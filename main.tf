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
  name     = "stlresgroup${random_integer.ri.result}"
  location = "polandcentral"
}

resource "azurerm_service_plan" "asp" {
  name                = "ContactsBookServicePlan${random_integer.ri.result}"
  resource_group_name = azurerm_resource_group.stlresgroup.name
  location            = azurerm_resource_group.stlresgroup.location
  os_type             = "Linux"
  sku_name            = "F1"
}

resource "azurerm_linux_web_app" "alwa" {
  name                = "ContactsBookWebApp${random_integer.ri.result}"
  resource_group_name = azurerm_resource_group.stlresgroup.name
  location            = azurerm_service_plan.asp.location
  service_plan_id     = azurerm_service_plan.asp.id

  site_config {
    application_stack {
      node_version = "16-lts"
    }
    always_on = false
  }
}

resource "azurerm_app_service_source_control" "aassc" {
  app_id                 = azurerm_linux_web_app.alwa.id
  repo_url               = "https://github.com/nakov/ContactBook"
  branch                 = "master"
  use_manual_integration = true
}
