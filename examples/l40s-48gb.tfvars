# common configuration
location = "us-east1-a"
project_id = "198e7c51-9ed2-41db-b3c8-baeee40d7592"
ssh_public_key_path = "~/.ssh/id_ed25519.pub"

# slurm-compute-node configuration
slurm_compute_node_type = "l40s-48gb.10x"
slurm_compute_node_count = 4

# slurm users configuration
slurm_users = [{
  name = "user1"
  uid = 1001
  ssh_pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIjPRr0iVR4mgzJy0ehnM5hWX4O86hM1bVTgdi5g3nkZ user1@crusoe.ai"
}, {
  name = "user2"
  uid = 1002
  ssh_pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIjPRr0iVR4mgzJy0ehnM5hWX4O86hM1bVTgdi5g3nkZ user2@crusoe.ai"
}, {
  name = "user3"
  uid = 1003
  ssh_pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIjPRr0iVR4mgzJy0ehnM5hWX4O86hM1bVTgdi5g3nkZ user3@crusoe.ai"
}]
