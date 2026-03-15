module "test" {
  source = "../"

  resource_group_name = "rg-monitor-test"
  location            = "eastus2"

  # Log Analytics Workspace
  create_log_analytics_workspace = true
  log_analytics_workspace_name   = "law-monitor-test"
  log_analytics_sku              = "PerGB2018"
  log_analytics_retention_days   = 30

  # Application Insights
  create_application_insights = true
  application_insights_name   = "ai-monitor-test"
  application_insights_type   = "web"

  # Action Groups
  action_groups = {
    critical-alerts = {
      short_name = "critical"
      enabled    = true
      email_receivers = [
        {
          name                    = "ops-team"
          email_address           = "ops@example.com"
          use_common_alert_schema = true
        }
      ]
    }
  }

  tags = {
    environment = "test"
    managed_by  = "terraform"
  }
}
