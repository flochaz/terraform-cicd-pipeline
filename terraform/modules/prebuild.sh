#!/bin/bash
set -e

if [[ -z  ${TEST_ACCOUNT_ASSUMED_ROLE} ]]; then
  curl 169.254.170.2$AWS_CONTAINER_CREDENTIALS_RELATIVE_URI | jq 'to_entries | [ .[] | select(.key | (contains("Expiration") or contains("RoleArn"))  | not) ] |  map(if .key == "AccessKeyId" then . + {"key":"AWS_ACCESS_KEY_ID"} else . end) | map(if .key == "SecretAccessKey" then . + {"key":"AWS_SECRET_ACCESS_KEY"} else . end) | map(if .key == "Token" then . + {"key":"AWS_SESSION_TOKEN"} else . end) | map("export \(.key)=\(.value)") | .[]' -r > /tmp/aws_cred_export.txt # work around https://github.com/hashicorp/terraform/issues/8746
  source /tmp/aws_cred_export.txt
  echo "[INFO] Local Deployment"
  exit 0
fi

echo "Assume Role in Test Account"
aws sts assume-role --role-arn ${TEST_ACCOUNT_ASSUMED_ROLE} --role-session-name "deployment" > /tmp/role
export AWS_ACCESS_KEY_ID=$(cat /tmp/role|jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(cat /tmp/role|jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(cat /tmp/role|jq -r '.Credentials.SessionToken')