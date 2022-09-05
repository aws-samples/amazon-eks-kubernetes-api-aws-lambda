#!/bin/bash
if ! hash aws 2>/dev/null || ! hash pip3 2>/dev/null; then
    echo "This script requires the AWS cli, and pip3 installed"
    exit 2
fi

set -eo pipefail
ARTIFACT_BUCKET=$(cat bucket-name.txt)
CLUSTER_NAME=$(cat cluster-name.txt)
rm -rf lambda_build ; mkdir lambda_build ; cd lambda_build
cp -r ../function/* .
pip3 install --target . -r requirements.txt
cd ../
aws cloudformation package --template-file template.yml --s3-bucket $ARTIFACT_BUCKET --output-template-file out.yml
aws cloudformation deploy --template-file out.yml \
  --stack-name eks-lambda-python \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides ClusterName=$CLUSTER_NAME
