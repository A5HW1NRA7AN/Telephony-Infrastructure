# Telephony-Infrastructure

This repository manages AWS cloud resources, Kubernetes cluster configurations, and Jenkins setups for the Telephony project. It is structured to support multiple styles of deployment.

## Repository Structure

```
Telephony-Infrastructure/
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

## ECR Registry Authentication

- **EC2 Standalone Environment**: The private FreeSWITCH instance is launched with the IAM instance profile `EC2-ECR-Read-Role` which automatically logs the Docker daemon into Amazon ECR.
- **Kubernetes Environment**: The Kubelet pulls private ECR images using a Kubernetes Image Pull Secret named `regcred`. This secret is automatically refreshed and updated in the default namespace during every Jenkins deployment via the pipeline (`Jenkinsfile`), eliminating the need to manage it manually.

---

## Operational Administration Guide (Agnostic CLI Reference)

To support team sharing and tool-agnostic operations, no custom local `.sh` wrapper scripts are required. All administrative actions are executed using standard native commands.

### 1. Download Kubeconfig securely
To fetch the cluster `admin.conf` and configure your local `kubectl` to access the cluster securely via the Nginx NAT Proxy:
```bash
# 1. Fetch admin.conf from the master node (10.0.1.143) through the Bastion jump host
ssh -i ./freeswitch-key.pem -o StrictHostKeyChecking=no \
  -o ProxyCommand="ssh -i ./freeswitch-key.pem -o StrictHostKeyChecking=no -W %h:%p ubuntu@<BASTION_PUBLIC_IP>" \
  ubuntu@10.0.1.143 "sudo cat /etc/kubernetes/admin.conf" > kubeconfig.yaml

# 2. Modify the API Server endpoint to point to the Proxy public EIP
sed -i "s/127.0.0.1:6443/<PROXY_PUBLIC_IP>:6443/g" kubeconfig.yaml

# 3. Export for kubectl usage (with full TLS verification enabled)
export KUBECONFIG=$(pwd)/kubeconfig.yaml
```

### 2. Verify Infrastructure & System Status
To check the running status of your environments natively:
```bash
# Check Kubernetes Cluster Nodes & Pods
kubectl get nodes -o wide
kubectl get pods -A

# Check Standalone EC2 FreeSWITCH Containers (via Bastion tunnel)
ssh -i ./freeswitch-key.pem \
  -o ProxyCommand="ssh -i ./freeswitch-key.pem -W %h:%p ubuntu@<BASTION_PUBLIC_IP>" \
  ubuntu@10.0.1.143 "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'"

# Check Jenkins CI/CD Status
# Send a query to the Jenkins API to check jobs
curl -s -u "<JENKINS_USER>:<JENKINS_API_TOKEN>" "http://<JENKINS_PUBLIC_IP>:8080/api/json"
```

### 3. Regenerate Kubernetes API Certificates (Add new Proxy EIP to SANs)
If the Proxy IP changes or is regenerated, you must update the certificate SANs so that `kubectl` can verify the TLS connection securely:
1. Update `supplementary_addresses_in_ssl_keys: [ "<NEW_PROXY_PUBLIC_IP>" ]` in `/home/rajan/Projects/kubespray/inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml`.
2. Run the Kubespray certificate playbook from the Kubespray root directory:
```bash
ansible-playbook -i inventory/mycluster/hosts.yaml --become --become-user=root cluster.yml --tags=certs
```

### 4. Reload Jenkins Configuration-as-Code (JCasC)
To trigger an immediate reload of Jenkins JCasC settings after updating remote credentials:
```bash
curl -X POST -u "<JENKINS_USER>:<JENKINS_API_TOKEN>" "http://<JENKINS_PUBLIC_IP>:8080/configuration-as-code/reload"
```


