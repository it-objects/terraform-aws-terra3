#!/bin/bash
set -e

export AWS_DEFAULT_REGION="$(/opt/aws/bin/ec2-metadata -z | sed 's/placement: \(.*\).$/\1/')"
INSTANCE_ID="$(/opt/aws/bin/ec2-metadata -i | cut -d' ' -f2)"

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
