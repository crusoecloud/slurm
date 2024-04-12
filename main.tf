terraform {
  required_providers {
    crusoe = {
      source  = "registry.terraform.io/crusoecloud/crusoe"
      version = "0.5.10"
    }
  }
}

locals {
  ssh_public_key = file("~/.ssh/id_ed25519.pub")
  location = "us-southcentral1-a"
  project_id = "198f5277-26f7-48bf-b97e-8b9b91d03b00"
  ib_partition_id = "c42dbe62-31fd-476b-bf07-d948bb303ec6"
}

resource "crusoe_compute_instance" "slurm_head_node" {
  count      = 2
  name       = "slurm-head-node-${count.index}"
  type       = "c1a.8x"
  ssh_key    = local.ssh_public_key
  location   = local.location
  project_id = local.project_id
  image      = "ubuntu22.04:latest"
}

resource "crusoe_compute_instance" "slurm_login_node" {
  count      = 1
  name       = "slurm-login-node-${count.index}"
  type       = "c1a.8x"
  ssh_key    = local.ssh_public_key
  location   = local.location
  project_id = local.project_id
  image      = "ubuntu22.04:latest"
}

resource "crusoe_compute_instance" "slurm_compute_node" {
  count    = 8
  name     = "slurm-compute-node-${count.index}"
  type     = "h100-80gb-sxm-ib.8x"
  ssh_key  = local.ssh_public_key
  location = local.location
  project_id = local.project_id
  image    = "ubuntu22.04-nvidia-sxm-docker:latest"
  host_channel_adapters = [{
    ib_partition_id = local.ib_partition_id
  }]
}

resource "local_file" "ansible_inventory" {
  content = templatefile("inventory.tmpl",
    {
      slurm_head_nodes = crusoe_compute_instance.slurm_head_node.*,
      slurm_login_nodes = crusoe_compute_instance.slurm_login_node.*,
      slurm_compute_nodes = crusoe_compute_instance.slurm_compute_node.*
    }
  )
  filename = "ansible/inventory/hosts"

  provisioner "local-exec" {
    command = "ansible-playbook -i ansible/inventory/hosts ansible/slurm.yml -f 32"
  }
}
