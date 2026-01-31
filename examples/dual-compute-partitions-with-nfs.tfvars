# common configuration
location ="eu-iceland1-a"
project_id = "6b60dd75-ea5f-4fae-81b8-12bbe3049e2a"
ssh_public_key_path = "~/.ssh/id_ed25519.pub"
vpc_subnet_id = "c200ac3f-acf0-4343-9da6-9702bd33d192"


# pt1 slurm-compute-node configuration
partition1_name = "gb200"
partition1_compute_node_custom_image_name = "gb200-slurm:latest"
partition1_compute_node_type = "gb200-186gb-nvl-ib.4x"
partition1_compute_node_count = 4
partition1_compute_node_ib_partition_id = "312d830d-b328-44bf-8a89-9a3cf986d571"
partition1_enable_imex_support = true

# pt2 slurm-compute-node configuration
partition2_name = "b200"
partition2_compute_node_custom_image_name = "b200-slurm:latest"
partition2_compute_node_type = "b200-180gb-sxm-ib.8x"
partition2_compute_node_count = 2
partition2_compute_node_ib_partition_id = "2a5d3404-595c-4fca-829e-e2324f27070c"

# head node
head_node_custom_image_name = "head-slurm:latest"
slurm_head_node_count = 1
slurm_head_node_type = "c1a.4x"

# login node
login_node_custom_image_name = "head-slurm:latest"
slurm_login_node_count = 1
slurm_login_node_type = "c1a.4x"

# observability
enable_observability = true
grafana_admin_password = "Crus0eM3tr1c5!"

# Shared disks using VAST NFS
#use_vast_nfs = true
vastnfs_version = "4.0.35"

# VAST NFS disk configuration
slurm_shared_disk_nfs_home_size = "1TiB"

#slurm_data_disk_size = "2TiB"
slurm_data_disk_mount_path = "/data"
# Use pre-existing Slurm VAST data disk
pre_existing_slurm_data_disk_id = "bba2ce8a-1d6c-429d-81aa-8dc55d7100f0"

partitions = [
    {
      name = "gb200"
      extra_args = {
        "Default" = "YES",
        "MaxTime" = "INFINITE",
        "State"   = "UP",
      }
    },
    {
      name = "b200"
      extra_args = {
        "MaxTime" = "INFINITE",
        "State"   = "UP",
      }
    }]
