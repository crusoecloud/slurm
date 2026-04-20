variable "ssh_public_key_path" {
  description = "The ssh public key authorized to login to the cluster."
  type        = string
}

variable "location" {
  description = "The location in which to create the cluster."
  type        = string
}

variable "project_id" {
  description = "The project in which to create the cluster."
  type        = string
}

variable "vpc_subnet_id" {
  description = "The vpc subnet id."
  type        = string
  default     = null
}

variable "slurm_head_node_count" {
  description = "The number of slurm head nodes."
  type        = number
  default     = 2
}

variable "slurm_head_node_type" {
  description = "The slurm head node instance type."
  type        = string
  default     = "c1a.16x"
}

# This is only required when using an infiniband enabled instance type for the head nodes.
variable "slurm_head_node_ib_partition_id" {
  description = "The ib partition in which to create the head node."
  type        = string
  default     = null
}

variable "slurm_head_node_reservation_id" {
  description = "The slurm head node reservation id"
  type        = string
  default     = null
}

variable "slurm_login_node_count" {
  description = "The number of slurm login nodes."
  type        = number
  default     = 2
}

variable "slurm_login_node_type" {
  description = "The slurm login node instance type."
  type        = string
  default     = "c1a.16x"
}

variable "slurm_login_node_reservation_id" {
  description = "The slurm login node reservation id"
  type        = string
  default     = null
}

# This is only required when using an infiniband enabled instance type for the login nodes.
variable "slurm_login_node_ib_partition_id" {
  description = "The ib partition in which to create the login node."
  type        = string
  default     = null
}

variable "partitions" {
  description = "Partition configuration"
  type = list(object({
    name       = string
    count      = number
    type       = string
    imex_support = bool
    ib_partition_id = string
    image = string
    custom_image = string
    reservation_id = string
    extra_args = map(string)
  }))
  default = [
    {
      name = "partition1"
      count = 0
      type = "b200-180gb-sxm-ib.8x"
      imex_support = false
      ib_partition_id = null
      image = "ubuntu22.04-nvidia-slurm:latest"
      custom_image = null
      reservation_id = null
      extra_args = {
        "Default" = "YES",
        "MaxTime" = "INFINITE",
        "State"   = "UP",
      }
    }
  ]
}

variable "slurm_users" {
  description = "Additional users"
  type = list(object({
    name       = string
    uid        = number
    ssh_pubkey = string
    is_sudoer  = optional(bool, false)
  }))
  default = []
}

variable "enable_observability" {
  description = "Enable observability stack (Prometheus, Grafana, GPU monitoring)"
  type        = bool
  default     = false
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana (if observability is enabled)"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "slurm_data_disk_size" {
  description = "The slurm data disk size."
  type        = string
  default     = "1024000GiB"
}

variable "slurm_home_disk_size" {
  description = "The slurm home directory size."
  type        = string
  default     = "20480GiB"
}

variable "slurmctld_disk_size" {
  description = "The slurmctld disk size. This is required to persist slurm cluster state"
  type        = string
  default     = "1024GiB"
}

variable "pre_existing_slurm_home_disk_id" {
  description = "Use a pre-existing Slurm VAST data disk"
  type        = string
  default     = null
}

variable "pre_existing_slurm_data_disk_id" {
  description = "Use a pre-existing Slurm VAST data disk"
  type        = string
  default     = null
}

variable "slurm_data_disk_mount_path" {
  description = "This is the training/checkpoint disk mount path"
  type        = string
  default     = "/data"
}

variable "vastnfs_version" {
  description = "The VAST NFS driver version"
  type        = string
  default     = "4.0.35"
}

variable "vast_nfs_server_host" {
  description = "The VAST NFS server hostname or IP address used as the NFS mount source"
  type        = string
  default     = "172.27.255.2"
}

variable "vast_nfs_remoteports" {
  description = "The VAST NFS remoteports range used in NFS mount options"
  type        = string
  default     = "172.27.255.2-172.27.255.17"
}

variable "head_node_custom_image_name" {
  description = "name:tag of your Custom Image for Head Nodes"
  type        = string
  default     = null
}

variable "login_node_custom_image_name" {
  description = "name:tag of your Custom Image for Login Nodes"
  type        = string
  default     = null
}
