provider "kubernetes" {
  host                   = module.aks.host
  client_certificate     = base64decode(module.aks.admin_client_certificate)
  client_key             = base64decode(module.aks.admin_client_key)
  cluster_ca_certificate = base64decode(module.aks.admin_cluster_ca_certificate)
}

resource "azurerm_managed_disk" "shared" {
  name                 = "shared"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "20"
}

resource "kubernetes_persistent_volume" "shared" {
  metadata {
    name = "shared"
  }
  spec {
    capacity = {
      storage = "16Gi"
    }
    access_modes = ["ReadWriteOnce"]
    persistent_volume_source {
      azure_disk {
        caching_mode  = "None"
        data_disk_uri = azurerm_managed_disk.shared.id
        disk_name     = "example"
        kind          = "Managed"
      }
    }
  }
}
