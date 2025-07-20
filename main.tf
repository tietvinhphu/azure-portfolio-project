terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
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

# 4. TẠO HẠ TẦNG CHO ỨNG DỤNG WEB (KẾ HOẠCH DỊCH VỤ)
resource "azurerm_service_plan" "plan" {
  name                = "portfolio-plan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "B1" # Bậc Basic, có chi phí thấp
}

# 5. TẠO ỨNG DỤNG WEB
resource "azurerm_linux_web_app" "webapp" {
  name                = "portfolio-webapp-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.plan.id
  https_only          = true

  # Xóa bỏ hoàn toàn linux_fx_version khỏi đây
  site_config {
    always_on = false
  }

  identity {
    type = "SystemAssigned"
  }

  # Thêm cấu hình Docker vào đây
  app_settings = {
    "SECRET_MESSAGE"             = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.secret.id})"
    "DOCKER_CUSTOM_IMAGE_NAME"   = "tietvinhphu/portfolio-app:latest"
    "DOCKER_REGISTRY_SERVER_URL" = "https://index.docker.io" # URL cho Docker Hub công khai
  }
}

# 6. CẤP QUYỀN CHO WEB APP ĐỌC KEY VAULT
resource "azurerm_key_vault_access_policy" "policy" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_web_app.webapp.identity[0].principal_id

  secret_permissions = ["Get"]
}
# 7. CẤP QUYỀN CHO BẠN (người đang chạy terraform) ĐỂ QUẢN LÝ SECRETS
resource "azurerm_key_vault_access_policy" "user_policy" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id # Lấy ID của chính bạn

  # Cấp quyền đầy đủ cho secrets
  secret_permissions = [
    "Get", "List", "Set", "Delete", "Purge", "Recover"
  ]

}
output "webapp_hostname" {
  description = "Địa chỉ trang web sau khi triển khai."
  value       = azurerm_linux_web_app.webapp.default_hostname
}