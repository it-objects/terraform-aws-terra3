#!/bin/bash
set -e

export TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
export AWS_DEFAULT_REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | cut -d \" -f4)
export INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/instance-id)

disable_source_dest_check() {
  aws ec2 modify-instance-attribute --no-source-dest-check --instance-id "$INSTANCE_ID"
}

enable_nat_config_service() {
  systemctl daemon-reload
  systemctl enable nat-config
  systemctl start nat-config
}

{
  disable_source_dest_check
  enable_nat_config_service
}
