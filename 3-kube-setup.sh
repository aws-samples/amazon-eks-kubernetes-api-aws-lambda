#!/bin/bash
if ! hash aws 2>/dev/null || ! hash kubectl 2>/dev/null || ! hash eksctl 2>/dev/null; then
    echo "This script requires the AWS cli, kubectl, and eksctl installed"
    exit 2
fi

set -eo pipefail

ROLE_ARN=$(aws cloudformation describe-stacks --stack-name eks-lambda-python --query "Stacks[0].Outputs[?OutputKey=='Role'].OutputValue" --output text)
CLUSTER_NAME=$(cat cluster-name.txt)
RBAC_OBJECT='kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: read-only
  namespace: default
rules:
- apiGroups: [""]
  resources: ["*"]
  verbs: ["get", "watch", "list"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: read-only-binding
  namespace: default
roleRef:
  kind: Role
  name: read-only
  apiGroup: rbac.authorization.k8s.io
subjects:
- kind: Group
  name: read-only-group'


echo ==========
echo Create Role and RoleBinding in Kubernetes with kubectl
echo ==========
echo "$RBAC_OBJECT"
echo
while true; do
    read -p "Do you want to create the Role and RoleBinding? (y/n)" response
    case $response in
        [Yy]* ) echo "$RBAC_OBJECT" | kubectl apply -f -; break;;
        [Nn]* ) break;;
        * ) echo "Response must start with y or n.";;
    esac
done

echo
echo ==========
echo Update aws-auth configmap with a new mapping
echo ==========
echo Cluster: $CLUSTER_NAME
echo RoleArn: $ROLE_ARN
echo
while true; do
    read -p "Do you want to create the aws-auth configmap entry? (y/n)" response
    case $response in
        [Yy]* ) eksctl create iamidentitymapping --cluster $CLUSTER_NAME --group read-only-group --arn $ROLE_ARN; break;;
        [Nn]* ) break;;
        * ) echo "Response must start with y or n.";;
    esac
done

