# Technical Terms Glossary

This document explains all the technical terms and acronyms used in the Automation Alchemy project.

---

## 🔤 Acronyms & Abbreviations

### **CLI** - Command Line Interface
- **What it is**: A text-based way to interact with your computer or services
- **Example**: `gcloud`, `terraform`, `ansible`, `git` commands
- **Why use it**: Faster, more powerful, and automatable compared to clicking buttons in a GUI
- **In our project**: We use `gcloud CLI` to manage GCP, `terraform CLI` to manage infrastructure

### **API** - Application Programming Interface
- **What it is**: A way for programs/services to talk to each other
- **Example**: When GitLab CI pushes a Docker image, it uses GCP's Container Registry API
- **Why use it**: Allows automation - code can do things without human interaction
- **In our project**: 
  - Container Registry API: Lets us push Docker images
  - Compute Engine API: Lets Terraform create VMs
  - Artifact Registry API: Google's newer container storage (we enabled it)

### **IaC** - Infrastructure as Code
- **What it is**: Writing code (instead of clicking buttons) to create servers, networks, etc.
- **Example**: Our `terraform/` directory defines VMs in code
- **Why use it**: Reproducible, version-controlled, can be automated
- **In our project**: Terraform files define our GCP infrastructure

### **CI/CD** - Continuous Integration / Continuous Delivery
- **CI**: Automatically test and build code when changes are made
- **CD**: Automatically deploy code to servers
- **Example**: GitLab CI runs tests, builds Docker images, and deploys
- **Why use it**: Catches bugs early, deploys faster, less manual work
- **In our project**: GitLab CI pipeline automates the entire deployment process

### **VPC** - Virtual Private Cloud
- **What it is**: Your own private network in the cloud
- **Example**: Our VMs are in `automation-alchemy-vpc`
- **Why use it**: Isolates your resources, controls network traffic
- **In our project**: All VMs are in the same VPC so they can communicate

### **VM** - Virtual Machine
- **What it is**: A computer that runs inside another computer (virtualization)
- **Example**: Our `automation-alchemy` VM runs on Google's physical servers
- **Why use it**: Cheaper than physical servers, easy to create/destroy
- **In our project**: We have 1 VM (can scale to 5) running our application

### **SSH** - Secure Shell
- **What it is**: A secure way to remotely access and control a computer
- **Example**: `ssh devops@34.88.104.254` connects to our VM
- **Why use it**: Encrypted, secure remote access
- **In our project**: We use SSH keys to access VMs and run Ansible

### **DNS** - Domain Name System
- **What it is**: Translates human-readable names (like `google.com`) to IP addresses
- **Example**: `34.88.104.254` is our VM's IP address
- **Why use it**: Easier to remember names than numbers
- **In our project**: We use IP addresses directly, but could use DNS for a domain

### **YAML** - YAML Ain't Markup Language
- **What it is**: A human-readable data format (like JSON but easier to read)
- **Example**: Our `.gitlab-ci.yml`, `docker-compose.yml`, Ansible playbooks
- **Why use it**: Easy to read and write, commonly used for configs
- **In our project**: All our configuration files use YAML

### **JSON** - JavaScript Object Notation
- **What it is**: A data format (like YAML but more strict)
- **Example**: Service account keys, Terraform outputs
- **Why use it**: Standard format, easy for programs to parse
- **In our project**: GCP service account keys are JSON files

---

## 🛠️ Tools & Technologies

### **Terraform**
- **What it is**: A tool for creating infrastructure (servers, networks, etc.) using code
- **How it works**: You write `.tf` files describing what you want, Terraform creates it
- **In our project**: Creates VMs, VPCs, firewalls on GCP
- **File**: `terraform/main.tf`, `terraform/variables.tf`

### **Ansible**
- **What it is**: A tool for configuring servers (installing software, setting up services)
- **How it works**: You write playbooks (YAML files) describing what to do, Ansible does it
- **In our project**: Installs Docker, configures firewall, deploys application
- **File**: `ansible/playbooks/*.yml`

### **GitLab CI**
- **What it is**: GitLab's built-in system for running automated tasks (tests, builds, deployments)
- **How it works**: Reads `.gitlab-ci.yml` file, runs jobs in Docker containers
- **In our project**: Validates code, builds Docker images, deploys to VMs
- **File**: `.gitlab-ci.yml`

### **Docker**
- **What it is**: A platform for running applications in containers (lightweight virtual machines)
- **How it works**: Packages your app and its dependencies into a container image
- **In our project**: Our Node.js app runs in a Docker container
- **File**: `docker/app-server/Dockerfile`

### **Docker Compose**
- **What it is**: A tool for running multiple Docker containers together
- **How it works**: Defines all containers in `docker-compose.yml`, runs them together
- **In our project**: Runs app-server, web-servers, load-balancer, netdata together
- **File**: `docker-compose.yml`

### **Container Registry**
- **What it is**: A place to store Docker images (like GitHub for code, but for Docker images)
- **How it works**: You push images there, then pull them when needed
- **In our project**: GCP Container Registry stores our built Docker images
- **URL**: `gcr.io/automation-alchemy/app-server`

### **Artifact Registry**
- **What it is**: Google's newer version of Container Registry (more features)
- **How it works**: Same as Container Registry but with better organization
- **In our project**: We enabled the API (required even for Container Registry)

---

## ☁️ Google Cloud Platform (GCP) Terms

### **GCP** - Google Cloud Platform
- **What it is**: Google's cloud computing service (like AWS, Azure)
- **Services**: Compute Engine (VMs), Container Registry, VPC, etc.
- **In our project**: We use GCP to host our VMs and store Docker images

### **Compute Engine**
- **What it is**: GCP's service for creating virtual machines
- **In our project**: Our VM runs on Compute Engine

### **Service Account**
- **What it is**: A special account for applications (not humans) to access GCP services
- **Example**: `gitlab-ci@automation-alchemy.iam.gserviceaccount.com`
- **Why use it**: Secure way for CI/CD to access GCP without using your personal account
- **In our project**: GitLab CI uses a service account to push Docker images

### **Service Account Key**
- **What it is**: A JSON file that proves the service account's identity
- **Example**: `gitlab-ci-key.json` (stored as base64 in GitLab CI variables)
- **Why use it**: Allows programs to authenticate as the service account
- **In our project**: GitLab CI uses this key to authenticate with GCP

### **IAM** - Identity and Access Management
- **What it is**: System for controlling who can do what in GCP
- **Example**: Service account has `roles/storage.admin` (can push Docker images)
- **Why use it**: Security - only give permissions that are needed
- **In our project**: Service account can push to Container Registry but can't delete VMs

### **Project**
- **What it is**: A container for all your GCP resources (VMs, storage, etc.)
- **Example**: `automation-alchemy` is our project
- **Why use it**: Organizes resources, controls billing
- **In our project**: All our resources are in the `automation-alchemy` project

### **Region/Zone**
- **Region**: A geographic area (e.g., `europe-north1` = Finland)
- **Zone**: A specific data center within a region (e.g., `europe-north1-a`)
- **Why use it**: Choose location for lower latency, compliance, or cost
- **In our project**: VM is in `europe-north1-a` (close to Estonia)

---

## 🔐 Security Terms

### **SSH Key**
- **What it is**: A pair of files (public + private) for secure authentication
- **Public key**: Goes on the server (VM) - anyone can see it
- **Private key**: Stays on your computer - keep it secret!
- **In our project**: We use SSH keys to access VMs securely

### **Base64 Encoding**
- **What it is**: A way to convert binary data (like files) into text
- **Why use it**: Can't store binary files in text fields (like GitLab CI variables)
- **In our project**: Service account key is base64 encoded in GitLab CI variables

### **Protected Variable**
- **What it is**: A GitLab CI variable that's only available to protected branches
- **Why use it**: Security - secrets only available in production branches
- **In our project**: `GCP_SERVICE_ACCOUNT_KEY` is protected (only works on protected `master`)

### **Masked Variable**
- **What it is**: A GitLab CI variable that's hidden in logs (shows as `***`)
- **Why use it**: Prevents secrets from appearing in pipeline logs
- **In our project**: `GCP_SERVICE_ACCOUNT_KEY` and `SSH_PRIVATE_KEY` are masked

---

## 📦 Application Terms

### **Load Balancer**
- **What it is**: Distributes incoming traffic across multiple servers
- **Example**: HAProxy distributes requests between web-server-1 and web-server-2
- **Why use it**: Better performance, high availability
- **In our project**: HAProxy load balances between 2 NGINX web servers

### **Web Server**
- **What it is**: Software that serves web pages to browsers
- **Example**: NGINX serves our `web-content/index.html`
- **Why use it**: Fast, efficient way to serve static files
- **In our project**: 2 NGINX web servers (web-server-1, web-server-2)

### **App Server**
- **What it is**: Software that runs application logic (not just static files)
- **Example**: Node.js app server handles API requests
- **Why use it**: Processes dynamic requests, does calculations
- **In our project**: Node.js Express server on port 3000

### **Health Check**
- **What it is**: A way to verify that a service is working correctly
- **Example**: Docker checks if containers are responding to `/health` endpoint
- **Why use it**: Automatically detects if something breaks
- **In our project**: All containers have health checks

---

## 🔄 Process Terms

### **Pipeline**
- **What it is**: A series of automated steps (validate → build → deploy)
- **Example**: GitLab CI pipeline runs when you push code
- **Why use it**: Automates repetitive tasks
- **In our project**: 4 stages - validate, build, deploy, healthcheck

### **Stage**
- **What it is**: A group of related jobs in a pipeline
- **Example**: "build" stage contains the Docker build job
- **Why use it**: Organizes pipeline into logical steps
- **In our project**: validate, build, deploy, healthcheck stages

### **Job**
- **What it is**: A single task in a pipeline (runs in a Docker container)
- **Example**: `docker:build` job builds and pushes Docker image
- **Why use it**: Each job does one specific thing
- **In our project**: terraform:validate, ansible:lint, docker:build, etc.

### **Artifact**
- **What it is**: Files produced by one job and used by another
- **Example**: Docker image info saved for deployment job
- **Why use it**: Passes data between pipeline stages
- **In our project**: Build stage saves image name, deploy stage uses it

---

## 📝 File Format Terms

### **Dockerfile**
- **What it is**: Instructions for building a Docker image
- **Example**: `FROM node:22-alpine`, `COPY . .`, `CMD ["node", "server.js"]`
- **Why use it**: Defines exactly how to package your application
- **In our project**: `docker/app-server/Dockerfile` builds our Node.js app

### **Playbook**
- **What it is**: An Ansible file that describes what to do on servers
- **Example**: `ansible/playbooks/docker.yml` installs Docker
- **Why use it**: Automates server configuration
- **In our project**: Multiple playbooks for different tasks

### **Inventory**
- **What it is**: A list of servers that Ansible should manage
- **Example**: `ansible/inventory/hosts.yml` lists our VM IPs
- **Why use it**: Tells Ansible which servers to configure
- **In our project**: Auto-generated from Terraform outputs

---

## 🎯 Project-Specific Terms

### **Automation Alchemy**
- **What it is**: The name of this project
- **Meaning**: "Alchemy" = transforming things (manual → automated)

### **Phase 1, 2, 3**
- **Phase 1**: Infrastructure (Terraform) - Create VMs ✅
- **Phase 2**: Configuration (Ansible) - Set up VMs ✅
- **Phase 3**: CI/CD (GitLab CI) - Automate deployments 🚧

### **All-in-One VM**
- **What it is**: Single VM running all services (for cost savings)
- **Why use it**: Free tier allows 1 VM, cheaper than multiple VMs
- **In our project**: One VM runs app-server, web-servers, load-balancer, netdata

---

## 💡 Quick Reference

| Term | Stands For | What It Does |
|------|-----------|--------------|
| **CLI** | Command Line Interface | Text-based tool for running commands |
| **API** | Application Programming Interface | How programs talk to each other |
| **IaC** | Infrastructure as Code | Define servers in code files |
| **CI/CD** | Continuous Integration/Delivery | Automate testing and deployment |
| **VPC** | Virtual Private Cloud | Your private network in the cloud |
| **VM** | Virtual Machine | A computer running inside another computer |
| **SSH** | Secure Shell | Secure remote access to servers |
| **DNS** | Domain Name System | Converts names to IP addresses |
| **YAML** | YAML Ain't Markup Language | Human-readable config format |
| **JSON** | JavaScript Object Notation | Data format for programs |
| **IAM** | Identity and Access Management | Controls who can do what |
| **GCP** | Google Cloud Platform | Google's cloud service |

---

**Last Updated**: 2025-11-20  
**Project**: Automation Alchemy

