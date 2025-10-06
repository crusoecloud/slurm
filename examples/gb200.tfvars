# common configuration
location = "eu-iceland1-a"
project_id = "0b823dae-dc42-4ce0-8927-f951c4867932"
ssh_public_key_path = "~/.ssh/id_rsa.pub"
vpc_subnet_id = "c95a0075-d854-4982-9846-c1373d2e7e74"
slurm_compute_node_ib_partition_id = "c9e93066-a1b2-4e8b-b40f-5f2c13c92cee"
slurm_head_node_count = 1
slurm_login_node_count = 1

# slurm-compute-node configuration
slurm_compute_node_type = "gb200-186gb-nvl-ib.4x"
slurm_compute_node_count = 16

# observability
enable_observability = false
grafana_admin_password = "admin123"

# Shared disks using VAST NFS
use_vast_nfs = false

# VAST NFS disk configuration
slurm_shared_disk_nfs_home_size = "10TiB"
slurm_data_disk_size = "10TiB"
slurm_data_disk_mount_path = "/data"

# Use pre-existing Slurm VAST data disk with VAST NFS. This will be attached to the login and compute nodes
# pre_existing_slurm_data_disk_id = "40332855-f6ad-4611-a61e-7772a41795ea"

# Additionl shared disks to attach to compute VMs
# slurm_shared_volumes = [{
#     id          = "40332855-f6ad-4611-a61e-7772a41795ea"
#     name        = "shared-disk-test"
#     mount_point = "/data"
#     mode        = "read-write"
#   }]

# slurm users configuration
slurm_users = [{
  name = "user1"
  uid = 1001
  ssh_pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAni1VhZrF7aTOEN43cSXEiTjp7oXUKXijp1hv9Pu0nV chinmaybaikar"
  },{
  name = "user2"
  uid = 1002
  ssh_pubkey = "ssh-rsa ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB/YitvZCS3TwDzLIBscnWMwPFq04XK9JjnCK1Urv//0"
  }
]

#GB200
enable_imex_support = true