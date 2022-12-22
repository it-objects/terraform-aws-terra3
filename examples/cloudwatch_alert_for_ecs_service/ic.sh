#!/bin/bash

# Creates an infracost cost analysis
terraform plan -out tfplan.binary
terraform show -json tfplan.binary > plan.json
infracost breakdown --path plan.json --usage-file infracost-usage.yml
rm tfplan.binary plan.json
