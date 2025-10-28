# common configuration
location = "us-east1-a"
project_id = "198e7c51-9ed2-41db-b3c8-baeee40d7592"
ssh_public_key_path = "~/.ssh/id_ed25519.pub"
vpc_subnet_id = "80cf6356-da22-42c8-8925-d5fb1e3e55ad"

# slurm-compute-node configuration
slurm_compute_node_type = "h100-80gb-sxm-ib.8x"
slurm_compute_node_ib_partition_id = "474dbfe2-ffb3-44ce-87a4-cea659fddea3"
slurm_compute_node_count = 4

# slurm users configuration
slurm_users = [
    {
      name = "crusoe-admin"
      uid = 75123
      ssh_pubkey = "from=\"35.232.249.237\" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM//Zq9sHLhFsP1gPZ+NuiUh8/4Vh5SVtISEKtz+c4el admin@managed-slurm-bastion-prod"
    }
]
