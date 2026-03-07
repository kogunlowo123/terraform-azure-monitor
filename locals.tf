locals {
  common_tags = merge(var.tags, {
    ManagedBy = "Terraform"
    Module    = "terraform-azure-monitor"
  })

  log_analytics_workspace_name = var.log_analytics_workspace_name != "" ? var.log_analytics_workspace_name : "log-monitor-${var.location}"

  log_analytics_workspace_id = var.create_log_analytics_workspace ? azurerm_log_analytics_workspace.this[0].id : null

  action_group_ids = {
    for k, v in azurerm_monitor_action_group.this : k => v.id
  }

  application_insights_name = var.application_insights_name != "" ? var.application_insights_name : "appi-monitor-${var.location}"
}
