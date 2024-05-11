# common configuration
location = "us-east1-a"
project_id = "198e7c51-9ed2-41db-b3c8-baeee40d7592"
ssh_public_key_path = "~/.ssh/id_ed25519.pub"

# slurm-compute-node configuration
slurm_compute_node_type = "h100-80gb-sxm-ib.8x"
slurm_compute_node_ib_network_id = "474dbfe2-ffb3-44ce-87a4-cea659fddea3"
slurm_compute_node_count = 4
