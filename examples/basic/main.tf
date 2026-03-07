provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "rg-monitor-basic"
  location = "East US"
}

module "monitor" {
  source = "../../"

  resource_group_name          = azurerm_resource_group.example.name
  location                     = azurerm_resource_group.example.location
  log_analytics_workspace_name = "log-basic-001"

  action_groups = {
    "ag-ops-team" = {
      short_name = "OpsTeam"
      email_receivers = [{
        name          = "ops-email"
        email_address = "ops@example.com"
      }]
    }
  }

  tags = {
    Environment = "development"
  }
}

output "log_analytics_workspace_id" {
  value = module.monitor.log_analytics_workspace_id
}

output "action_group_ids" {
  value = module.monitor.action_group_ids
}
