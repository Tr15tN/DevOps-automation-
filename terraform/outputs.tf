# Output VM information for Ansible inventory
output "vm_instances" {
  description = "Information about created VM instances"
  value = {
    for k, v in google_compute_instance.vms : k => {
      name        = v.name
      internal_ip = v.network_interface[0].network_ip
      external_ip = v.network_interface[0].access_config[0].nat_ip
      zone        = v.zone
      role        = try(local.create_vms[k].role, contains(keys(local.create_vms), k) ? k : "unknown")
    }
  }
}

# Output for Ansible inventory file generation
output "ansible_inventory" {
  description = "Ansible inventory in INI format"
  value       = <<-EOT
    [all]
    %{for k, v in google_compute_instance.vms~}
    ${v.name} ansible_host=${v.network_interface[0].access_config[0].nat_ip} ansible_user=${var.ssh_user} role=${k}
    %{endfor~}
    
    [load_balancer]
    %{for k, v in google_compute_instance.vms~}
    %{if k == "load-balancer" || k == "all-in-one"~}
    ${v.name} ansible_host=${v.network_interface[0].access_config[0].nat_ip} ansible_user=${var.ssh_user}
    %{endif~}
    %{endfor~}
    
    [web_servers]
    %{for k, v in google_compute_instance.vms~}
    %{if k == "web-server-1" || k == "web-server-2" || k == "all-in-one"~}
    ${v.name} ansible_host=${v.network_interface[0].access_config[0].nat_ip} ansible_user=${var.ssh_user}
    %{endif~}
    %{endfor~}
    
    [app_servers]
    %{for k, v in google_compute_instance.vms~}
    %{if k == "app-server" || k == "all-in-one"~}
    ${v.name} ansible_host=${v.network_interface[0].access_config[0].nat_ip} ansible_user=${var.ssh_user}
    %{endif~}
    %{endfor~}
    
    [jenkins]
    %{for k, v in google_compute_instance.vms~}
    %{if k == "jenkins" || k == "all-in-one"~}
    ${v.name} ansible_host=${v.network_interface[0].access_config[0].nat_ip} ansible_user=${var.ssh_user}
    %{endif~}
    %{endfor~}
  EOT
}

# Output VPC information
output "vpc_network" {
  description = "VPC network information"
  value = {
    name   = google_compute_network.main.name
    id     = google_compute_network.main.id
    subnet = google_compute_subnetwork.main.name
    cidr   = google_compute_subnetwork.main.ip_cidr_range
  }
}

# Output project information
output "project_info" {
  description = "Project information"
  value = {
    project_id = var.project_id
    region     = var.region
    zone       = var.zone
  }
}

