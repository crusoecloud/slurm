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
}

variable "slurm_head_node_count" {
  description = "The number of slurm head nodes."
  type        = number
  default     = 2
}

variable "slurm_login_node_count" {
  description = "The number of slurm login nodes."
  type        = number
  default     = 2
}

variable "slurm_nfs_node_type" {
  description = "The slurm nfs node instance type."
  type        = string
  default     = "s1a.80x"
}

variable "slurm_nfs_home_size" {
  description = "The slurm nfs host size."
  type        = string
  default     = "10240GiB"
}

variable "slurm_compute_node_type" {
  description = "The slurm compute node instance type."
  type        = string
}

variable "slurm_compute_node_count" {
  description = "The number of slurm compute nodes."
  type        = number
}

variable "slurm_compute_node_ib_network_id" {
  description = "The ib network in which to create the cluster."
  type        = string
  default     = null
}

variable "slurm_users" {
  description = "Additional users"
  type = list(object({
    name = string
    uid = number
    ssh_pubkey = string
  }))
  default     = []
}
