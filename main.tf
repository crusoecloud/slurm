terraform {
  required_providers {
    crusoe = {
      source  = "registry.terraform.io/crusoecloud/crusoe"
    }
    ansible = {
      version = "~> 1.3.0"
      source  = "ansible/ansible"
    }
  }
}

locals {
  ssh_public_key = file(var.ssh_public_key_path)
}

resource "crusoe_compute_instance" "slurm_head_node" {
  count      = var.slurm_head_node_count
  name       = "slurm-head-node-${count.index}"
  type       = "c1a.16x"
  ssh_key    = local.ssh_public_key
  location   = var.location
  project_id = var.project_id
  image    = "ubuntu22.04-nvidia-slurm:latest"
  network_interfaces = [{
    subnet = var.vpc_subnet_id,
    public_ipv4 = {
      type = "static"
    }
  }]
}

resource "crusoe_compute_instance" "slurm_login_node" {
  count      = var.slurm_login_node_count
  name       = "slurm-login-node-${count.index}"
  type       = "c1a.16x"
  ssh_key    = local.ssh_public_key
  location   = var.location
  project_id = var.project_id
  image    = "ubuntu22.04-nvidia-slurm:latest"
  network_interfaces = [{
    subnet = var.vpc_subnet_id,
    public_ipv4 = {
      type = "static"
    }
  }]
}

resource "crusoe_storage_disk" "slurm_nfs_home" {
  name = "slurm-nfs-home"
  size = var.slurm_nfs_home_size
  location = var.location
  project_id = var.project_id
}

resource "crusoe_compute_instance" "slurm_nfs_node" {
  count      = 1
  name       = "slurm-nfs-node-${count.index}"
  type       = var.slurm_nfs_node_type
  ssh_key    = local.ssh_public_key
  location   = var.location
  project_id = var.project_id
  image      = "ubuntu22.04:latest"
  disks = [{ 
      id = crusoe_storage_disk.slurm_nfs_home.id
      mode = "read-write"
      attachment_type = "data"
  }]
  network_interfaces = [{
    subnet = var.vpc_subnet_id,
    public_ipv4 = {
      type = "static"
    }
  }]
}

# If an ib_network_id is defined, create an infiniband partition for the slurm
# compute nodes. This is only necessary / possible on compute instance types
# that support infiniband.
resource "crusoe_ib_partition" "slurm_ib_partition" {
  count = var.slurm_compute_node_ib_network_id != null ? 1: 0
  ib_network_id = var.slurm_compute_node_ib_network_id
  name     = "slurm-ib-partition"
  project_id = var.project_id
}

resource "crusoe_compute_instance" "slurm_compute_node" {
  count    = var.slurm_compute_node_count
  name     = "slurm-compute-node-${count.index}"
  type       = var.slurm_compute_node_type
  ssh_key  = local.ssh_public_key
  location = var.location
  project_id = var.project_id
  image    = "ubuntu22.04-nvidia-slurm:latest"
  host_channel_adapters = var.slurm_compute_node_ib_network_id != null ? [{
    ib_partition_id = crusoe_ib_partition.slurm_ib_partition[0].id
  }]: null
  network_interfaces = [{
    subnet = var.vpc_subnet_id,
    public_ipv4 = {
      type = "static"
    }
  }]
}

resource "ansible_host" "slurm_nfs_node_host" {
  for_each = {
    for n in crusoe_compute_instance.slurm_nfs_node : n.name => n
  }

  name      = each.value.name
  groups    = [ "slurm_nfs_nodes" ]
  variables = {
    ansible_host = each.value.network_interfaces[0].public_ipv4.address
    instance_type = each.value.type
    location = each.value.location
  }
}

resource "ansible_host" "slurm_head_node_host" {
  for_each = {
    for n in crusoe_compute_instance.slurm_head_node : n.name => n
  }

  name      = each.value.name
  groups    = [ "slurm_head_nodes" ]
  variables = {
    ansible_host = each.value.network_interfaces[0].public_ipv4.address
    instance_type = each.value.type
    location = each.value.location
  }
}

resource "ansible_host" "slurm_login_node_host" {
  for_each = {
    for n in crusoe_compute_instance.slurm_login_node : n.name => n
  }

  name      = each.value.name
  groups    = [ "slurm_login_nodes" ]
  variables = {
    ansible_host = each.value.network_interfaces[0].public_ipv4.address
    instance_type = each.value.type
    location = each.value.location
  }
}

resource "ansible_host" "slurm_compute_node_host" {
  for_each = {
    for n in crusoe_compute_instance.slurm_compute_node : n.name => n
  }

  name      = each.value.name
  groups    = [ "slurm_compute_nodes" ]
  variables = {
    ansible_host = each.value.network_interfaces[0].public_ipv4.address
    instance_type = each.value.type
    location = each.value.location
  }
}

resource "ansible_group" "all" {
  name     = "all"
  variables = {
    slurm_users = jsonencode(var.slurm_users)
  }
}

resource "null_resource" "ansible_playbook" {
  # Always run ansible-playbook.
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "ansible-galaxy install -r ansible/roles/requirements.yml"
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i ansible/inventory/inventory.yml ansible/slurm.yml -f 128"
  }

  depends_on = [
    ansible_host.slurm_nfs_node_host,
    ansible_host.slurm_head_node_host,
    ansible_host.slurm_login_node_host,
    ansible_host.slurm_compute_node_host,
    ansible_group.all
  ]
}
