variable "k3d_cluster_name" {
  description = "Name of the k3d cluster"
  type        = string
  default     = "infra-takehome"
}

variable "k3s_version" {
  description = "K3s image tag to use for cluster nodes"
  type        = string
  default     = "v1.35.2-k3s1"
}

variable "postgres_password" {
  description = "Password for the PostgreSQL instance"
  type        = string
  default     = "postgres"
  sensitive   = true
}

variable "postgres_port" {
  description = "Host port to expose PostgreSQL on"
  type        = number
  default     = 5432
}

variable "db_name" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_superuser" {
  type = string
}

variable "db_superuser_password" {
  type      = string
  sensitive = true
}