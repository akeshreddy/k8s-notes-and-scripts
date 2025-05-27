#!/bin/bash

set -e

# Configuration
CLUSTER_NAME="< replace with your domain name. Example : k8sb33.xyz >"
STATE_STORE="s3://< replace with your domain name. Example : k8sb33.xyz >"
ZONES="us-east-1a,us-east-1b"
CONTROL_PLANE_ZONES="us-east-1a"
NODE_COUNT=2
CONTROL_PLANE_COUNT=1
NODE_SIZE="t3.medium"
CONTROL_PLANE_SIZE="t3.medium"
NODE_VOLUME_SIZE=15
CONTROL_PLANE_VOLUME_SIZE=10
SSH_KEY_PATH="< provide the path for the ssh public key. Example : $HOME/.ssh/K8S-Key-Pair.pub >"
DNS_ZONE="< replace with your domain name. Example : k8sb33.xyz >"
MAX_SPOT_PRICE="0.02"  # Set to null ("") to let AWS use on-demand cap

echo "Creating kops cluster configuration..."
kops create cluster \
  --name=$CLUSTER_NAME \
  --state=$STATE_STORE \
  --zones=$ZONES \
  --node-count=$NODE_COUNT \
  --control-plane-count=$CONTROL_PLANE_COUNT \
  --node-size=$NODE_SIZE \
  --control-plane-size=$CONTROL_PLANE_SIZE \
  --node-volume-size=$NODE_VOLUME_SIZE \
  --control-plane-volume-size=$CONTROL_PLANE_VOLUME_SIZE \
  --control-plane-zones=$CONTROL_PLANE_ZONES \
  --ssh-public-key=$SSH_KEY_PATH \
  --dns-zone=$DNS_ZONE \
  --networking calico

echo "Patching instance groups to use spot instances only..."

IG_NAMES=($(kops get ig --name=$CLUSTER_NAME | awk 'NR>1 {print $1}'))

for ig in "${IG_NAMES[@]}"; do
  echo "Modifying instance group: $ig"
  kops get ig $ig --name=$CLUSTER_NAME --state=$STATE_STORE -o yaml > ${ig}.yaml

  if command -v yq >/dev/null 2>&1; then
    yq eval "
      .spec.instanceInterruptionBehavior = \"terminate\" |
      .spec.maxPrice = \"$MAX_SPOT_PRICE\"
    " -i ${ig}.yaml
  else
    echo "Please install 'yq' for YAML editing or manually patch ${ig}.yaml"
    echo "command to install yq: sudo snap install yq"
    exit 1
  fi

  kops replace -f ${ig}.yaml --state=$STATE_STORE
done

echo "Applying cluster configuration..."
kops update cluster --name=$CLUSTER_NAME --state=$STATE_STORE --yes

echo "Export kubeconfig file..."
kops export kubeconfig --admin

echo "✅ Cluster is getting created with spot instance configuration! It should be ready in a few minutes."
echo "validate the cluster using the command : kops validate cluster --wait 10m"