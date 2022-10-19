# Terraform module for Kubernetes Prow

Prow is a Kubernetes based CI/CD system.

Prow provides GitHub automation in the form of policy enforcement, chat-ops via /foo style commands, and automatic PR merging.

See also:

* [Repository](https://github.com/kubernetes/test-infra/tree/master/prow)
* [Deploying Prow](https://github.com/kubernetes/test-infra/blob/master/prow/getting_started_deploy.md)

## Pre-requirements

### A GitHub app with specified permissions

Repository permissions:

* Actions: Read-Only (Only needed when using the merge automation `tide`)
* Administration: Read-Only (Required to fetch teams and collaborateurs)
* Checks: Read-Only (Only needed when using the merge automation `tide`)
* Contents: Read (Read & write needed when using the merge automation `tide`)
* Issues: Read & write
* Metadata: Read-Only
* Pull Requests: Read & write
* Projects: Admin when using the `projects` plugin, none otherwise
* Commit statuses: Read & write

Organization permissions:

* Members: Read-Only (Read & write when using `peribolos`)
* Projects: Admin when using the `projects` plugin, none otherwise

Subscribe to events:

* All events.

### Secret

Webhook secret:

```shell
openssl rand -hex 20
```

GitHub App private key:

Click `generate private key` after GitHub App created.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name                                                                      | Version |
|---------------------------------------------------------------------------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2  |

## Providers

| Name                                                                   | Version |
|------------------------------------------------------------------------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | n/a     |

## Modules

No modules.

## Resources

| Name                                                                                                                                                         | Type     |
|--------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|
| [kubernetes_config_map.config](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map)                                | resource |
| [kubernetes_config_map.plugins](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map)                               | resource |
| [kubernetes_deployment.crier](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment)                                 | resource |
| [kubernetes_deployment.deck](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment)                                  | resource |
| [kubernetes_deployment.ghproxy](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment)                               | resource |
| [kubernetes_deployment.hook](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment)                                  | resource |
| [kubernetes_deployment.horologium](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment)                            | resource |
| [kubernetes_deployment.minio](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment)                                 | resource |
| [kubernetes_deployment.prow_controller_manager](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment)               | resource |
| [kubernetes_deployment.sinker](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment)                                | resource |
| [kubernetes_deployment.statusreconciler](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment)                      | resource |
| [kubernetes_deployment.tide](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment)                                  | resource |
| [kubernetes_ingress_v1.prow](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_v1)                                  | resource |
| [kubernetes_namespace.prow](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace)                                    | resource |
| [kubernetes_namespace.test_pods](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace)                               | resource |
| [kubernetes_persistent_volume_claim.ghproxy](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim)     | resource |
| [kubernetes_persistent_volume_claim.minio](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim)       | resource |
| [kubernetes_role.hook](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role)                                              | resource |
| [kubernetes_role.prow_controller_manager](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role)                           | resource |
| [kubernetes_role.prow_crier](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role)                                        | resource |
| [kubernetes_role.prow_deck](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role)                                         | resource |
| [kubernetes_role.prow_sinker](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role)                                       | resource |
| [kubernetes_role.prowhorologium](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role)                                    | resource |
| [kubernetes_role.statusreconciler](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role)                                  | resource |
| [kubernetes_role.test_pods_crier](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role)                                   | resource |
| [kubernetes_role.test_pods_deck](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role)                                    | resource |
| [kubernetes_role.test_pods_prow_controller_manager](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role)                 | resource |
| [kubernetes_role.test_pods_sinker](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role)                                  | resource |
| [kubernetes_role.tide](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role)                                              | resource |
| [kubernetes_role_binding.hook](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role_binding)                              | resource |
| [kubernetes_role_binding.horologium](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role_binding)                        | resource |
| [kubernetes_role_binding.prow_controller_manager](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role_binding)           | resource |
| [kubernetes_role_binding.prow_crier](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role_binding)                        | resource |
| [kubernetes_role_binding.prow_deck](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role_binding)                         | resource |
| [kubernetes_role_binding.prow_sinker](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role_binding)                       | resource |
| [kubernetes_role_binding.statusreconciler](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role_binding)                  | resource |
| [kubernetes_role_binding.test_pods_crier](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role_binding)                   | resource |
| [kubernetes_role_binding.test_pods_deck](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role_binding)                    | resource |
| [kubernetes_role_binding.test_pods_prow_controller_manager](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role_binding) | resource |
| [kubernetes_role_binding.test_pods_sinker](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role_binding)                  | resource |
| [kubernetes_role_binding.tide](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role_binding)                              | resource |
| [kubernetes_secret.github_token](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret)                                  | resource |
| [kubernetes_secret.hmac_token](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret)                                    | resource |
| [kubernetes_secret.prow_s3_credentials](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret)                           | resource |
| [kubernetes_secret.test_pods_prow_s3_credentials](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret)                 | resource |
| [kubernetes_service.deck](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service)                                        | resource |
| [kubernetes_service.ghproxy](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service)                                     | resource |
| [kubernetes_service.hook](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service)                                        | resource |
| [kubernetes_service.minio](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service)                                       | resource |
| [kubernetes_service.tide](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service)                                        | resource |
| [kubernetes_service_account.crier](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account)                       | resource |
| [kubernetes_service_account.deck](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account)                        | resource |
| [kubernetes_service_account.hook](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account)                        | resource |
| [kubernetes_service_account.horologium](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account)                  | resource |
| [kubernetes_service_account.prow_controller_manager](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account)     | resource |
| [kubernetes_service_account.sinker](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account)                      | resource |
| [kubernetes_service_account.statusreconciler](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account)            | resource |
| [kubernetes_service_account.tide](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account)                        | resource |

## Inputs

| Name                                                                                                                      | Description                                      | Type     | Default | Required |
|---------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------|----------|---------|:--------:|
| <a name="input_domain"></a> [domain](#input\_domain)                                                                      | The top-level domain of prow service             | `string` | n/a     |   yes    |
| <a name="input_github_appid"></a> [github\_appid](#input\_github\_appid)                                                  | The id of Github APP                             | `string` | n/a     |   yes    |
| <a name="input_github_cert"></a> [github\_cert](#input\_github\_cert)                                                     | The private key cert pem of Github APP           | `string` | n/a     |   yes    |
| <a name="input_hmac_token"></a> [hmac\_token](#input\_hmac\_token)                                                        | The hmac token of Github webhook secret          | `string` | n/a     |   yes    |
| <a name="input_kube_client_certificate"></a> [kube\_client\_certificate](#input\_kube\_client\_certificate)               | The client certificate of Kubernetes cluster     | `string` | n/a     |   yes    |
| <a name="input_kube_client_key"></a> [kube\_client\_key](#input\_kube\_client\_key)                                       | The client key of Kubernetes cluster             | `string` | n/a     |   yes    |
| <a name="input_kube_cluster_ca_certificate"></a> [kube\_cluster\_ca\_certificate](#input\_kube\_cluster\_ca\_certificate) | The cluster ca certificate of Kubernetes cluster | `string` | n/a     |   yes    |
| <a name="input_kube_host"></a> [kube\_host](#input\_kube\_host)                                                           | The hostname of Kubernetes cluster               | `string` | n/a     |   yes    |
| <a name="input_minio_root_password"></a> [minio\_root\_password](#input\_minio\_root\_password)                           | The password of minio                            | `string` | n/a     |   yes    |
| <a name="input_minio_root_user"></a> [minio\_root\_user](#input\_minio\_root\_user)                                       | The user of minio                                | `string` | n/a     |   yes    |
| <a name="input_plugin_config_raw"></a> [plugin\_config\_raw](#input\_plugin\_config\_raw)                                 | The raw config of plugin                         | `string` | n/a     |   yes    |
| <a name="input_prow_config_raw"></a> [prow\_config\_raw](#input\_prow\_config\_raw)                                       | The raw config of prow                           | `string` | n/a     |   yes    |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
