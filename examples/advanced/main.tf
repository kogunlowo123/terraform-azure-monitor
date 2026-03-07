provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "rg-monitor-advanced"
  location = "East US"
}

data "azurerm_subscription" "current" {}

resource "azurerm_linux_virtual_machine_scale_set" "example" {
  name                = "vmss-example"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard_B2s"
  instances           = 1
  admin_username      = "adminuser"

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  network_interface {
    name    = "nic-example"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet-main/subnets/snet-compute"
    }
  }
}

module "monitor" {
  source = "../../"

  resource_group_name          = azurerm_resource_group.example.name
  location                     = azurerm_resource_group.example.location
  log_analytics_workspace_name = "log-advanced-001"
  log_analytics_retention_days = 60

  create_application_insights   = true
  application_insights_name     = "appi-advanced-001"
  application_insights_type     = "web"

  action_groups = {
    "ag-critical" = {
      short_name = "Critical"
      email_receivers = [
        { name = "oncall-email", email_address = "oncall@example.com" },
        { name = "manager-email", email_address = "manager@example.com" }
      ]
      sms_receivers = [{
        name         = "oncall-sms"
        country_code = "1"
        phone_number = "5551234567"
      }]
    }
    "ag-warning" = {
      short_name = "Warning"
      email_receivers = [{
        name          = "team-email"
        email_address = "team@example.com"
      }]
    }
  }

  metric_alerts = {
    "alert-high-cpu" = {
      description = "Alert when CPU exceeds 85%"
      severity    = 2
      frequency   = "PT5M"
      window_size = "PT15M"
      scopes      = [azurerm_linux_virtual_machine_scale_set.example.id]
      action_group_names = ["ag-critical"]

      criteria = [{
        metric_namespace = "Microsoft.Compute/virtualMachineScaleSets"
        metric_name      = "Percentage CPU"
        aggregation      = "Average"
        operator         = "GreaterThan"
        threshold        = 85
      }]
    }
  }

  activity_log_alerts = {
    "alert-service-health" = {
      description = "Service health notification"
      scopes      = [data.azurerm_subscription.current.id]
      action_group_names = ["ag-critical"]

      criteria = {
        category = "ServiceHealth"
        service_health = {
          events    = ["Incident", "Maintenance"]
          locations = ["East US"]
        }
      }
    }
  }

  tags = {
    Environment = "staging"
    Project     = "monitoring-advanced"
  }
}

output "log_analytics_workspace_id" {
  value = module.monitor.log_analytics_workspace_id
}

output "application_insights_id" {
  value = module.monitor.application_insights_id
}

output "metric_alert_ids" {
  value = module.monitor.metric_alert_ids
}
