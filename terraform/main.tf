# Configure the Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
  ])

  project = var.project_id
  service = each.value

  disable_dependent_services = false
  disable_on_destroy         = false
}

# Create VPC network
resource "google_compute_network" "main" {
  name                    = "automation-alchemy-vpc"
  auto_create_subnetworks = false
  description             = "VPC for Automation Alchemy project"

  depends_on = [google_project_service.required_apis]
}

# Create subnet
resource "google_compute_subnetwork" "main" {
  name          = "automation-alchemy-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.main.id
  description   = "Subnet for Automation Alchemy VMs"
}

# Create firewall rule for SSH
resource "google_compute_firewall" "ssh" {
  name    = "allow-ssh"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"] # In production, restrict this to your IP
  target_tags   = var.vm_tags
  description   = "Allow SSH access"
}

# Create firewall rule for HTTP
resource "google_compute_firewall" "http" {
  name    = "allow-http"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "8081", "8082", "3000"]
  }

  source_ranges = ["0.0.0.0/0"] # In production, restrict this
  target_tags   = var.vm_tags
  description   = "Allow HTTP/HTTPS access"
}

# Create firewall rule for HAProxy stats
resource "google_compute_firewall" "haproxy_stats" {
  name    = "allow-haproxy-stats"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["8404"]
  }

  source_ranges = ["0.0.0.0/0"] # In production, restrict this
  target_tags   = var.vm_tags
  description   = "Allow HAProxy stats access"
}

# Create firewall rule for Netdata
resource "google_compute_firewall" "netdata" {
  name    = "allow-netdata"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["19999"]
  }

  source_ranges = ["0.0.0.0/0"] # In production, restrict this
  target_tags   = var.vm_tags
  description   = "Allow Netdata monitoring access"
}

# Create firewall rule for internal communication
resource "google_compute_firewall" "internal" {
  name    = "allow-internal"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [google_compute_subnetwork.main.ip_cidr_range]
  target_tags   = var.vm_tags
  description   = "Allow internal communication between VMs"
}

# Read SSH public key
locals {
  ssh_public_key = try(file(var.ssh_public_key_path), "")
}

# Create VMs based on vm_count
# If vm_count = 1, create single VM with all services
# If vm_count >= 4, create separate VMs for each role
locals {
  # Determine which VMs to create based on vm_count
  create_vms = var.vm_count == 1 ? {
    "all-in-one" = {
      name        = "automation-alchemy"
      machine_type = var.vm_machine_type
      disk_size    = var.vm_disk_size
      role         = "all-in-one"
    }
  } : var.vm_count == 4 ? {
    "load-balancer" = var.vm_roles["load-balancer"]
    "web-server-1" = var.vm_roles["web-server-1"]
    "web-server-2" = var.vm_roles["web-server-2"]
    "app-server"   = var.vm_roles["app-server"]
  } : {
    for role, config in var.vm_roles : role => config
  }
}

# Create compute instances
resource "google_compute_instance" "vms" {
  for_each = local.create_vms

  name         = each.value.name
  machine_type = each.value.machine_type
  zone         = var.zone
  tags         = var.vm_tags

  boot_disk {
    initialize_params {
      image = var.vm_image
      size  = each.value.disk_size
      type  = var.vm_disk_type
    }
  }

  network_interface {
    network    = google_compute_network.main.name
    subnetwork = google_compute_subnetwork.main.name

    # No public IP - we'll use IAP or bastion host for access
    # For now, assign public IP for simplicity (can be changed later)
    access_config {
      # Ephemeral public IP
    }
  }

  # Metadata for SSH key
  metadata = {
    ssh-keys = "${var.ssh_user}:${local.ssh_public_key}"
  }

  # Enable monitoring
  metadata_startup_script = <<-EOF
    #!/bin/bash
    # Update system
    apt-get update
    apt-get upgrade -y
    
    # Install basic tools
    apt-get install -y curl wget git
    
    # Set hostname
    hostnamectl set-hostname ${each.value.name}
    
    # Log completion
    echo "VM ${each.value.name} initialized at $(date)" >> /var/log/startup.log
  EOF

  # Service account for VM (minimal permissions)
  service_account {
    email  = google_service_account.vm_service_account.email
    scopes = ["cloud-platform"]
  }

  depends_on = [
    google_project_service.required_apis,
    google_compute_subnetwork.main,
  ]
}

# Create service account for VMs
resource "google_service_account" "vm_service_account" {
  account_id   = "automation-alchemy-vm-sa"
  display_name = "Service Account for Automation Alchemy VMs"
  description  = "Service account with minimal permissions for VMs"
}

# Grant minimal IAM permissions to service account
resource "google_project_iam_member" "vm_service_account" {
  for_each = toset([
    "roles/monitoring.metricWriter",
    "roles/logging.logWriter",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.vm_service_account.email}"
}

