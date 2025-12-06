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

variable "slurm_compute_node_type" {
  description = "The slurm compute node instance type."
  type        = string
}

variable "slurm_compute_node_count" {
  description = "The number of slurm compute nodes."
  type        = number
}

# This is only required when using an infiniband enabled instance type for the compute nodes.
variable "slurm_compute_node_ib_partition_id" {
  description = "The ib partition in which to create the compute nodes."
  type        = string
  default     = null
}

variable "slurm_compute_node_reservation_id" {
  description = "The slurm compute node reservation id"
  type        = string
  default     = null
}

variable "slurm_users" {
  description = "Additional users"
  type        = list(object({
    name      = string
    uid       = number
    ssh_pubkey = string
  }))
  default     = []
}

variable "partitions" {
  description = "Partition configuration"
  type = list(object({
    name = string
    extra_args = map(string)
  }))
  default = [
    {
      name = "batch"
      extra_args = {
        "Default" = "YES",
        "MaxTime" = "INFINITE",
        "State" = "UP",
      }
    }, {
      name = "login"
      extra_args = {
        "State":  "INACTIVE",
				"Hidden": "YES",
      }
    }
  ]
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

variable "slurm_shared_disk_nfs_home_size" {
  description = "The slurm nfs home directory size."
  type        = string
  default     = "20480GiB"
}

variable "slurmctld_disk_size" {
  description = "The slurmctld disk size. This is required to persist slurm cluster state"
  type        = string
  default     = "1024GiB"
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

variable "vastnfs_version"{
  description = "The VAST NFS driver version"
  type        = string
  default     = "4.0.35"
}

variable "enable_imex_support" {
  description = "If true, a file with the list of all compute node IPs will be created for use with imex"
  type        = bool
  default     = false
}

variable "compute_node_custom_image_name" {
  description = "name:tag of your Custom Image for Compute Nodes"
  type        = string
  default     = null
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