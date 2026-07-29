# common configuration
location ="eu-iceland1-a"
project_id = "<your project ID>"
ssh_public_key_path = "~/.ssh/id_ed25519.pub"
vpc_subnet_id = "<your subnet ID>"

# For 'image' and 'custom_image' values, for any node type:
# If using an official Crusoe image: set its name and tag in 'image' and set 'custom_image' to null
# If using a custom image: set its name and tag in 'custom_image' and set 'image' to null

# head node
# head_node_custom_image_name = "<custom image name and tag>"
slurm_head_node_count = 1
slurm_head_node_type = "c1a.4x"

# login node
# login_node_custom_image_name = "<custom image name and tag>"
slurm_login_node_count = 1
slurm_login_node_type = "c1a.16x"

# observability
enable_observability = true
grafana_admin_password = "<secure password for your Grafana dashboard>"

# Shared disks using VAST NFS
vastnfs_version = "4.0.35"

slurm_home_disk_size = "10TiB"
# Or use a pre-existing volume as the /home  disk
# pre_existing_slurm_home_disk_id = "<volume id of existing home disk>"

slurm_data_disk_size = "20TiB"
# Or use a pre-existing volume as the data disk
# pre_existing_slurm_data_disk_id = "<your existing data volume ID>"
slurm_data_disk_mount_path = "/data"

#create a partition object in this list for each compute type in the cluster
#imex support only true for GB200
partitions = [
    {
      name = "gb200"
      count = 4
      type = "gb200-186gb-nvl-ib.4x"
      imex_support = true
      ib_partition_id = "<your GB200 IB partition ID"
      image = null
      custom_image = "<your custom image name and tag>"
      reservation_id = null
      extra_args = {
        "Default" = "YES",
        "MaxTime" = "INFINITE",
        "State"   = "UP",
      }
    },
    {
      name = "cpu"
      count = 2
      type = "c1a.32x"
      imex_support = false
      ib_partition_id = null
      image = null
      custom_image = "<your custom image name and tag>"
      reservation_id = null
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
