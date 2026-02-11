# common configuration
location ="eu-iceland1-a"
project_id = "6b60dd75-ea5f-4faefggfg49e2a"
ssh_public_key_path = "~/.ssh/id_ed25519.pub"
vpc_subnet_id = "c200ac3f-acf0-4343-9da6fdfdf3d192"

# head node
slurm_head_node_count = 1
slurm_head_node_type = "c1a.4x"


# login node
slurm_login_node_count = 2
slurm_login_node_type = "c1a.4x"

# observability
enable_observability = true
grafana_admin_password = "admin123"

# Shared disks using VAST NFS
vastnfs_version = "4.0.35"

# VAST Home disk configuration
pre_existing_slurm_home_disk_id = "ac3def90-4d98-4a78-9vcbvbvbbv"

# VAST data disk
slurm_data_disk_mount_path = "/data"
pre_existing_slurm_data_disk_id = "bba2ce8a-1d6c-429d-81aa-8dvvcvcvcv"

partitions = [
    {
      name = "cpua"
      count = 2
      type = "c1a.8x"
      imex_support = false
      ib_partition_id = null
      reservation_id = null
      image = "ubuntu22.04-nvidia-slurm:latest"
      custom_image = null
      extra_args = {
        "Default" = "YES",
        "MaxTime" = "INFINITE",
        "State"   = "UP",
      }
    },
    {
      name = "cpub"
      count = 2
      type = "c1a.8x"
      imex_support = false
      ib_partition_id = null
      reservation_id = null
      image = "ubuntu22.04-nvidia-slurm:latest"
      custom_image = null
      extra_args = {
        "MaxTime" = "INFINITE",
        "State"   = "UP",
      }
    }
  ]

# slurm users configuration
slurm_users = [{
  name = "user1"
  uid = 1001
  is_sudoer = true
  ssh_pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICK73FqSzvHb4OQctUAaaAbIfcBA9VwRBzacPeZKPnL9 ubuntu@jumphost"
  },{
  name = "user2"
  uid = 1002
  ssh_pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICK73FqSzvHb4OQctUAaaAbIfcBA9VwRBzacPeZKPnL9 ubuntu@jumphost"
  }
]
