#!/usr/bin/env bash

# Script to find AWS profile by account ID
# Usage: ./find_profile.sh ACCOUNT_ID

if [ -z "$1" ]; then
  echo "Please provide an account ID"
  echo "Usage: ./find_profile.sh ACCOUNT_ID"
  exit 1
fi

ACCOUNT_ID="$1"

for PROFILE in $(aws configure list-profiles); do
  ROLE_ARN=$(aws configure get role_arn --profile "$PROFILE")

  if [[ "$ROLE_ARN" == *":${ACCOUNT_ID}:"* ]]; then
    echo "$PROFILE"
    exit 0
  fi
done

echo "No AWS profile found for account ${ACCOUNT_ID}" >&2
exit 1
