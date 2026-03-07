output "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace."
  value       = var.create_log_analytics_workspace ? azurerm_log_analytics_workspace.this[0].id : null
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace."
  value       = var.create_log_analytics_workspace ? azurerm_log_analytics_workspace.this[0].name : null
}

output "log_analytics_workspace_customer_id" {
  description = "Workspace (customer) ID of the Log Analytics workspace."
  value       = var.create_log_analytics_workspace ? azurerm_log_analytics_workspace.this[0].workspace_id : null
}

output "log_analytics_workspace_primary_shared_key" {
  description = "Primary shared key of the Log Analytics workspace."
  value       = var.create_log_analytics_workspace ? azurerm_log_analytics_workspace.this[0].primary_shared_key : null
  sensitive   = true
}

output "log_analytics_workspace_secondary_shared_key" {
  description = "Secondary shared key of the Log Analytics workspace."
  value       = var.create_log_analytics_workspace ? azurerm_log_analytics_workspace.this[0].secondary_shared_key : null
  sensitive   = true
}

output "application_insights_id" {
  description = "Resource ID of the Application Insights resource."
  value       = var.create_application_insights ? azurerm_application_insights.this[0].id : null
}

output "application_insights_name" {
  description = "Name of the Application Insights resource."
  value       = var.create_application_insights ? azurerm_application_insights.this[0].name : null
}

output "application_insights_app_id" {
  description = "Application ID of the Application Insights resource."
  value       = var.create_application_insights ? azurerm_application_insights.this[0].app_id : null
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key of the Application Insights resource."
  value       = var.create_application_insights ? azurerm_application_insights.this[0].instrumentation_key : null
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Connection string of the Application Insights resource."
  value       = var.create_application_insights ? azurerm_application_insights.this[0].connection_string : null
  sensitive   = true
}

output "action_group_ids" {
  description = "Map of action group names to their resource IDs."
  value       = { for k, v in azurerm_monitor_action_group.this : k => v.id }
}

output "metric_alert_ids" {
  description = "Map of metric alert names to their resource IDs."
  value       = { for k, v in azurerm_monitor_metric_alert.this : k => v.id }
}

output "log_alert_ids" {
  description = "Map of log alert names to their resource IDs."
  value       = { for k, v in azurerm_monitor_scheduled_query_rules_alert_v2.this : k => v.id }
}

output "activity_log_alert_ids" {
  description = "Map of activity log alert names to their resource IDs."
  value       = { for k, v in azurerm_monitor_activity_log_alert.this : k => v.id }
}

output "diagnostic_setting_ids" {
  description = "Map of diagnostic setting names to their resource IDs."
  value       = { for k, v in azurerm_monitor_diagnostic_setting.this : k => v.id }
}

output "data_collection_rule_ids" {
  description = "Map of data collection rule names to their resource IDs."
  value       = { for k, v in azurerm_monitor_data_collection_rule.this : k => v.id }
}
