terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.38.1"
    }
  }
}

provider "azurerm" {
  features {
  }
  subscription_id = "c897cbe7-bc5d-426f-96a1-d0473db7848a"
}

resource "random_integer" "ri" {
  min = 1
  max = 5000
}

resource "azurerm_resource_group" "stlresgroup" {
  name     = "AzureTasks${random_integer.ri.result}"
  location = "polandcentral"
}

resource "azurerm_service_plan" "asp" {
  name                = "AzureTasksServicePlan${random_integer.ri.result}"
  resource_group_name = azurerm_resource_group.stlresgroup.name
  location            = azurerm_resource_group.stlresgroup.location
  os_type             = "Linux"
  sku_name            = "F1"
}

resource "azurerm_linux_web_app" "alwa" {
  name                = "AzureTasksWebApp${random_integer.ri.result}"
  resource_group_name = azurerm_resource_group.stlresgroup.name
  location            = azurerm_service_plan.asp.location
  service_plan_id     = azurerm_service_plan.asp.id

  site_config {
    application_stack {
      dotnet_version = "6.0"
    }
    always_on = false
  }

  connection_string {
    name  = "DefaultConnection"
    type  = "SQLAzure"
    value = "Data Source=tcp:${azurerm_mssql_server.server.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.database.name};User ID=${azurerm_mssql_server.server.administrator_login};Password=${azurerm_mssql_server.server.administrator_login_password};Trusted_Connection=False; MultipleActiveResultSets=True;"
  }
}

resource "azurerm_app_service_source_control" "aassc" {
  app_id   = azurerm_linux_web_app.alwa.id
  repo_url = "https://github.com/StiliyanEnchev/Azure-Web-App-with-Database-TaskBoard"
  branch   = "main"
}

resource "azurerm_mssql_server" "server" {
  name                         = "taskboardsqlserver${random_integer.ri.result}"
  resource_group_name          = azurerm_resource_group.stlresgroup.name
  location                     = "polandcentral"
  version                      = "12.0"
  administrator_login          = "4dm1n157r470r"
  administrator_login_password = "4-v3ry-53cr37-p455w0rd"
}

resource "azurerm_mssql_database" "database" {
  name                 = "TaskBoardDB${random_integer.ri.result}"
  server_id            = azurerm_mssql_server.server.id
  collation            = "SQL_Latin1_General_CP1_CI_AS"
  license_type         = "LicenseIncluded"
  max_size_gb          = 2
  sku_name             = "S0"
  zone_redundant       = false
}

resource "azurerm_mssql_firewall_rule" "firewall" {
  name             = "FirewallRule1"
  server_id        = azurerm_mssql_server.server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}