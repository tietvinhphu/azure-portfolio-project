terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.1"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

# Suffix ngẫu nhiên để đảm bảo tên tài nguyên là duy nhất
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# 1. TẠO NHÓM TÀI NGUYÊN
resource "azurerm_resource_group" "rg" {
  name     = "portfolio-project-rg-${random_string.suffix.result}"
  location = "Southeast Asia"
}

# 2. TẠO HẠ TẦNG MẠNG (VNET & SUBNET)
resource "azurerm_virtual_network" "vnet" {
  name                = "portfolio-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "app_subnet" {
  name                 = "app-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# 3. TẠO KHO BÍ MẬT (KEY VAULT)
resource "azurerm_key_vault" "kv" {
  name                = "portfoliokv${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
}

resource "azurerm_key_vault_secret" "secret" {
  name         = "SecretMessage"
  value        = "Thanh cong! Ban da lay duoc bi mat tu Key Vault."
  key_vault_id = azurerm_key_vault.kv.id
}

# 4. TẠO HẠ TẦNG CHO ỨNG DỤNG WEB
resource "azurerm_service_plan" "plan" {
  name                = "portfolio-plan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "B1" # Bậc Basic, có chi phí thấp
}

resource "azurerm_linux_web_app" "webapp" {
  name                = "portfolio-webapp-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.plan.id
  https_only          = true # Bật HTTPS

   # Cấu hình để chạy Docker container
  site_config {
    always_on        = false
    linux_fx_version = "DOCKER|node:latest"
  }

  # TẠO DANH TÍNH ĐƯỢC QUẢN LÝ
  identity {
    type = "SystemAssigned"
  }

  # CÀI ĐẶT THAM CHIẾU ĐẾN KEY VAULT
  app_settings = {
    "SECRET_MESSAGE" = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.secret.id})"
  }
}

# 5. CẤP QUYỀN CHO WEB APP ĐỌC KEY VAULT
resource "azurerm_key_vault_access_policy" "policy" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_web_app.webapp.identity[0].principal_id

  secret_permissions = ["Get"]
}