variable "domain" {
  type        = string
  description = "The top-level domain of prow service"
}

variable "github_appid" {
  type        = string
  description = "The id of Github APP"
}

variable "github_cert" {
  type        = string
  description = "The private key cert pem of Github APP"
}

variable "hmac_token" {
  type        = string
  description = "The hmac token of Github webhook secret"
}

variable "kube_client_certificate" {
  type        = string
  description = "The client certificate of Kubernetes cluster"
}

variable "kube_client_key" {
  type        = string
  description = "The client key of Kubernetes cluster"
}

variable "kube_cluster_ca_certificate" {
  type        = string
  description = "The cluster ca certificate of Kubernetes cluster"
}

variable "kube_host" {
  type        = string
  description = "The hostname of Kubernetes cluster"
}

variable "minio_root_password" {
  type        = string
  description = "The password of minio"
}

variable "minio_root_user" {
  type        = string
  description = "The user of minio"
}

variable "plugin_config_raw" {
  type        = string
  description = "The raw config of plugin"
}

variable "prow_config_raw" {
  type        = string
  description = "The raw config of prow"
}
