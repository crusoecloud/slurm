# common configuration
location = "eu-iceland1-a"
project_id = "9c75db17-61c6-44e0-98e9-53a5689d9ff7"
ssh_public_key_path = "~/.ssh/crusoe-dx-lab.pub"
vpc_subnet_id = "7fea2fae-c316-4f48-8bf7-6627f3f6dd7e"
slurm_compute_node_ib_partition_id = "56763150-da19-4f69-9b9e-bc5a169ae6b7"

# slurm-compute-node configuration
slurm_compute_node_type = "h200-141gb-sxm-ib.8x"
slurm_compute_node_count = 3

# observability
enable_observability = false
grafana_admin_password = "admin123"

# Shared disks using VAST NFS
use_vast_nfs = true
vastnfs_version = "4.0.35"

# VAST NFS disk configuration
slurm_shared_disk_nfs_home_size = "20TiB"
slurm_data_disk_size = "1000TiB"
slurm_data_disk_mount_path = "/data"

# Use pre-existing Slurm VAST data disk
# pre_existing_slurm_data_disk_id = "<Disk_ID>"

# slurm users configuration
slurm_users = [{
  name = "user1"
  uid = 1001
  ssh_pubkey = "<public-key>"
  },{
  name = "user2"
  uid = 1002
  ssh_pubkey = "<public-key>"
  }]