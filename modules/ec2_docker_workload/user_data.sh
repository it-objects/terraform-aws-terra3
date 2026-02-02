#!/bin/bash

# EC2 Docker Workload - User Data Script
# This script initializes the EC2 instance with Docker and runs the specified container

INSTANCE_NAME="${instance_name}"
LOG_GROUP_NAME="${log_group_name}"

echo "Starting EC2 Docker Workload initialization..."
echo "Instance: $INSTANCE_NAME"
echo "Log Group: $LOG_GROUP_NAME"

# Log output to file and console
exec > >(tee -a /var/log/docker-workload-init.log)
exec 2>&1

# Set error handling - don't exit immediately, log errors and continue
set +e
trap 'echo "[$(date)] ERROR: Script encountered an error at line $LINENO"' ERR

# Get AWS region from instance metadata
AWS_REGION=$(ec2-metadata --availability-zone 2>/dev/null | cut -d' ' -f2 | sed 's/[a-z]$//' || echo "us-east-1")
echo "[$(date)] AWS Region: $AWS_REGION"

# -----------------------------------------------
# 1. Update system packages
# -----------------------------------------------
echo "[$(date)] Updating system packages..."
dnf update -y
dnf install -y docker awscli

# -----------------------------------------------
# 2. Configure Docker
# -----------------------------------------------
echo "[$(date)] Configuring Docker..."

# Create directory for daemon config
mkdir -p /etc/docker

# Configure Docker to use CloudWatch Logs driver
cat > /etc/docker/daemon.json <<DOCKER_CONFIG
{
  "log-driver": "awslogs",
  "log-opts": {
    "awslogs-group": "$LOG_GROUP_NAME",
    "awslogs-region": "$AWS_REGION",
    "awslogs-stream": "docker-$INSTANCE_NAME",
    "awslogs-datetime-format": "%Y-%m-%d %H:%M:%S"
  },
  "live-restore": true,
  "userland-proxy": false
}
DOCKER_CONFIG

# -----------------------------------------------
# 3. Attach Persistent EBS Volumes
# -----------------------------------------------
echo "[$(date)] Attaching persistent EBS volumes..."

# Get instance ID from IMDSv2
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null || echo "")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" "http://169.254.169.254/latest/meta-data/instance-id" 2>/dev/null || echo "")

if [ -z "$INSTANCE_ID" ]; then
  echo "[$(date)] WARNING: Could not determine instance ID, skipping volume attachment"
else
  echo "[$(date)] Instance ID: $INSTANCE_ID"

  # Find volumes tagged for this workload and attach them
  echo "[$(date)] Querying for persistent volumes tagged with WorkloadInstance=${instance_name}..."

  aws ec2 describe-volumes \
    --region "$AWS_REGION" \
    --filters "Name=tag:WorkloadInstance,Values=${instance_name}" \
             "Name=tag:Persistent,Values=true" \
    --query 'Volumes[*].[VolumeId,Tags[?Key==`DeviceName`].Value|[0]]' \
    --output text 2>/dev/null | while read VOLUME_ID DEVICE_NAME; do

    # Skip if empty line
    if [ -z "$VOLUME_ID" ]; then
      continue
    fi

    VOLUME_ID=$(echo "$VOLUME_ID" | xargs 2>/dev/null)
    DEVICE_NAME=$(echo "$DEVICE_NAME" | xargs 2>/dev/null)

    if [ -n "$VOLUME_ID" ] && [ -n "$DEVICE_NAME" ]; then
      echo "[$(date)] Found volume $VOLUME_ID, attaching to $DEVICE_NAME..."
      aws ec2 attach-volume \
        --region "$AWS_REGION" \
        --volume-id "$VOLUME_ID" \
        --instance-id "$INSTANCE_ID" \
        --device "$DEVICE_NAME" 2>/dev/null && echo "[$(date)] Attached $VOLUME_ID" || echo "[$(date)] WARNING: Failed to attach $VOLUME_ID"
    fi
  done

  echo "[$(date)] Waiting for volumes to attach..."
  sleep 15
fi

# -----------------------------------------------
# 4. Start Docker service
# -----------------------------------------------
echo "[$(date)] Starting Docker service..."

# Enable Docker to start on boot (important for ASG replacements)
if systemctl enable docker; then
  echo "[$(date)] Docker service enabled for boot"
else
  echo "[$(date)] WARNING: Failed to enable Docker service for boot"
fi

# Start Docker service now
if systemctl start docker; then
  echo "[$(date)] Docker service started"
else
  echo "[$(date)] WARNING: Failed to start Docker service"
fi

# Wait for Docker daemon to be ready
echo "[$(date)] Waiting for Docker daemon to be ready..."
DOCKER_READY=false
for i in {1..30}; do
  if docker ps &>/dev/null; then
    echo "[$(date)] Docker daemon is ready"
    DOCKER_READY=true
    break
  fi
  echo "[$(date)] Waiting for Docker... ($i/30)"
  sleep 1
done

if [ "$DOCKER_READY" = false ]; then
  echo "[$(date)] ERROR: Docker daemon failed to start after 30 seconds"
  exit 1
fi

# Allow ec2-user to run Docker commands
usermod -a -G docker ec2-user 2>/dev/null || true

# -----------------------------------------------
# 5. Create mount points for EBS volumes
# -----------------------------------------------
echo "[$(date)] Setting up EBS volume mount points..."

# Wait for volumes to be attached (give devices time to appear)
sleep 10

# List of expected block devices (from Terraform configuration)
EXPECTED_DEVICES="${expected_devices}"
echo "[$(date)] Expected devices: $EXPECTED_DEVICES"

# Format and mount additional EBS volumes
# Also check NVMe device names (nvme1n1, nvme2n1, etc.)
ALL_DEVICES="$EXPECTED_DEVICES nvme1n1 nvme2n1 nvme3n1 nvme4n1 nvme5n1"
for DEVICE in $ALL_DEVICES; do
  DEVICE_PATH=""

  # Resolve device path (handle symlinks like /dev/sdf -> nvme1n1)
  if [ -b "/dev/$DEVICE" ]; then
    DEVICE_PATH="/dev/$DEVICE"
  elif [ -L "/dev/$DEVICE" ]; then
    # It's a symlink, resolve it
    REAL_DEVICE=$(readlink -f "/dev/$DEVICE")
    if [ -b "$REAL_DEVICE" ]; then
      DEVICE_PATH="$REAL_DEVICE"
    fi
  fi

  if [ -n "$DEVICE_PATH" ]; then
    echo "[$(date)] Processing device: $DEVICE_PATH"

    # Check if device already has a filesystem
    if blkid "$DEVICE_PATH" 2>/dev/null; then
      echo "[$(date)] Device $DEVICE_PATH already has filesystem, skipping format"
    else
      echo "[$(date)] Formatting $DEVICE_PATH..."
      mkfs.ext4 -F "$DEVICE_PATH" || echo "[$(date)] WARNING: Failed to format $DEVICE_PATH"
    fi

    # Create mount point (strip n1 suffix from NVMe devices)
    DEVICE_SHORT="$${DEVICE%%n1}"
    MOUNT_POINT="/mnt/$${DEVICE_SHORT}"
    mkdir -p "$MOUNT_POINT"

    if ! grep -q "$DEVICE_PATH" /etc/fstab; then
      echo "$DEVICE_PATH $MOUNT_POINT ext4 defaults,nofail 0 2" >> /etc/fstab
    fi

    if mount "$MOUNT_POINT" 2>/dev/null; then
      echo "[$(date)] Successfully mounted $DEVICE_PATH to $MOUNT_POINT"
    else
      echo "[$(date)] WARNING: Failed to mount $DEVICE_PATH to $MOUNT_POINT"
    fi

    # Set proper permissions for Docker containers
    chmod 755 "$MOUNT_POINT"
    chown 999:999 "$MOUNT_POINT" 2>/dev/null || true
  fi
done

# -----------------------------------------------
# 6. Pull Docker image
# -----------------------------------------------
echo "[$(date)] Pulling Docker image: ${docker_image_uri}..."
if docker pull "${docker_image_uri}"; then
  echo "[$(date)] Docker image pulled successfully"
else
  echo "[$(date)] WARNING: Failed to pull Docker image, attempting to run anyway..."
fi

# -----------------------------------------------
# 7. Run Docker container
# -----------------------------------------------
echo "[$(date)] Starting Docker container..."

# Build docker run command
# Use bridge networking (default) with explicit port mappings
# ALB targets the instance on the host port, which is mapped to the container port
DOCKER_RUN_CMD="docker run \
  --name '$INSTANCE_NAME' \
  --restart=unless-stopped \
  ${docker_port_args} \
  ${docker_env_vars} \
  ${docker_volume_mounts} \
  --detach \
  --log-driver=awslogs \
  --log-opt awslogs-group='$LOG_GROUP_NAME' \
  --log-opt awslogs-region='$AWS_REGION' \
  --log-opt awslogs-stream='container-$INSTANCE_NAME' \
  '${docker_image_uri}'"

# Execute the docker run command
if eval "$DOCKER_RUN_CMD"; then
  echo "[$(date)] Docker container started successfully"
else
  echo "[$(date)] WARNING: Failed to start Docker container"
fi

# -----------------------------------------------
# 8. Setup graceful shutdown handler
# -----------------------------------------------
echo "[$(date)] Setting up graceful shutdown handler..."
cat > /usr/local/bin/docker-shutdown.sh <<'SHUTDOWN_EOF'
#!/bin/bash
INSTANCE_NAME="${instance_name}"
echo "Gracefully shutting down Docker container: $INSTANCE_NAME"
docker stop "$INSTANCE_NAME" --time=30 || true
SHUTDOWN_EOF

chmod +x /usr/local/bin/docker-shutdown.sh

# Register shutdown hook for systemd
cat > /etc/systemd/system/docker-shutdown.service <<SERVICE_EOF
[Unit]
Description=Docker Container Graceful Shutdown
Before=shutdown.target reboot.target halt.target kexec.target
DefaultDependencies=no

[Service]
Type=oneshot
ExecStop=/usr/local/bin/docker-shutdown.sh

[Install]
WantedBy=multi-user.target
SERVICE_EOF

systemctl daemon-reload
systemctl enable docker-shutdown.service

# -----------------------------------------------
# 9. Verification
# -----------------------------------------------
echo "[$(date)] Waiting for container to be ready..."
sleep 10

if docker ps | grep -q "$INSTANCE_NAME"; then
  echo "[$(date)] SUCCESS: Docker container is running!"
  docker ps --filter "name=$INSTANCE_NAME"
else
  echo "[$(date)] ERROR: Docker container failed to start!"
  docker logs "$INSTANCE_NAME" || true
  exit 1
fi

echo "[$(date)] EC2 Docker Workload initialization completed successfully!"
