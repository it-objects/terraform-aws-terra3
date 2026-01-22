#!/bin/bash
set -e

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

# Get AWS region from instance metadata
AWS_REGION=$(ec2-metadata --availability-zone 2>/dev/null | cut -d' ' -f2 | sed 's/[a-z]$//' || echo "us-east-1")

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
# 3. Start Docker service
# -----------------------------------------------
echo "[$(date)] Starting Docker service..."
systemctl start docker
systemctl enable docker

# Allow ec2-user to run Docker commands
usermod -a -G docker ec2-user 2>/dev/null || true

# Wait for Docker daemon to be ready
sleep 5

# -----------------------------------------------
# 4. Create mount points for EBS volumes
# -----------------------------------------------
echo "[$(date)] Setting up EBS volume mount points..."

# Wait for volumes to be attached (give devices time to appear)
sleep 10

# Format and mount additional EBS volumes (check for common device names)
for DEVICE in sdf sdg sdh sdi sdj; do
  if [ -b "/dev/$DEVICE" ]; then
    echo "[$(date)] Formatting and mounting /dev/$DEVICE..."
    if ! blkid "/dev/$DEVICE" 2>/dev/null; then
      mkfs.ext4 -F "/dev/$DEVICE"
    fi
    MOUNT_POINT="/mnt/$DEVICE"
    mkdir -p "$MOUNT_POINT"
    if ! grep -q "/dev/$DEVICE" /etc/fstab; then
      echo "/dev/$DEVICE $MOUNT_POINT ext4 defaults,nofail 0 2" >> /etc/fstab
    fi
    mount "$MOUNT_POINT" || true

    # Set proper permissions for Docker containers
    chmod 755 "$MOUNT_POINT"
    chown 999:999 "$MOUNT_POINT" 2>/dev/null || true
  fi
done

# -----------------------------------------------
# 5. Pull Docker image
# -----------------------------------------------
echo "[$(date)] Pulling Docker image: ${docker_image_uri}..."
docker pull "${docker_image_uri}"

# -----------------------------------------------
# 6. Run Docker container
# -----------------------------------------------
echo "[$(date)] Starting Docker container..."

# Build docker run command
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
eval "$DOCKER_RUN_CMD"

# -----------------------------------------------
# 7. Setup graceful shutdown handler
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
# 8. Verification
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
