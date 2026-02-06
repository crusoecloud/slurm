terraform {
  required_providers {
    crusoe = {
      source = "registry.terraform.io/crusoecloud/crusoe"
    }
    ansible = {
      version = "~> 1.3.0"
      source  = "ansible/ansible"
    }
  }
}

locals {
  ssh_public_key = file(var.ssh_public_key_path)

  compute_instances = flatten([
    for group in var.partitions : [
      for i in range(group.count) : {
        key        = "${group.name}-compute-node-${format("%03d", i)}"
        index      = i
        partition_name  = group.name
        type = group.type
        ib_partition_id = group.ib_partition_id
        image = group.image
        custom_image = group.custom_image
        reservation_id = group.reservation_id
        extra_args = group.extra_args
      }
    ]
  ])
}

resource "crusoe_storage_disk" "slurm_data_disk" {
  count      = var.pre_existing_slurm_data_disk_id == null ? 1 : 0
  name       = "slurm-data-disk"
  size       = var.slurm_data_disk_size
  location   = var.location
  project_id = var.project_id
  type       = "shared-volume"
}

resource "crusoe_storage_disk" "slurm_nfs_home_disk" {
  count      = 1
  name       = "slurm-nfs-home-disk"
  size       = var.slurm_shared_disk_nfs_home_size
  location   = var.location
  project_id = var.project_id
  type       = "shared-volume"
}

resource "crusoe_storage_disk" "slurmctld_disk" {
  count      = 1
  name       = "slurmctld-disk"
  size       = var.slurmctld_disk_size
  location   = var.location
  project_id = var.project_id
  type       = "shared-volume"
}

resource "crusoe_compute_instance" "slurm_compute_node" {
  for_each = { for inst in local.compute_instances : inst.key => inst }
  name           = each.value.key
  type           = each.value.type
  ssh_key        = local.ssh_public_key
  location       = var.location
  project_id     = var.project_id
  image          = each.value.custom_image != null ? null : each.value.image
  custom_image   = each.value.custom_image != null ? each.value.custom_image : null
  reservation_id = each.value.reservation_id
  host_channel_adapters = each.value.ib_partition_id != null ? [{
    ib_partition_id = each.value.ib_partition_id
  }] : null
  network_interfaces = [{
    subnet = var.vpc_subnet_id,
    public_ipv4 = {
      type = "static"
    }
  }]
  disks = [
    {
      id              = crusoe_storage_disk.slurm_nfs_home_disk[0].id
      mode            = "read-write"
      attachment_type = "data"
    },
    {
      id = coalesce(
        var.pre_existing_slurm_data_disk_id,
        try(crusoe_storage_disk.slurm_data_disk[0].id, null)
      )
      mode            = "read-write"
      attachment_type = "data"
  }]
}


resource "crusoe_compute_instance" "slurm_head_node" {
  count          = var.slurm_head_node_count
  name           = "slurm-head-node-${count.index}"
  type           = var.slurm_head_node_type
  ssh_key        = local.ssh_public_key
  location       = var.location
  project_id     = var.project_id
  image          = var.head_node_custom_image_name != null ? null : "ubuntu22.04-nvidia-slurm:latest"
  custom_image   = var.head_node_custom_image_name != null ? var.head_node_custom_image_name : null
  reservation_id = var.slurm_head_node_reservation_id
  host_channel_adapters = var.slurm_head_node_ib_partition_id != null ? [{
    ib_partition_id = var.slurm_head_node_ib_partition_id
  }] : null
  network_interfaces = [{
    subnet = var.vpc_subnet_id,
    public_ipv4 = {
      type = "static"
    }
  }]
  disks = [{
    id              = crusoe_storage_disk.slurmctld_disk[0].id
    mode            = "read-write"
    attachment_type = "data"
    }, {
    id              = crusoe_storage_disk.slurm_nfs_home_disk[0].id
    mode            = "read-write"
    attachment_type = "data"
  }]
}

resource "crusoe_compute_instance" "slurm_login_node" {
  count          = var.slurm_login_node_count
  name           = "slurm-login-node-${count.index}"
  type           = var.slurm_login_node_type
  ssh_key        = local.ssh_public_key
  location       = var.location
  project_id     = var.project_id
  image          = var.login_node_custom_image_name != null ? null : "ubuntu22.04-nvidia-slurm:latest"
  custom_image   = var.login_node_custom_image_name != null ? var.login_node_custom_image_name : null
  reservation_id = var.slurm_login_node_reservation_id
  host_channel_adapters = var.slurm_login_node_ib_partition_id != null ? [{
    ib_partition_id = var.slurm_login_node_ib_partition_id
  }] : null
  network_interfaces = [{
    subnet = var.vpc_subnet_id,
    public_ipv4 = {
      type = "static"
    }
  }]
  disks = [{
    id              = crusoe_storage_disk.slurm_nfs_home_disk[0].id
    mode            = "read-write"
    attachment_type = "data"
    },
    {
      id = coalesce(
        var.pre_existing_slurm_data_disk_id,
        try(crusoe_storage_disk.slurm_data_disk[0].id, null)
      )
      mode            = "read-write"
      attachment_type = "data"
  }]
}

resource "crusoe_vpc_firewall_rule" "allow_grafana_access" {
  count             = var.enable_observability ? 1 : 0
  action            = "allow"
  destination       = crusoe_compute_instance.slurm_head_node[0].network_interfaces[0].private_ipv4.address
  destination_ports = "3000"
  direction         = "ingress"
  name              = "grafana-slurm-access"
  network           = crusoe_compute_instance.slurm_head_node[0].network_interfaces[0].network
  protocols         = "tcp"
  source            = "0.0.0.0/0"
  source_ports      = "1-65535"
}

# IMEX nodes files - one for each partition with IMEX enabled
resource "local_file" "partition_node_hostfile" {
  for_each = {
    for p in var.partitions : p.name => p if p.imex_support
  }

  content = templatefile("${path.module}/nodes.tpl", {
    ips = [
      for key, inst in crusoe_compute_instance.slurm_compute_node :
      inst.network_interfaces[0].private_ipv4.address
      if startswith(key, "${each.key}-compute-node-")
    ]
  })

  filename = "${path.module}/imex_nodes_${each.key}.txt"
}

resource "ansible_host" "slurm_head_node_host" {
  for_each = {
    for n in crusoe_compute_instance.slurm_head_node : n.name => n
  }

  name = each.value.name
  groups = [
    "slurm_head_nodes",
    replace(split(".", each.value.type)[0], "-", "_"),
  ]
  variables = {
    ansible_host  = each.value.network_interfaces[0].public_ipv4.address
    instance_type = each.value.type
    location      = each.value.location
  }
}

resource "ansible_host" "slurm_login_node_host" {
  for_each = {
    for n in crusoe_compute_instance.slurm_login_node : n.name => n
  }
  name = each.value.name
  groups = [
    "slurm_compute_nodes",
    replace(split(".", each.value.type)[0], "-", "_"),
  ]
  variables = {
    ansible_host   = each.value.network_interfaces[0].public_ipv4.address
    slurm_features = jsonencode(["login"])
    instance_type  = each.value.type
    location       = each.value.location
  }
}

# Compute nodes - ansible
resource "ansible_host" "slurm_compute_node_host" {
  for_each = {
    for n in crusoe_compute_instance.slurm_compute_node : n.name => n
  }
  name = each.value.name
  groups = [
    "slurm_compute_nodes",
    format("%s%s",split("-", each.value.name)[0],"_compute_nodes"),
    replace(split(".", each.value.type)[0], "-", "_"),
  ]
  variables = {
    ansible_host   = each.value.network_interfaces[0].public_ipv4.address
    #slurm_features contains a 1 element list consisting of the partition name
    slurm_features = jsonencode([split("-", each.value.name)[0]])
    instance_type  = each.value.type
    location       = each.value.location
  }
}

resource "ansible_group" "all" {
  name = "all"
  variables = {
    slurm_users                = jsonencode(var.slurm_users)
    partitions                 = jsonencode(var.partitions)
    enable_observability       = var.enable_observability
    grafana_admin_password     = var.grafana_admin_password
    vastnfs_version            = var.vastnfs_version
    slurm_data_disk_id         = var.pre_existing_slurm_data_disk_id != null ? var.pre_existing_slurm_data_disk_id : length(crusoe_storage_disk.slurm_data_disk) > 0 ? crusoe_storage_disk.slurm_data_disk[0].id : null
    slurm_nfs_home_disk_id     = try(crusoe_storage_disk.slurm_nfs_home_disk[0].id, null)
    slurmctld_disk_id          = try(crusoe_storage_disk.slurmctld_disk[0].id, null)
    slurm_data_disk_mount_path = var.slurm_data_disk_mount_path
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
    ansible_host.slurm_head_node_host,
    ansible_host.slurm_login_node_host,
    ansible_host.slurm_compute_node_host,
    ansible_group.all
  ]
}

output "slurm_head_nodes_addr" {
  description = "Head node(s)"
  value       = crusoe_compute_instance.slurm_head_node[*].network_interfaces[0].public_ipv4.address
}

output "slurm_login_nodes_addr" {
  description = "Login node(s)"
  value       = crusoe_compute_instance.slurm_login_node[*].network_interfaces[0].public_ipv4.address
}

output "slurm_compute_nodes_addr" {
  description = "Compute node(s)"
  value       = [for instance in crusoe_compute_instance.slurm_compute_node : instance.network_interfaces[0].public_ipv4.address]
}
