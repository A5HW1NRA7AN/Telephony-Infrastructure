# Infrastructure

This repository manages AWS cloud resources, Kubernetes cluster configurations, and Jenkins setups for the Telephony project. It is structured to support multiple styles of deployment.

## Repository Structure

```
Infrastructure/
├── README.md
├── freeswitch-ec2/             # Standalone EC2 Deployment
│   └── terraform/              # Terraform scripts (VMs automatically configured with Docker)
├── freeswitch-kubernetes/      # Kubernetes-based Deployments (Missed Call & IVR)
│   ├── terraform/              # Terraform scripts for provisioning cluster VMs
│   └── kubespray/              # Ansible configurations for K8s bootstrapping
└── jenkins/                    # CI/CD Infrastructure
    ├── Dockerfile              # Dockerized Jenkins server
    ├── casc.yaml               # Jenkins Configuration-as-Code settings
    ├── docker-compose.yml      # Docker compose configuration to run Jenkins
    └── plugins.txt             # Required Jenkins plugins list
```

---

## Deployment Styles

### 1. Standalone EC2 Deployment (`freeswitch-ec2/`)

This configuration provisions a Bastion host, an Nginx SIP/RTP Proxy, and a private FreeSWITCH instance automatically configured with Docker and Docker Compose. 

#### Provisioning via Terraform
Navigate to the `freeswitch-ec2/terraform/` directory and execute:
```bash
terraform init
terraform plan
terraform apply
```

This will output the public and private IP addresses and generate the private key file `freeswitch-key.pem` locally. The Jenkins pipeline on the `freeswitch` branch in the Telephony repository will use these parameters to build and deploy the containers to the private instance.

---

### 2. Kubernetes Deployment (`freeswitch-kubernetes/`)

This configuration provisions the identical VM infrastructure but leaves the FreeSWITCH private server unconfigured so that it can be bootstrapped as a Kubernetes node.

#### Step 1: Provision Cluster VMs
Navigate to the `freeswitch-kubernetes/terraform/` directory and execute:
```bash
terraform init
terraform plan
terraform apply
```

This generates `env.sh` and `hosts_k8s.yaml` inside the `terraform/` folder which are utilized by the Kubespray playbooks.

#### Step 2: Bootstrap Kubernetes Cluster
Bootstrap the Kubernetes cluster using Kubespray from WSL:
```bash
chmod +x freeswitch-kubernetes/kubespray/deploy_kubespray_wsl.sh
./freeswitch-kubernetes/kubespray/deploy_kubespray_wsl.sh
```

Once the cluster is bootstrapped, deployments are managed by Helm charts from the `freeswitch-kubernetes` and `freeswitch-ivr-kubernetes` branches in the Telephony repository.

---

### 3. Jenkins CI/CD Setup (`jenkins/`)

The `jenkins/` directory contains configuration files for running a Dockerized Jenkins instance with Jenkins Configuration-as-Code (JCasC).

To run Jenkins:
1. Copy the `.env.example` from the Jenkins setup directory to `.env` and fill in your AWS credentials.
2. Run `docker compose up -d --build` inside the `jenkins/` folder.
3. Access the Jenkins dashboard at `http://localhost:8080` (or server port). Pipelines for the Telephony project branches will automatically load.

---

## ECR IAM Role Authentication

The private FreeSWITCH instance is launched with the IAM instance profile `EC2-ECR-Read-Role`. This enables Docker or Kubernetes (containerd) to authenticate and pull private images from Amazon ECR directly without requiring local Docker login configurations or Kubernetes registry secrets.

