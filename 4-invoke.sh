#!/bin/bash
if ! hash aws 2>/dev/null; then
    echo "This script requires the AWS cli installed"
    exit 2
fi

set -eo pipefail

while true; do
  aws lambda invoke --function-name lambda-eks-getpods-python --payload '{}' out.json
  cat out.json
  echo ""
  sleep 2
done
