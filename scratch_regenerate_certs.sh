#!/bin/bash
# Script to regenerate K8s API certificates with Proxy IP SANs
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
  source "$SCRIPT_DIR/.env"
else
  echo "Error: .env file not found at $SCRIPT_DIR/.env" >&2
  exit 1
fi

TERRAFORM_ENV_DIR="$SCRIPT_DIR/freeswitch-kubernetes/terraform"
if [ -f "$TERRAFORM_ENV_DIR/env.sh" ]; then
  source "$TERRAFORM_ENV_DIR/env.sh"
else
  echo "Error: env.sh not found."
  exit 1
fi

echo "==> Updating hosts.yaml with Proxy EIP $PROXY_IP on private server..."
ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no -o ProxyCommand="ssh -i $KEY_PATH -o StrictHostKeyChecking=no -W %h:%p ubuntu@$BASTION_IP" ubuntu@$PRIVATE_IP "bash -s" << EOF
set -e
cd kubespray
mkdir -p inventory/localcluster

cat << 'INVENTORY' > inventory/localcluster/hosts.yaml
all:
  hosts:
    node1:
      ansible_host: 127.0.0.1
      ip: $PRIVATE_IP
      access_ip: $PRIVATE_IP
      ansible_connection: local
  vars:
    supplementary_addresses_in_ssl_keys: [ "$PROXY_IP" ]
  children:
    kube_control_plane:
      hosts:
        node1:
    kube_node:
      hosts:
        node1:
    etcd:
      hosts:
        node1:
    k8s_cluster:
      children:
        kube_control_plane:
        kube_node:
    calico_rr:
      hosts: {}
INVENTORY

echo "==> Running Kubespray certificate regeneration playbook..."
source kubespray-venv/bin/activate
ansible-playbook -i inventory/localcluster/hosts.yaml --become cluster.yml --tags=facts,kubeadm,master,certs

echo "==> Restarting kube-apiserver to load new certificates..."
sudo crictl pods | grep kube-apiserver | awk '{print \$1}' | xargs -r sudo crictl stopp
EOF

echo "==> Certificate regeneration complete!"
