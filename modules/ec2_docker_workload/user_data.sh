#!/bin/bash

# EC2 Docker Workload - User Data Script
# This script initializes the EC2 instance with Docker and runs the specified container

INSTANCE_NAME="${instance_name}"
LOG_GROUP_NAME="${log_group_name}"
ROUTE53_ZONE_ID="${route53_zone_id}"
ROUTE53_RECORD_NAME="${route53_record_name}"

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

# Debug: Check AWS credentials and IAM role
echo "[$(date)] DEBUG: Checking AWS credentials and IAM role..."
if aws sts get-caller-identity --region "$AWS_REGION" 2>&1 | head -5; then
  echo "[$(date)] DEBUG: AWS credentials are available"
else
  echo "[$(date)] WARNING: Could not verify AWS credentials"
fi

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
  echo "[$(date)] DEBUG: Running: aws ec2 describe-volumes --region \"$AWS_REGION\" --filters \"Name=tag:WorkloadInstance,Values=${instance_name}\" \"Name=tag:Persistent,Values=true\" --query 'Volumes[*].[VolumeId,Tags[?Key==\`DeviceName\`].Value|[0]]' --output text"

  VOLUMES_OUTPUT=$(aws ec2 describe-volumes \
    --region "$AWS_REGION" \
    --filters "Name=tag:WorkloadInstance,Values=${instance_name}" \
             "Name=tag:Persistent,Values=true" \
    --query 'Volumes[*].[VolumeId,Tags[?Key==`DeviceName`].Value|[0]]' \
    --output text 2>&1)

  VOLUMES_EXIT_CODE=$?
  echo "[$(date)] DEBUG: describe-volumes exit code: $VOLUMES_EXIT_CODE"
  echo "[$(date)] DEBUG: Volumes output: $VOLUMES_OUTPUT"

  echo "$VOLUMES_OUTPUT" | while read VOLUME_ID DEVICE_NAME; do

    # Skip if empty line
    if [ -z "$VOLUME_ID" ]; then
      echo "[$(date)] DEBUG: Skipping empty volume entry"
      continue
    fi

    VOLUME_ID=$(echo "$VOLUME_ID" | xargs 2>/dev/null)
    DEVICE_NAME=$(echo "$DEVICE_NAME" | xargs 2>/dev/null)

    echo "[$(date)] DEBUG: Processing volume - ID: $VOLUME_ID, Device: $DEVICE_NAME"

    if [ -n "$VOLUME_ID" ] && [ -n "$DEVICE_NAME" ]; then
      echo "[$(date)] Found volume $VOLUME_ID, attaching to $DEVICE_NAME..."

      # First, detach from any old instance if still attached
      ATTACHED_INSTANCE=$(aws ec2 describe-volumes \
        --region "$AWS_REGION" \
        --volume-ids "$VOLUME_ID" \
        --query 'Volumes[0].Attachments[0].InstanceId' \
        --output text 2>/dev/null)

      echo "[$(date)] DEBUG: Volume $VOLUME_ID currently attached to: $ATTACHED_INSTANCE"

      if [ -n "$ATTACHED_INSTANCE" ] && [ "$ATTACHED_INSTANCE" != "None" ] && [ "$ATTACHED_INSTANCE" != "$INSTANCE_ID" ]; then
        echo "[$(date)] Volume $VOLUME_ID is still attached to instance $ATTACHED_INSTANCE, detaching first..."
        aws ec2 detach-volume \
          --region "$AWS_REGION" \
          --volume-id "$VOLUME_ID" 2>/dev/null

        # Wait for detach to complete (up to 60 seconds)
        echo "[$(date)] Waiting for volume to detach..."
        for i in {1..12}; do
          STATE=$(aws ec2 describe-volumes \
            --region "$AWS_REGION" \
            --volume-ids "$VOLUME_ID" \
            --query 'Volumes[0].State' \
            --output text 2>/dev/null)

          echo "[$(date)] DEBUG: Volume state check $i/12: $STATE"

          if [ "$STATE" = "available" ]; then
            echo "[$(date)] Volume is now available"
            break
          fi
          echo "[$(date)] Volume state: $STATE, waiting... ($i/12)"
          sleep 5
        done
      fi

      # Now attach to this instance
      echo "[$(date)] Attaching $VOLUME_ID to $DEVICE_NAME..."
      echo "[$(date)] DEBUG: Running: aws ec2 attach-volume --region \"$AWS_REGION\" --volume-id \"$VOLUME_ID\" --instance-id \"$INSTANCE_ID\" --device \"$DEVICE_NAME\""

      ATTACH_OUTPUT=$(aws ec2 attach-volume \
        --region "$AWS_REGION" \
        --volume-id "$VOLUME_ID" \
        --instance-id "$INSTANCE_ID" \
        --device "$DEVICE_NAME" 2>&1)

      ATTACH_EXIT_CODE=$?
      echo "[$(date)] DEBUG: attach-volume exit code: $ATTACH_EXIT_CODE"

      if [ $ATTACH_EXIT_CODE -eq 0 ]; then
        echo "[$(date)] Attached $VOLUME_ID successfully"
        echo "[$(date)] Attachment details: $ATTACH_OUTPUT"
      else
        echo "[$(date)] ERROR: Failed to attach $VOLUME_ID"
        echo "[$(date)] AWS Error: $ATTACH_OUTPUT"
        echo "[$(date)] Checking volume and instance state..."
        aws ec2 describe-volumes --region "$AWS_REGION" --volume-ids "$VOLUME_ID" --query 'Volumes[0].[VolumeId,State,Attachments]' --output text 2>/dev/null || true
        aws ec2 describe-instances --region "$AWS_REGION" --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].[InstanceId,State.Name]' --output text 2>/dev/null || true
      fi
    fi
  done

  echo "[$(date)] Waiting for volumes to attach..."
  sleep 15
fi

# -----------------------------------------------
# 4. Start Docker service
# -----------------------------------------------
echo "[$(date)] Starting Docker service..."
if systemctl start docker; then
  echo "[$(date)] Docker service started"
else
  echo "[$(date)] WARNING: Failed to start Docker service"
fi

if systemctl enable docker; then
  echo "[$(date)] Docker service enabled"
else
  echo "[$(date)] WARNING: Failed to enable Docker service"
fi

# Allow ec2-user to run Docker commands
usermod -a -G docker ec2-user 2>/dev/null || true

# Wait for Docker daemon to be ready
sleep 5

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
# 6. Fetch Secrets from SSM Parameter Store and Secrets Manager
# -----------------------------------------------
echo "[$(date)] Processing secrets from SSM Parameter Store and Secrets Manager..."

SECRETS_JSON='${docker_secrets_json}'
DOCKER_SECRET_ENV_VARS=""

echo "[$(date)] DEBUG: SECRETS_JSON = $SECRETS_JSON"

if [ "$SECRETS_JSON" != "{}" ] && [ -n "$SECRETS_JSON" ]; then
  echo "[$(date)] Found secrets to fetch..."
  echo "[$(date)] DEBUG: Checking IAM permissions..."

  # Test IAM permissions by checking caller identity
  CALLER_IDENTITY=$(aws sts get-caller-identity --region "$AWS_REGION" 2>&1)
  CALLER_EXIT_CODE=$?
  echo "[$(date)] DEBUG: Caller identity check exit code: $CALLER_EXIT_CODE"
  if [ $CALLER_EXIT_CODE -eq 0 ]; then
    echo "[$(date)] DEBUG: Caller identity: $CALLER_IDENTITY"
  else
    echo "[$(date)] DEBUG: Failed to get caller identity: $CALLER_IDENTITY"
  fi

  # Parse JSON and fetch each secret using process substitution to avoid subshell issues
  # Format: {"ENV_VAR_NAME": "arn:aws:ssm:region:account:parameter/path"} or {"ENV_VAR_NAME": "arn:aws:secretsmanager:region:account:secret:name"}
  while IFS='|' read -r ENV_VAR_NAME SECRET_ARN; do
    if [ -z "$ENV_VAR_NAME" ] || [ -z "$SECRET_ARN" ]; then
      echo "[$(date)] DEBUG: Skipping empty entry"
      continue
    fi

    echo "[$(date)] Fetching secret for $ENV_VAR_NAME..."
    echo "[$(date)] DEBUG: Secret ARN = $SECRET_ARN"

    SECRET_VALUE=""

    # Detect if it's SSM Parameter Store or Secrets Manager based on ARN
    if echo "$SECRET_ARN" | grep -q "arn:aws:ssm:"; then
      # SSM Parameter Store
      echo "[$(date)] Detected SSM Parameter Store ARN"
      PARAM_NAME=$(echo "$SECRET_ARN" | sed 's|.*:parameter||')
      echo "[$(date)] DEBUG: Extracted parameter name: $PARAM_NAME"

      echo "[$(date)] DEBUG: Running: aws ssm get-parameter --name \"$PARAM_NAME\" --with-decryption --region \"$AWS_REGION\" --query 'Parameter.Value' --output text"

      SECRET_VALUE=$(aws ssm get-parameter \
        --name "$PARAM_NAME" \
        --with-decryption \
        --region "$AWS_REGION" \
        --query 'Parameter.Value' \
        --output text 2>&1)

      FETCH_EXIT_CODE=$?
      echo "[$(date)] DEBUG: SSM get-parameter exit code: $FETCH_EXIT_CODE"

      if [ $FETCH_EXIT_CODE -eq 0 ] && [ -n "$SECRET_VALUE" ]; then
        echo "[$(date)] Successfully fetched SSM parameter for $ENV_VAR_NAME (length: $${#SECRET_VALUE})"
      else
        echo "[$(date)] ERROR: Failed to fetch SSM parameter for $ENV_VAR_NAME"
        echo "[$(date)] DEBUG: AWS error output: $SECRET_VALUE"
        echo "[$(date)] DEBUG: Checking if parameter exists..."
        aws ssm describe-parameters --region "$AWS_REGION" --filters "Key=Name,Values=$PARAM_NAME" 2>&1 | head -20
        continue
      fi

    elif echo "$SECRET_ARN" | grep -q "arn:aws:secretsmanager:"; then
      # AWS Secrets Manager
      echo "[$(date)] Detected Secrets Manager ARN"
      SECRET_NAME=$(echo "$SECRET_ARN" | sed 's|.*:secret:||' | sed 's|-[A-Za-z0-9]*$||')
      echo "[$(date)] DEBUG: Extracted secret name: $SECRET_NAME"

      echo "[$(date)] DEBUG: Running: aws secretsmanager get-secret-value --secret-id \"$SECRET_NAME\" --region \"$AWS_REGION\" --query 'SecretString' --output text"

      SECRET_JSON=$(aws secretsmanager get-secret-value \
        --secret-id "$SECRET_NAME" \
        --region "$AWS_REGION" \
        --query 'SecretString' \
        --output text 2>&1)

      FETCH_EXIT_CODE=$?
      echo "[$(date)] DEBUG: Secrets Manager get-secret-value exit code: $FETCH_EXIT_CODE"

      if [ $FETCH_EXIT_CODE -eq 0 ] && [ -n "$SECRET_JSON" ]; then
        # Try to parse as JSON first (for structured secrets)
        if echo "$SECRET_JSON" | jq empty 2>/dev/null; then
          # It's JSON, try to extract the value matching the env var name
          SECRET_VALUE=$(echo "$SECRET_JSON" | jq -r ".$ENV_VAR_NAME // ." 2>/dev/null)
          echo "[$(date)] DEBUG: Parsed as JSON, extracted value length: $${#SECRET_VALUE}"
        else
          # It's a plain string secret
          SECRET_VALUE="$SECRET_JSON"
          echo "[$(date)] DEBUG: Treated as plain string, length: $${#SECRET_VALUE}"
        fi

        if [ -n "$SECRET_VALUE" ]; then
          echo "[$(date)] Successfully fetched Secrets Manager secret for $ENV_VAR_NAME (length: $${#SECRET_VALUE})"
        else
          echo "[$(date)] ERROR: Failed to extract value from Secrets Manager secret for $ENV_VAR_NAME"
          echo "[$(date)] DEBUG: Raw secret JSON: $SECRET_JSON"
          continue
        fi
      else
        echo "[$(date)] ERROR: Failed to fetch Secrets Manager secret for $ENV_VAR_NAME"
        echo "[$(date)] DEBUG: AWS error output: $SECRET_JSON"
        continue
      fi
    else
      echo "[$(date)] ERROR: Unknown secret ARN format for $ENV_VAR_NAME: $SECRET_ARN"
      continue
    fi

    # Escape quotes and special characters in secret value for Docker command
    ESCAPED_SECRET=$(echo "$SECRET_VALUE" | sed 's/"/\\"/g' | sed "s/'/\\\\'/g")
    DOCKER_SECRET_ENV_VARS="$DOCKER_SECRET_ENV_VARS -e $ENV_VAR_NAME=\"$ESCAPED_SECRET\""
    echo "[$(date)] DEBUG: Added environment variable $ENV_VAR_NAME to Docker command"
  done < <(echo "$SECRETS_JSON" | jq -r 'to_entries[] | "\(.key)|\(.value)"')
else
  echo "[$(date)] No secrets configured"
fi

echo "[$(date)] DEBUG: Final DOCKER_SECRET_ENV_VARS length: $${#DOCKER_SECRET_ENV_VARS}"

# -----------------------------------------------
# 7. Authenticate with ECR (if enabled)
# -----------------------------------------------
echo "[$(date)] DEBUG: enable_ecr_access = ${enable_ecr_access}"

if [ "${enable_ecr_access}" = "true" ] || [ "${enable_ecr_access}" = "True" ]; then
  echo "[$(date)] ECR access enabled, authenticating with ECR..."

  # Extract registry URL from image URI (everything before first /)
  REGISTRY_URL=$(echo "${docker_image_uri}" | cut -d'/' -f1)
  echo "[$(date)] DEBUG: Extracted registry URL: $REGISTRY_URL"

  if [[ "$REGISTRY_URL" =~ dkr\.ecr\. ]]; then
    echo "[$(date)] Detected ECR registry: $REGISTRY_URL"
    echo "[$(date)] DEBUG: Running: aws ecr get-login-password --region \"$AWS_REGION\""

    LOGIN_OUTPUT=$(aws ecr get-login-password --region "$AWS_REGION" 2>&1)
    LOGIN_EXIT_CODE=$?
    echo "[$(date)] DEBUG: get-login-password exit code: $LOGIN_EXIT_CODE"

    if [ $LOGIN_EXIT_CODE -eq 0 ] && [ -n "$LOGIN_OUTPUT" ]; then
      echo "[$(date)] DEBUG: Got login password, attempting docker login..."
      if echo "$LOGIN_OUTPUT" | docker login --username AWS --password-stdin "$REGISTRY_URL" 2>&1 | head -5; then
        echo "[$(date)] Successfully authenticated with ECR"
      else
        echo "[$(date)] ERROR: Failed to authenticate with ECR, but continuing..."
      fi
    else
      echo "[$(date)] ERROR: Failed to get ECR login password"
      echo "[$(date)] DEBUG: AWS error: $LOGIN_OUTPUT"
    fi
  else
    echo "[$(date)] Image URI does not appear to be from ECR, skipping ECR authentication"
  fi
else
  echo "[$(date)] ECR access not enabled"
fi

# -----------------------------------------------
# 8. Pull Docker image
# -----------------------------------------------
echo "[$(date)] Pulling Docker image: ${docker_image_uri}..."
echo "[$(date)] DEBUG: Running: docker pull \"${docker_image_uri}\""

PULL_OUTPUT=$(docker pull "${docker_image_uri}" 2>&1)
PULL_EXIT_CODE=$?

echo "[$(date)] DEBUG: docker pull exit code: $PULL_EXIT_CODE"
echo "[$(date)] DEBUG: docker pull output (last 20 lines):"
echo "$PULL_OUTPUT" | tail -20

if [ $PULL_EXIT_CODE -eq 0 ]; then
  echo "[$(date)] Docker image pulled successfully"
else
  echo "[$(date)] WARNING: Failed to pull Docker image, attempting to run anyway..."
  echo "[$(date)] DEBUG: Full pull error: $PULL_OUTPUT"
fi

# -----------------------------------------------
# 9. Run Docker container
# -----------------------------------------------
echo "[$(date)] Starting Docker container..."

# Build docker run command
DOCKER_RUN_CMD="docker run \
  --name '$INSTANCE_NAME' \
  --restart=unless-stopped \
  ${docker_port_args} \
  ${docker_env_vars} \
  $DOCKER_SECRET_ENV_VARS \
  ${docker_volume_mounts} \
  --detach \
  --log-driver=awslogs \
  --log-opt awslogs-group='$LOG_GROUP_NAME' \
  --log-opt awslogs-region='$AWS_REGION' \
  --log-opt awslogs-stream='container-$INSTANCE_NAME' \
  '${docker_image_uri}'"

echo "[$(date)] DEBUG: Docker run command (sanitized):"
# Print command with secrets masked
echo "$DOCKER_RUN_CMD" | sed 's/-e [A-Z_]*="[^"]*"/-e REDACTED="***"/g'

echo "[$(date)] DEBUG: Command components:"
echo "[$(date)] DEBUG:   Instance name: $INSTANCE_NAME"
echo "[$(date)] DEBUG:   Port args: ${docker_port_args}"
echo "[$(date)] DEBUG:   Env vars: ${docker_env_vars}"
echo "[$(date)] DEBUG:   Secret env vars count: $(echo "$DOCKER_SECRET_ENV_VARS" | grep -o '\-e' | wc -l)"
echo "[$(date)] DEBUG:   Volume mounts: ${docker_volume_mounts}"
echo "[$(date)] DEBUG:   Image URI: ${docker_image_uri}"

# Execute the docker run command
echo "[$(date)] DEBUG: Executing docker run command..."
RUN_OUTPUT=$(eval "$DOCKER_RUN_CMD" 2>&1)
RUN_EXIT_CODE=$?

echo "[$(date)] DEBUG: docker run exit code: $RUN_EXIT_CODE"
echo "[$(date)] DEBUG: docker run output: $RUN_OUTPUT"

if [ $RUN_EXIT_CODE -eq 0 ]; then
  echo "[$(date)] Docker container started successfully"
  echo "[$(date)] DEBUG: Container ID: $RUN_OUTPUT"
else
  echo "[$(date)] WARNING: Failed to start Docker container"
  echo "[$(date)] DEBUG: Full error output: $RUN_OUTPUT"
  echo "[$(date)] DEBUG: Checking Docker daemon status..."
  docker ps 2>&1 | head -10
fi

# -----------------------------------------------
# 9. Register with Route53 (for internal DNS service discovery)
# -----------------------------------------------
if [ -n "$ROUTE53_ZONE_ID" ] && [ -n "$ROUTE53_RECORD_NAME" ]; then
  echo "[$(date)] Registering instance with Route53..."

  # Get private IP address from IMDSv2
  PRIVATE_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" "http://169.254.169.254/latest/meta-data/local-ipv4" 2>/dev/null || echo "")

  if [ -n "$PRIVATE_IP" ]; then
    echo "[$(date)] Private IP: $PRIVATE_IP"
    echo "[$(date)] Updating Route53 record: $ROUTE53_RECORD_NAME -> $PRIVATE_IP"

    aws route53 change-resource-record-sets \
      --hosted-zone-id "$ROUTE53_ZONE_ID" \
      --region "$AWS_REGION" \
      --change-batch "{
        \"Changes\": [{
          \"Action\": \"UPSERT\",
          \"ResourceRecordSet\": {
            \"Name\": \"$ROUTE53_RECORD_NAME\",
            \"Type\": \"A\",
            \"TTL\": 60,
            \"ResourceRecords\": [{\"Value\": \"$PRIVATE_IP\"}]
          }
        }]
      }" 2>/dev/null

    if [ $? -eq 0 ]; then
      echo "[$(date)] Successfully registered with Route53"
    else
      echo "[$(date)] WARNING: Failed to register with Route53"
    fi
  else
    echo "[$(date)] WARNING: Could not determine private IP address"
  fi
else
  echo "[$(date)] Route53 registration disabled (no ZONE_ID or RECORD_NAME)"
fi

# -----------------------------------------------
# 10. Setup graceful shutdown handler
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
# 11. Verification
# -----------------------------------------------
echo "[$(date)] Waiting for container to be ready..."
sleep 10

echo "[$(date)] DEBUG: Checking running containers..."
docker ps 2>&1 | head -20

if docker ps | grep -q "$INSTANCE_NAME"; then
  echo "[$(date)] SUCCESS: Docker container is running!"
  echo "[$(date)] DEBUG: Container details:"
  docker ps --filter "name=$INSTANCE_NAME" 2>&1

  echo "[$(date)] DEBUG: Container logs (last 50 lines):"
  docker logs "$INSTANCE_NAME" 2>&1 | tail -50
else
  echo "[$(date)] ERROR: Docker container failed to start!"
  echo "[$(date)] DEBUG: Attempting to get logs anyway..."
  docker logs "$INSTANCE_NAME" 2>&1 || true

  echo "[$(date)] DEBUG: Checking all containers:"
  docker ps -a 2>&1

  echo "[$(date)] DEBUG: Docker daemon status:"
  systemctl status docker 2>&1 | head -20

  exit 1
fi

echo "[$(date)] EC2 Docker Workload initialization completed successfully!"
