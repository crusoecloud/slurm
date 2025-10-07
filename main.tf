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

resource "crusoe_storage_disk" "slurm_data_disk" {
  count = var.use_vast_nfs && var.pre_existing_slurm_data_disk_id == null ? 1 : 0
  name     = "slurm-data-disk"
  size     = var.slurm_data_disk_size
  location = var.location
  project_id = var.project_id
  type     = "shared-volume"
}

resource "crusoe_storage_disk" "slurm_nfs_home_disk" {
  count = var.use_vast_nfs ? 1 : 0
  name     = "slurm-nfs-home-disk"
  size     = var.slurm_shared_disk_nfs_home_size
  location = var.location
  project_id = var.project_id
  type     = "shared-volume"
}

resource "crusoe_storage_disk" "slurmctld_disk" {
  count = var.use_vast_nfs ? 1 : 0
  name     = "slurmctld-disk"
  size     = var.slurmctld_disk_size
  location = var.location
  project_id = var.project_id
  type     = "shared-volume"
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
  disks = var.use_vast_nfs ? [{
    id              = crusoe_storage_disk.slurmctld_disk[0].id
    mode            = "read-write"
    attachment_type = "data"
  },{
    id              = crusoe_storage_disk.slurm_nfs_home_disk[0].id
    mode            = "read-write"
    attachment_type = "data"
  }] : []
}

output "slurm_head_nodes_addr" {
  description = "Head node(s)"
  value = crusoe_compute_instance.slurm_head_node[*].network_interfaces[0].public_ipv4.address
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
  disks = var.use_vast_nfs ? [
  {
    id              = crusoe_storage_disk.slurm_nfs_home_disk[0].id
    mode            = "read-write"
    attachment_type = "data"
  },
  {
    id              = coalesce(
      var.pre_existing_slurm_data_disk_id,
      try(crusoe_storage_disk.slurm_data_disk[0].id, null)
    )
    mode            = "read-write"
    attachment_type = "data"
  }
  ] : [
  for v in try(var.slurm_shared_volumes, []) : {
    id              = v.id
    mode            = v.mode
    attachment_type = "data"
  }]
}

output "slurm_login_nodes_addr" {
  description = "Login node(s)"
  value = crusoe_compute_instance.slurm_login_node[*].network_interfaces[0].public_ipv4.address
}

resource "crusoe_storage_disk" "slurm_nfs_home" {
  count = var.use_vast_nfs ? 0 : 1
  name = "slurm-nfs-home"
  size = var.slurm_nfs_home_size
  location = var.location
  project_id = var.project_id
}

moved {
  from = crusoe_storage_disk.slurm_nfs_home
  to   = crusoe_storage_disk.slurm_nfs_home[0]
}

resource "crusoe_compute_instance" "slurm_nfs_node" {
  count = var.use_vast_nfs ? 0 : 1
  name       = "slurm-nfs-node-${count.index}"
  type       = var.slurm_nfs_node_type
  ssh_key    = local.ssh_public_key
  location   = var.location
  project_id = var.project_id
  image      = "ubuntu24.04:latest"
  disks = [{ 
      id = crusoe_storage_disk.slurm_nfs_home[0].id
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
  disks = var.use_vast_nfs ? [
  {
    id              = crusoe_storage_disk.slurm_nfs_home_disk[0].id
    mode            = "read-write"
    attachment_type = "data"
  },
  {
    id              = coalesce(
      var.pre_existing_slurm_data_disk_id,
      try(crusoe_storage_disk.slurm_data_disk[0].id, null)
    )
    mode            = "read-write"
    attachment_type = "data"
  }
  ] : [
  for v in try(var.slurm_shared_volumes, []) : {
    id              = v.id
    mode            = v.mode
    attachment_type = "data"
  }]
}

resource "local_file" "node_hostfile" {
  count = var.enable_imex_support ? 1 : 0
  content = templatefile("${path.module}/nodes.tpl", {
    ips = crusoe_compute_instance.slurm_compute_node[*].network_interfaces[0].private_ipv4.address
    
  })
  filename = "${path.module}/imex_nodes.txt"
}

output "slurm_compute_nodes_addr" {
  description = "Compute node(s)"
  value = crusoe_compute_instance.slurm_compute_node[*].network_interfaces[0].public_ipv4.address
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
    use_vast_nfs = var.use_vast_nfs
    vastnfs_version = var.vastnfs_version
    slurm_data_disk_id = var.pre_existing_slurm_data_disk_id != null ? var.pre_existing_slurm_data_disk_id : length(crusoe_storage_disk.slurm_data_disk) > 0 ? crusoe_storage_disk.slurm_data_disk[0].id : null
    slurm_nfs_home_disk_id = try(crusoe_storage_disk.slurm_nfs_home_disk[0].id, null)
    slurmctld_disk_id = try(crusoe_storage_disk.slurmctld_disk[0].id, null)
    slurm_data_disk_mount_path = var.slurm_data_disk_mount_path
    use_imex = var.enable_imex_support
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
