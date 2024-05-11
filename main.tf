terraform {
  required_providers {
    crusoe = {
      source  = "registry.terraform.io/crusoecloud/crusoe"
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
  image      = "ubuntu22.04:latest"
}

resource "crusoe_compute_instance" "slurm_login_node" {
  count      = var.slurm_login_node_count
  name       = "slurm-login-node-${count.index}"
  type       = "c1a.16x"
  ssh_key    = local.ssh_public_key
  location   = var.location
  project_id = var.project_id
  image      = "ubuntu22.04:latest"
}

resource "crusoe_storage_disk" "slurm_nfs_home" {
  name = "slurm-nfs-home"
  size = "10240GiB"
  location = var.location
  project_id = var.project_id
}

resource "crusoe_compute_instance" "slurm_nfs_node" {
  count      = 1
  name       = "slurm-nfs-node-${count.index}"
  type       = "s1a.80x"
  ssh_key    = local.ssh_public_key
  location   = var.location
  project_id = var.project_id
  image      = "ubuntu22.04:latest"
  disks = [{ 
      id = crusoe_storage_disk.slurm_nfs_home.id
      mode = "read-write"
      attachment_type = "data"
  }]
}

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
  image    = "ubuntu22.04-nvidia-sxm-docker:latest"
  host_channel_adapters = var.slurm_compute_node_ib_network_id != null ? [{
    ib_partition_id = crusoe_ib_partition.slurm_ib_partition[0].id
  }]: null
}

resource "local_file" "ansible_inventory" {
  content = templatefile("inventory.tmpl",
    {
      slurm_head_nodes = crusoe_compute_instance.slurm_head_node.*,
      slurm_login_nodes = crusoe_compute_instance.slurm_login_node.*,
      slurm_nfs_nodes = crusoe_compute_instance.slurm_nfs_node.*,
      slurm_compute_nodes = crusoe_compute_instance.slurm_compute_node.*
    }
  )
  filename = "ansible/inventory/hosts"
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
    command = "ansible-playbook -i ansible/inventory/hosts ansible/slurm.yml -f 128"
  }

  depends_on = [local_file.ansible_inventory]
}
