#!/bin/bash

# use this to inject sensitive env vars from parameter store into ECS directly and avoid adding these to git
aws ssm put-parameter \
    --name "/mastodon-with-terra3/secrets" \
    --value "$(<terraform.tfvars.json)" \
    --type "SecureString"
