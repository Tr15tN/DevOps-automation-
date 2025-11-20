variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "europe-north1" # Finland - closest to Estonia
}

variable "zone" {
  description = "The GCP zone for resources"
  type        = string
  default     = "europe-north1-a"
}

variable "vm_count" {
  description = "Number of VMs to create (1 = free tier, 4-5 = full setup)"
  type        = number
  default     = 1
}

variable "vm_machine_type" {
  description = "Machine type for VMs (e2-micro is free tier)"
  type        = string
  default     = "e2-micro"
}

variable "vm_disk_size" {
  description = "Boot disk size in GB (30GB is free tier)"
  type        = number
  default     = 30
}

variable "vm_disk_type" {
  description = "Boot disk type"
  type        = string
  default     = "pd-standard"
}

variable "vm_image" {
  description = "VM image to use"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "ssh_user" {
  description = "SSH username for VMs"
  type        = string
  default     = "devops"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "vm_tags" {
  description = "Tags for VMs"
  type        = list(string)
  default     = ["automation-alchemy"]
}

variable "enable_monitoring" {
  description = "Enable monitoring agent on VMs"
  type        = bool
  default     = true
}

variable "vm_roles" {
  description = "VM roles and their configurations"
  type = map(object({
    name         = string
    machine_type = string
    disk_size    = number
  }))
  default = {
    load-balancer = {
      name         = "load-balancer"
      machine_type = "e2-micro"
      disk_size    = 30
    }
    web-server-1 = {
      name         = "web-server-1"
      machine_type = "e2-micro"
      disk_size    = 30
    }
    web-server-2 = {
      name         = "web-server-2"
      machine_type = "e2-micro"
      disk_size    = 30
    }
    app-server = {
      name         = "app-server"
      machine_type = "e2-micro"
      disk_size    = 30
    }
    jenkins = {
      name         = "jenkins"
      machine_type = "e2-micro"
      disk_size    = 30
    }
  }
}

