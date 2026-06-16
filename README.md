# On-Prem Infrastructure

This repository manages AWS cloud resources and Kubernetes cluster bootstrapping configurations for the Telephony project.

## Project Structure

```
On-Prem-Infrastructure/
├── .gitignore
├── README.md
├── terraform/                  # AWS Infrastructure Provisioning
│   ├── main.tf                 # VPC definition
│   ├── variables.tf            # Subnet ranges & whitelists
│   ├── security.tf             # Key pairs & Security Groups
│   ├── instances.tf            # Bastion, Proxy, and K8s node instances
│   └── outputs.tf              # Outputs IPs and config files
└── kubespray/                  # Ansible K8s Bootstrapping
    ├── deploy_kubespray_wsl.sh # Run playbook from WSL
    └── deploy_kubespray_local.sh # Run playbook locally on server
```

---

## Usage Guide

### 1. Provision Cloud Infrastructure (Terraform)
Navigate to the `terraform/` directory and run the initialization commands on your Windows shell:

```powershell
# Navigate to directory
cd terraform/

# Initialize provider plugins
terraform init

# Plan deployment and review resources
terraform plan

# Deploy VMs to AWS
terraform apply
```

Upon a successful `terraform apply`:
* A dynamic `env.sh` and `hosts_k8s.yaml` will be generated inside the `terraform/` folder.
* A private key file `freeswitch-key.pem` will be created in the `terraform/` folder.

---

### 2. Bootstrap Kubernetes Cluster (Kubespray)
Once the EC2 instances are running, you can bootstrap the single-node Kubernetes cluster.

#### Option A: WSL Egress Deployment (Recommended)
If your local machine runs WSL and has Ansible installed, execute:

```bash
# From the repository root in WSL:
chmod +x kubespray/deploy_kubespray_wsl.sh
./kubespray/deploy_kubespray_wsl.sh
```

#### Option B: Remote Local Deployment
If you do not have Ansible locally, trigger the bootstrap script to run entirely on the private server:

```bash
# From the repository root in WSL:
chmod +x kubespray/deploy_kubespray_local.sh
./kubespray/deploy_kubespray_local.sh
```

This will run the deployment inside a `screen` session on the remote server so that connection drops do not abort the installation.
