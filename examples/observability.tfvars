# common configuration
location = "us-northcentral1-a"
project_id = "4ba4b775-28a3-4481-bb93-9037a23fb8e0"
ssh_public_key_path = "~/.ssh/id_ed25519.pub"
vpc_subnet_id = "5963d82e-59cd-43ee-8b15-3e7b6fb9839b"

# head node
slurm_head_node_count = 1
slurm_head_node_type = "c1a.8x"

# login node
slurm_login_node_count = 1
slurm_login_node_type = "c1a.8x"

# nfs node
slurm_nfs_node_type = "s1a.20x"
slurm_nfs_home_size = "1024GiB"

# slurm-compute-node configuration
slurm_compute_node_type = "a40.1x"
slurm_compute_node_count = 1

# slurm users configuration
slurm_users = [{
  name = "user1"
  uid = 1001
  ssh_pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDQD5doToJjyyq0BH8TDlHZqqVy+kZpuGgJP5gbDanpF piotr.rojek (at) deepsense.ai"
}]

# observability
enable_observability = true
grafana_admin_password = "admin123"