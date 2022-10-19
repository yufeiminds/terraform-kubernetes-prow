provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

resource "random_id" "prefix" {
  byte_length = 8
}

locals {
  resource_group_name = "${random_id.prefix.hex}-rg"
}

resource "azurerm_resource_group" "main" {
  location = var.location
  name     = local.resource_group_name
}

resource "azurerm_virtual_network" "test" {
  address_space       = ["10.52.0.0/16"]
  location            = var.location
  name                = "${random_id.prefix.hex}-vn"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "test" {
  address_prefixes     = ["10.52.0.0/24"]
  name                 = "${random_id.prefix.hex}-sn"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.test.name
}

module "aks" {
  source  = "Azure/aks/azurerm"
  version = "6.0.0"

  prefix                            = "prefix-${random_id.prefix.hex}"
  resource_group_name               = azurerm_resource_group.main.name
  agents_availability_zones         = ["1", "2"]
  net_profile_dns_service_ip        = "10.0.0.10"
  net_profile_docker_bridge_cidr    = "170.10.0.1/16"
  net_profile_service_cidr          = "10.0.0.0/16"
  network_plugin                    = "azure"
  network_policy                    = "azure"
  os_disk_size_gb                   = 60
  private_cluster_enabled           = false
  local_account_disabled            = false
  rbac_aad_managed                  = true
  role_based_access_control_enabled = true
  sku_tier                          = "Paid"
  identity_type                     = "SystemAssigned"
  vnet_subnet_id                    = azurerm_subnet.test.id

  agents_labels = {
    "node1" : "label1"
  }
  agents_tags = {
    "Agent" : "agentTag"
  }
}
