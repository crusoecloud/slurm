# common configuration
location = "eu-iceland1-a"
project_id = "ad337f40-ac0f-4165-be89-d4e0d03c699f"
ssh_public_key_path = "~/.ssh/id_ed25519.pub"
vpc_subnet_id = "2ad77302-db87-464f-ac42-a8679bf76372"

# head node
slurm_head_node_count = 1
slurm_head_node_type = "c1a.4x"

# login node
slurm_login_node_count = 1
slurm_login_node_type = "c1a.4x"

# slurm-compute-node configuration
slurm_compute_node_type = "h200-141gb-sxm-ib.8x"
slurm_compute_node_ib_partition_id = "280386dc-d25f-4188-8de1-53d0141ea09e"
slurm_compute_node_count = 1

slurm_shared_volumes = [{
  id = "195c5a4f-44e0-4902-b0ca-5dca7bbed3a8"
  name = "slurm-vast-icat"
  mode = "read-write"
  mount_point = "/data"
}]

# slurm users configuration
slurm_users = [{
  name = "user1"
  uid = 1001
  ssh_pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPLZWkpxGIeCLrEsZQVbbeoQdT7fZuW84eTjRMy0zgPr yjeong@crusoe.ai"
}]