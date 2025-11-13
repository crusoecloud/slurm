# common configuration
location = "us-east1-a"
project_id = "ad337f40-ac0f-4165-be89-d4e0d03c699f"
ssh_public_key_path = "~/.ssh/id_ed25519.pub"
vpc_subnet_id = "0538aecf-e3d7-484c-aa3f-bee399b344d8"

# slurm-compute-node configuration
slurm_compute_node_type = "h100-80gb-sxm-ib.8x"
slurm_compute_node_ib_partition_id = "686331f9-9368-4245-bf48-a359a8c0e476"
slurm_compute_node_count = 1

# slurm users configuration
slurm_users = [{
  name = "user1"
  uid = 1001
  ssh_pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPLZWkpxGIeCLrEsZQVbbeoQdT7fZuW84eTjRMy0zgPr yjeong@crusoe.ai"
}]

enable_custom_images = true
custom_image_name = "slurm-new:latest"