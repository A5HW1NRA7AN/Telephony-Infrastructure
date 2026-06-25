#!/bin/bash
# Bootstrapping script for K8s FreeSWITCH Server
set -e
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y curl gnupg lsb-release git
