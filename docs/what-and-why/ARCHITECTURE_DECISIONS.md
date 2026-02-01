# Architecture Decisions - Automation Alchemy

This document records the architectural decisions made during the project, including the rationale and trade-offs.

---

## ADR-001: Cloud Provider Selection

**Decision**: Use Google Cloud Platform (GCP) instead of local VMs or other cloud providers.

**Context**: 
- Future project (Voyager) requires cloud infrastructure
- Need to learn cloud provider fundamentals
- Budget constraints (want to keep costs low)

**Options Considered**:
1. **Local VMs** (VirtualBox/Hyper-V)
2. **AWS** (Amazon Web Services)
3. **GCP** (Google Cloud Platform)
4. **Azure** (Microsoft Azure)

**Decision**: GCP

**Rationale**:
- ✅ **Best Free Tier**: 1 e2-micro VM free forever (not just 12 months)
- ✅ **$300 Credit**: 90 days of free usage
- ✅ **Future Alignment**: Next project uses GCP
- ✅ **Simple Pricing**: Easier to understand than AWS
- ✅ **Good Documentation**: Excellent learning resources

**Trade-offs**:
- ❌ Requires internet connection
- ❌ Small monthly cost if scaling beyond free tier
- ⚠️ Less common than AWS in job market (but still widely used)

**Status**: ✅ Implemented

---

## ADR-002: Infrastructure as Code Tool

**Decision**: Use Terraform for infrastructure provisioning.

**Context**:
- Need to automate VM creation
- Future project requires Terraform
- Want declarative infrastructure

**Options Considered**:
1. **Terraform** (HashiCorp)
2. **Vagrant** (HashiCorp)
3. **Cloud Console** (Manual)
4. **gcloud CLI** (Scripts)

**Decision**: Terraform

**Rationale**:
- ✅ **Industry Standard**: Most popular IaC tool
- ✅ **Multi-Cloud**: Works with AWS, GCP, Azure
- ✅ **Declarative**: Easy to read and understand
- ✅ **State Management**: Tracks infrastructure changes
- ✅ **Future Alignment**: Required in next project
- ✅ **Large Community**: Lots of modules and examples

**Trade-offs**:
- ⚠️ Learning curve for HCL syntax
- ⚠️ Requires provider setup

**Status**: ✅ Implemented

---

## ADR-003: Configuration Management Tool

**Decision**: Use Ansible for server configuration and hardening.

**Context**:
- Need to configure multiple VMs
- Future project uses Helm (Kubernetes), but VMs need configuration
- Want agentless solution

**Options Considered**:
1. **Ansible** (Red Hat)
2. **Chef** (Progress)
3. **Puppet** (Puppet)
4. **Manual Scripts**

**Decision**: Ansible

**Rationale**:
- ✅ **Agentless**: No software to install on VMs
- ✅ **Simple YAML**: Easy to learn and read
- ✅ **Idempotent**: Safe to run multiple times
- ✅ **Perfect Scale**: Ideal for 4-5 VMs
- ✅ **Large Module Library**: Lots of built-in modules

**Trade-offs**:
- ⚠️ Requires SSH access (but we have that)
- ⚠️ Can be slow for large infrastructures (but we only have 4-5 VMs)

**Status**: Implemented

---

## ADR-004: CI/CD Platform

**Decision**: Use GitLab CI instead of Jenkins.

**Context**:
- Need CI/CD pipeline
- Future project explicitly requires GitLab CI
- Want to learn relevant tools

**Options Considered**:
1. **Jenkins** (CloudBees)
2. **GitLab CI** (GitLab)
3. **GitHub Actions** (GitHub)
4. **CircleCI** (CircleCI)

**Decision**: GitLab CI

**Rationale**:
- ✅ **Future Requirement**: Next project requires GitLab CI
- ✅ **Integrated**: Works with GitLab (if using GitLab)
- ✅ **Simple YAML**: Easy to configure
- ✅ **Modern**: More modern than Jenkins
- ✅ **Free Tier**: GitLab.com has free tier

**Trade-offs**:
- ⚠️ Less flexible than Jenkins for complex workflows
- ⚠️ Requires GitLab (but can use GitLab.com free)

**Status**: Implemented

---

## ADR-005: Initial VM Count

**Decision**: Start with 1 VM (`vm_count = 1`), scale to 4-5 later.

**Context**:
- Budget constraints (want to keep costs low)
- Learning focus (tools, not multi-VM complexity)
- Can scale later when needed

**Options Considered**:
1. **1 VM**: All services on one VM
2. **4 VMs**: Load balancer + 2 web + app
3. **5 VMs**: Adds Jenkins VM

**Decision**: Start with 1 VM

**Rationale**:
- ✅ **Cost**: $0/month (free tier)
- ✅ **Sufficient**: All services can run via Docker Compose
- ✅ **Learning**: Focus on automation tools
- ✅ **Scalable**: Easy to change `vm_count` later

**Trade-offs**:
- ❌ Less realistic (not true multi-VM setup)
- ❌ Single point of failure
- ✅ But can scale to 4-5 VMs anytime

**Status**: ✅ Implemented (configurable)

---

## ADR-006: VM Machine Type

**Decision**: Use `e2-micro` machine type.

**Context**:
- Want to use free tier
- Need to minimize costs
- Services are lightweight

**Options Considered**:
1. **e2-micro**: 1 vCPU, 1GB RAM (FREE)
2. **e2-small**: 2 vCPU, 2GB RAM (~$7/month)
3. **e2-medium**: 2 vCPU, 4GB RAM (~$14/month)

**Decision**: e2-micro

**Rationale**:
- ✅ **Free Tier**: 1 e2-micro is free forever
- ✅ **Sufficient**: Enough for learning/development
- ✅ **Cost-Effective**: Additional VMs only ~$7/month
- ✅ **Upgradeable**: Can change machine type later

**Trade-offs**:
- ⚠️ Limited resources (1GB RAM)
- ⚠️ Shared CPU (not dedicated)
- ✅ But sufficient for our use case

**Status**: ✅ Implemented

---

## ADR-007: Network Architecture

**Decision**: Create custom VPC instead of using default network.

**Context**:
- Need network isolation
- Want control over IP ranges
- Best practice for production

**Options Considered**:
1. **Default Network**: GCP auto-created network
2. **Custom VPC**: Manually created network

**Decision**: Custom VPC

**Rationale**:
- ✅ **Isolation**: Separate network for our project
- ✅ **Control**: Full control over IP ranges
- ✅ **Best Practice**: Production environments use custom VPCs
- ✅ **Learning**: Understand VPC concepts
- ✅ **Security**: Can implement stricter rules

**Trade-offs**:
- ⚠️ More setup required
- ✅ But better for learning and production

**Status**: ✅ Implemented

---

## ADR-008: SSH Authentication

**Decision**: Use SSH public key authentication instead of passwords.

**Context**:
- Need secure access to VMs
- Ansible requires SSH
- Best practice for cloud infrastructure

**Options Considered**:
1. **SSH Keys**: Public/private key pair
2. **Passwords**: Username/password
3. **GCP IAP**: Identity-Aware Proxy

**Decision**: SSH Keys

**Rationale**:
- ✅ **Security**: More secure than passwords
- ✅ **Automation**: Required for Ansible
- ✅ **Best Practice**: Standard for cloud infrastructure
- ✅ **No Password Management**: Keys are easier

**Trade-offs**:
- ⚠️ Need to manage keys
- ✅ But standard practice

**Status**: ✅ Implemented

---

## ADR-009: Service Account Permissions

**Decision**: Create dedicated service account with minimal permissions.

**Context**:
- VMs need some GCP API access
- Security best practice
- Principle of least privilege

**Options Considered**:
1. **Default Service Account**: Full permissions
2. **Custom Service Account**: Minimal permissions
3. **No Service Account**: No GCP API access

**Decision**: Custom Service Account with Minimal Permissions

**Rationale**:
- ✅ **Security**: Principle of least privilege
- ✅ **Best Practice**: Don't use default service account
- ✅ **Audit Trail**: Easier to track actions
- ✅ **Future-Proof**: Can add permissions later

**Permissions Granted**:
- `roles/monitoring.metricWriter`: Write metrics
- `roles/logging.logWriter`: Write logs

**Trade-offs**:
- ⚠️ Need to create and manage service account
- ✅ But much more secure

**Status**: ✅ Implemented

---

## ADR-010: Firewall Rule Scope

**Decision**: Initially open firewall rules to `0.0.0.0/0` (all IPs) for development.

**Context**:
- Need to access VMs from anywhere during development
- Learning environment, not production
- Can restrict later

**Options Considered**:
1. **Open (0.0.0.0/0)**: Allow all IPs
2. **Restricted**: Only specific IPs
3. **VPN Only**: Access via VPN

**Decision**: Open for development, document restriction for production

**Rationale**:
- ✅ **Convenience**: Easy access during development
- ✅ **Learning**: Focus on automation, not security hardening yet
- ✅ **Flexible**: Can restrict later
- ✅ **Documented**: Clear that production should restrict

**Trade-offs**:
- ❌ Less secure (but acceptable for dev)
- ✅ Will restrict in production

**Status**: ✅ Implemented (with production notes)

---

## Summary

| Decision | Tool/Approach | Status |
|----------|---------------|--------|
| Cloud Provider | GCP | ✅ Implemented |
| IaC Tool | Terraform | ✅ Implemented |
| Config Management | Ansible | Implemented |
| CI/CD | GitLab CI | Implemented |
| Initial VM Count | 1 (scalable) | ✅ Implemented |
| Machine Type | e2-micro | ✅ Implemented |
| Network | Custom VPC | ✅ Implemented |
| Authentication | SSH Keys | ✅ Implemented |
| Service Account | Minimal Permissions | ✅ Implemented |
| Firewall | Open (dev), Restricted (prod) | ✅ Implemented |

---

## 📝 Update Reminder

**This document should be updated when making or changing architectural decisions.**

