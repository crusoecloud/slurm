# common configuration
location = ""
project_id = ""
ssh_public_key_path = ""
vpc_subnet_id = ""

slurm_head_node_count = 1
slurm_login_node_count = 1
slurm_login_node_type = "c1a.32x"
slurm_head_node_type = "c1a.32x"

# slurm-compute-node configuration
partitions = [
    {
      name = ""
      count = 64
      type = ""
      imex_support = true
      image = null
      ib_partition_id = ""
      custom_image = ""
      reservation_id = null
      extra_args = {
        "Default" = "YES",
        "MaxTime" = "INFINITE",
        "State"   = "UP",
      }
    },
  ]

# observability
enable_observability = true
grafana_admin_password = "admin123"

# VAST NFS disk configuration
slurm_home_disk_size = "300TiB"
slurm_data_disk_size = "500TiB"
slurm_data_disk_mount_path = "/data"
vast_nfs_server_host = "nfs.crusoecloudcompute.com"
vast_nfs_remoteports = "dns"

# Slurm accounting
slurm_account_name      = "crusoe"
slurmdbd_mysql_password = "exemplarPA$$w0rd"

# Use pre-existing Slurm VAST data disk with VAST NFS. This will be attached to the login and compute nodes
# pre_existing_slurm_data_disk_id = "eda10ac4-0b96-49e0-b709-cfbe443fd66d"

# slurm users configuration
slurm_users = [{
  name      = "exemplar"
  uid       = 1001
  ssh_pubkey = ""
  is_sudoer = true
  },
]