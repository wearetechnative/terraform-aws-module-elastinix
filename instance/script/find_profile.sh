#!/usr/bin/env bash

# Script to find AWS profile by account ID
# Usage: ./find_profile.sh ACCOUNT_ID

if [ -z "$1" ]; then
  echo "Please provide an account ID"
  echo "Usage: ./find_profile.sh ACCOUNT_ID"
  exit 1
fi

ACCOUNT_ID="$1"
jsonify-aws-dotfiles | jq -r '.config | to_entries[] | select(.value.role_arn != null) | select(.value.role_arn | contains("'"$ACCOUNT_ID"'")) | .key'
