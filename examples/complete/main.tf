provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "rg-monitor-complete"
  location = "East US"
}

data "azurerm_subscription" "current" {}

resource "azurerm_storage_account" "example" {
  name                     = "stmonitorcomp001"
  location                 = azurerm_resource_group.example.location
  resource_group_name      = azurerm_resource_group.example.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_key_vault" "example" {
  name                = "kv-monitor-comp-001"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
}

data "azurerm_client_config" "current" {}

module "monitor" {
  source = "../../"

  resource_group_name          = azurerm_resource_group.example.name
  location                     = azurerm_resource_group.example.location
  log_analytics_workspace_name = "log-complete-001"
  log_analytics_sku            = "PerGB2018"
  log_analytics_retention_days = 90
  log_analytics_daily_quota_gb = 10

  log_analytics_solutions = {
    "SecurityInsights" = {
      publisher = "Microsoft"
      product   = "OMSGallery/SecurityInsights"
    }
    "ContainerInsights" = {
      publisher = "Microsoft"
      product   = "OMSGallery/ContainerInsights"
    }
  }

  create_application_insights                               = true
  application_insights_name                                 = "appi-complete-001"
  application_insights_type                                 = "web"
  application_insights_daily_data_cap_gb                    = 5
  application_insights_retention_days                       = 120
  application_insights_sampling_percentage                  = 50
  application_insights_daily_data_cap_notifications_disabled = false

  action_groups = {
    "ag-critical" = {
      short_name = "Critical"
      email_receivers = [
        { name = "oncall-primary", email_address = "oncall-primary@example.com" },
        { name = "oncall-secondary", email_address = "oncall-secondary@example.com" }
      ]
      sms_receivers = [
        { name = "oncall-sms", country_code = "1", phone_number = "5551234567" }
      ]
      webhook_receivers = [{
        name        = "pagerduty"
        service_uri = "https://events.pagerduty.com/integration/abc123/enqueue"
      }]
    }
    "ag-warning" = {
      short_name = "Warning"
      email_receivers = [{
        name          = "team-email"
        email_address = "platform-team@example.com"
      }]
    }
    "ag-informational" = {
      short_name = "Info"
      email_receivers = [{
        name          = "info-email"
        email_address = "info@example.com"
      }]
    }
  }

  metric_alerts = {
    "alert-storage-capacity" = {
      description        = "Alert when storage account capacity exceeds 80%"
      severity           = 2
      frequency          = "PT1H"
      window_size        = "PT1H"
      scopes             = [azurerm_storage_account.example.id]
      action_group_names = ["ag-warning"]

      criteria = [{
        metric_namespace = "Microsoft.Storage/storageAccounts"
        metric_name      = "UsedCapacity"
        aggregation      = "Average"
        operator         = "GreaterThan"
        threshold        = 85899345920
      }]
    }
    "alert-storage-availability" = {
      description        = "Alert on storage availability drop"
      severity           = 1
      frequency          = "PT5M"
      window_size        = "PT15M"
      scopes             = [azurerm_storage_account.example.id]
      action_group_names = ["ag-critical"]

      dynamic_criteria = [{
        metric_namespace  = "Microsoft.Storage/storageAccounts"
        metric_name       = "Availability"
        aggregation       = "Average"
        operator          = "LessThan"
        alert_sensitivity = "High"
      }]
    }
  }

  log_alerts = {
    "alert-keyvault-errors" = {
      description          = "Alert on Key Vault operation errors"
      severity             = 2
      evaluation_frequency = "PT10M"
      window_duration      = "PT30M"
      scopes               = [azurerm_key_vault.example.id]
      action_group_names   = ["ag-critical"]

      criteria = {
        query                   = <<-QUERY
          AzureDiagnostics
          | where ResourceType == "VAULTS"
          | where ResultType != "Success"
          | summarize ErrorCount = count() by bin(TimeGenerated, 5m), OperationName
        QUERY
        time_aggregation_method = "Count"
        operator                = "GreaterThan"
        threshold               = 5

        failing_periods = {
          minimum_failing_periods_to_trigger_alert = 2
          number_of_evaluation_periods             = 3
        }
      }
    }
  }

  activity_log_alerts = {
    "alert-service-health" = {
      description        = "Service health incident notification"
      scopes             = [data.azurerm_subscription.current.id]
      action_group_names = ["ag-critical"]

      criteria = {
        category = "ServiceHealth"
        service_health = {
          events    = ["Incident", "Maintenance", "Security"]
          locations = ["East US", "West US 2"]
        }
      }
    }
    "alert-resource-health" = {
      description        = "Resource health degradation alert"
      scopes             = [data.azurerm_subscription.current.id]
      action_group_names = ["ag-warning"]

      criteria = {
        category = "ResourceHealth"
        resource_health = {
          current  = ["Degraded", "Unavailable"]
          previous = ["Available"]
          reason   = ["PlatformInitiated"]
        }
      }
    }
    "alert-policy-changes" = {
      description        = "Alert on Azure Policy assignment changes"
      scopes             = [data.azurerm_subscription.current.id]
      action_group_names = ["ag-informational"]

      criteria = {
        category       = "Administrative"
        operation_name = "Microsoft.Authorization/policyAssignments/write"
      }
    }
  }

  diagnostic_settings = {
    "diag-keyvault" = {
      target_resource_id = azurerm_key_vault.example.id

      enabled_logs = [
        { category_group = "allLogs" }
      ]

      metrics = [{
        category = "AllMetrics"
        enabled  = true
      }]
    }
    "diag-storage" = {
      target_resource_id = azurerm_storage_account.example.id
      storage_account_id = azurerm_storage_account.example.id

      metrics = [{
        category = "Transaction"
        enabled  = true
      }]
    }
  }

  data_collection_rules = {
    "dcr-linux-perf" = {
      description = "Linux performance counter collection rule"
      kind        = "Linux"

      destinations = {
        log_analytics = [{
          workspace_resource_id = module.monitor.log_analytics_workspace_id
          name                  = "log-analytics-dest"
        }]
      }

      data_flows = [{
        streams      = ["Microsoft-Perf", "Microsoft-Syslog"]
        destinations = ["log-analytics-dest"]
      }]

      data_sources = {
        performance_counters = [{
          name                          = "linux-perf"
          streams                       = ["Microsoft-Perf"]
          sampling_frequency_in_seconds = 60
          counter_specifiers = [
            "Processor(*)\\% Processor Time",
            "Memory(*)\\% Used Memory",
            "LogicalDisk(*)\\% Free Space"
          ]
        }]

        syslog = [{
          name           = "linux-syslog"
          streams        = ["Microsoft-Syslog"]
          facility_names = ["auth", "authpriv", "daemon", "kern", "syslog"]
          log_levels     = ["Alert", "Critical", "Emergency", "Error", "Warning"]
        }]
      }
    }
  }

  tags = {
    Environment = "production"
    Project     = "monitoring-platform"
    CostCenter  = "MON-001"
  }
}

output "log_analytics_workspace_id" {
  value = module.monitor.log_analytics_workspace_id
}

output "application_insights_id" {
  value = module.monitor.application_insights_id
}

output "action_group_ids" {
  value = module.monitor.action_group_ids
}

output "metric_alert_ids" {
  value = module.monitor.metric_alert_ids
}

output "log_alert_ids" {
  value = module.monitor.log_alert_ids
}

output "activity_log_alert_ids" {
  value = module.monitor.activity_log_alert_ids
}

output "data_collection_rule_ids" {
  value = module.monitor.data_collection_rule_ids
}
