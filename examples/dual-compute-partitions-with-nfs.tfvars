# common configuration
location ="eu-iceland1-a"
project_id = "<your project ID>"
ssh_public_key_path = "~/.ssh/id_ed25519.pub"
vpc_subnet_id = "<your subnet ID>"

# head node
head_node_custom_image_name = "head-slurm:latest"
slurm_head_node_count = 1
slurm_head_node_type = "c1a.4x"

# login node
login_node_custom_image_name = "head-slurm:latest"
slurm_login_node_count = 1
slurm_login_node_type = "c1a.4x"

# observability
enable_observability = false
grafana_admin_password = "<some secure password for your Grafana dashboard>"

# Shared disks using VAST NFS
#use_vast_nfs = true
vastnfs_version = "4.0.35"

# VAST NFS disk configuration
slurm_shared_disk_nfs_home_size = "1TiB"

#slurm_data_disk_size = "2TiB"
slurm_data_disk_mount_path = "/data"
# Use pre-existing Slurm VAST data disk
pre_existing_slurm_data_disk_id = "<your existing data volume ID>"

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
      custom_image = "head-slurm:latest"
      reservation_id = null
      extra_args = {
        "MaxTime" = "INFINITE",
        "State"   = "UP",
      }
    }
  ]