#!/bin/bash
# Bootstrapping script for Jenkins Automation Server
set -e
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release git

# Install Docker
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable Docker for ubuntu user
usermod -aG docker ubuntu
systemctl enable docker
systemctl start docker
