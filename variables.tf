variable "k8stoken" {
  default = ""
  description = "Overrides the auto-generated bootstrap token."
}

resource "random_string" "k8stoken_first_part" {
  length = 6
  upper = false
  special = false
}

resource "random_string" "k8stoken_second_part" {
  length = 16
  upper = false
  special = false
}

locals {
  k8stoken = "${var.k8stoken == "" ? "${random_string.k8stoken_first_part.result}.${random_string.k8stoken_second_part.result}" : "${var.k8stoken}"}"
}

variable "cluster_name" {
  default = "k8s"
  description = "Controls the naming of the AWS resources."
}

variable "access_key" {
  default = ""
}

variable "secret_key" {
  default = ""
}

variable "k8s_ssh_key" {}

variable "admin_cidr_blocks" {
  description = "A comma separated list of CIDR blocks to allow SSH connections from."
}

variable "region" {
  default = "us-east-1"
}

variable "az" {
  default = "a"
}

variable "kubernetes_version" {
  default = "1.13.4"
  description = "Which version of Kubernetes to install."
}

variable "master_instance_type" {
  default = "m1.small"
  description = "Which EC2 instance type to use for the master nodes."
}

variable "master_spot_price" {
  default = "0.01"
  description = "The maximum spot bid for the master node."
}

variable "worker_instance_type" {
  default = "m1.small"
  description = "Which EC2 instance type to use for the worker nodes."
}

variable "worker_spot_price" {
  default = "0.01"
  description = "The maximum spot bid for worker nodes."
}

variable "min_worker_count" {
  default = "1"
  description = "The minimum worker node count."
}

variable "max_worker_count" {
  default = "1"
  description = "The maximum worker node count."
}

variable "backup_enabled" {
  default = "1"
  description = "Whether or not the automatic S3 backup should be enabled. (1 for enabled, 0 for disabled)."
}

variable "backup_cron_expression" {
  default = "*/15 * * * *"
  description = "A cron expression to use for the automatic etcd backups."
}

variable "external_dns_enabled" {
  default = "1"
  description = "Whether or not to enable external-dns. (1 for enabled, 0 for disabled)."
}

variable "nginx_ingress_enabled" {
  default = "0"
  description = "Whether or not to enable nginx ingress. (1 for enabled, 0 for disabled)."
}

variable "nginx_ingress_domain" {
  default = ""
  description = "The DNS name to map to Nginx Ingress (using External DNS)."
}

variable "cert_manager_enabled" {
  default = "0"
  description = "Whether or not to enable the cert manager. (1 for enabled, 0 for disabled)."
}

variable "cert_manager_email" {
  default = ""
  description = "The email address to use for Let's Encrypt certificate requests."
}

variable "cluster_autoscaler_enabled" {
  default = "0"
  description = "Whether or not to enable the cluster autoscaler. (1 for enabled, 0 for disabled)."
}
