module "prow" {
  source = "../.."

  plugin_config_raw           = file("./conf.d/plugins.tftpl")
  prow_config_raw             = templatefile("./conf.d/config.tftpl", { domain = var.domain })
  domain                      = var.domain
  kube_host                   = module.aks.host
  kube_client_certificate     = module.aks.admin_client_certificate
  kube_client_key             = module.aks.admin_client_key
  kube_cluster_ca_certificate = module.aks.admin_cluster_ca_certificate
  hmac_token                  = file("${path.module}/conf.d/hmac-token")
  minio_root_user             = "root"
  minio_root_password         = "ZXa9s8d80a"
  github_appid                = "245737"
  github_cert                 = file("${path.module}/conf.d/github_cert.pem")
}
