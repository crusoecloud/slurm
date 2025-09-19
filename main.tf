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
  type       = var.slurm_head_node_type
  ssh_key    = local.ssh_public_key
  location   = var.location
  project_id = var.project_id
  image    = "ubuntu22.04-nvidia-slurm:latest"
  reservation_id = var.slurm_head_node_reservation_id
  host_channel_adapters = var.slurm_head_node_ib_partition_id != null ? [{
    ib_partition_id = var.slurm_head_node_ib_partition_id
  }]: null
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
  type       = var.slurm_login_node_type
  ssh_key    = local.ssh_public_key
  location   = var.location
  project_id = var.project_id
  image    = "ubuntu22.04-nvidia-slurm:latest"
  reservation_id = var.slurm_login_node_reservation_id
  host_channel_adapters = var.slurm_login_node_ib_partition_id != null ? [{
    ib_partition_id = var.slurm_login_node_ib_partition_id
  }]: null
  network_interfaces = [{
    subnet = var.vpc_subnet_id,
    public_ipv4 = {
      type = "static"
    }
  }]
  disks = [for v in var.slurm_shared_volumes: {
    id = v.id
    mode = v.mode
    attachment_type = "data"
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
  reservation_id = var.slurm_nfs_node_reservation_id
  host_channel_adapters = var.slurm_nfs_node_ib_partition_id != null ? [{
    ib_partition_id = var.slurm_nfs_node_ib_partition_id
  }]: null
  network_interfaces = [{
    subnet = var.vpc_subnet_id,
    public_ipv4 = {
      type = "static"
    }
  }]
}

resource "crusoe_compute_instance" "slurm_compute_node" {
  count    = var.slurm_compute_node_count
  name     = "slurm-compute-node-${count.index}"
  type       = var.slurm_compute_node_type
  ssh_key  = local.ssh_public_key
  location = var.location
  project_id = var.project_id
  image    = "ubuntu22.04-nvidia-slurm:latest"
  reservation_id = var.slurm_compute_node_reservation_id
  host_channel_adapters = var.slurm_compute_node_ib_partition_id != null ? [{
    ib_partition_id = var.slurm_compute_node_ib_partition_id
  }]: null
  network_interfaces = [{
    subnet = var.vpc_subnet_id,
    public_ipv4 = {
      type = "static"
    }
  }]
  disks = [for v in var.slurm_shared_volumes: {
    id = v.id
    mode = v.mode
    attachment_type = "data"
  }]
}

resource "ansible_host" "slurm_nfs_node_host" {
  for_each = {
    for n in crusoe_compute_instance.slurm_nfs_node : n.name => n
  }

  name      = each.value.name
  groups    = [
    "slurm_nfs_nodes",
    replace(split(".", each.value.type)[0], "-", "_"),
  ]
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
  groups    = [
    "slurm_head_nodes",
    replace(split(".", each.value.type)[0], "-", "_"),
  ]
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
  groups    = [
    "slurm_compute_nodes",
    replace(split(".", each.value.type)[0], "-", "_"),
  ]
  variables = {
    ansible_host = each.value.network_interfaces[0].public_ipv4.address
    slurm_features = jsonencode([ "login" ])
    instance_type = each.value.type
    location = each.value.location
    volumes = jsonencode(var.slurm_shared_volumes)
  }
}

resource "ansible_host" "slurm_compute_node_host" {
  for_each = {
    for n in crusoe_compute_instance.slurm_compute_node : n.name => n
  }

  name      = each.value.name
  groups    = [
    "slurm_compute_nodes",
    replace(split(".", each.value.type)[0], "-", "_"),
  ]
  variables = {
    ansible_host = each.value.network_interfaces[0].public_ipv4.address
    slurm_features = jsonencode([ "batch" ])
    instance_type = each.value.type
    location = each.value.location
    volumes = jsonencode(var.slurm_shared_volumes)
  }
}

resource "ansible_group" "all" {
  name     = "all"
  variables = {
    slurm_users = jsonencode(var.slurm_users)
    partitions = jsonencode(var.partitions)
    enable_observability = var.enable_observability
    grafana_admin_password = var.grafana_admin_password
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
