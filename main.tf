###############################################################################
# Log Analytics Workspace
###############################################################################
resource "azurerm_log_analytics_workspace" "this" {
  count = var.create_log_analytics_workspace ? 1 : 0

  name                               = local.log_analytics_workspace_name
  location                           = var.location
  resource_group_name                = var.resource_group_name
  sku                                = var.log_analytics_sku
  retention_in_days                  = var.log_analytics_retention_days
  daily_quota_gb                     = var.log_analytics_daily_quota_gb
  internet_ingestion_enabled         = var.log_analytics_internet_ingestion_enabled
  internet_query_enabled             = var.log_analytics_internet_query_enabled

  tags = local.common_tags
}

###############################################################################
# Log Analytics Solutions
###############################################################################
resource "azurerm_log_analytics_solution" "this" {
  for_each = var.create_log_analytics_workspace ? var.log_analytics_solutions : {}

  solution_name         = each.key
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.this[0].id
  workspace_name        = azurerm_log_analytics_workspace.this[0].name

  plan {
    publisher = each.value.publisher
    product   = each.value.product
  }
}

###############################################################################
# Application Insights
###############################################################################
resource "azurerm_application_insights" "this" {
  count = var.create_application_insights ? 1 : 0

  name                                  = local.application_insights_name
  location                              = var.location
  resource_group_name                   = var.resource_group_name
  workspace_id                          = local.log_analytics_workspace_id
  application_type                      = var.application_insights_type
  daily_data_cap_in_gb                  = var.application_insights_daily_data_cap_gb
  daily_data_cap_notifications_disabled = var.application_insights_daily_data_cap_notifications_disabled
  retention_in_days                     = var.application_insights_retention_days
  sampling_percentage                   = var.application_insights_sampling_percentage
  disable_ip_masking                    = var.application_insights_disable_ip_masking

  tags = local.common_tags
}

###############################################################################
# Action Groups
###############################################################################
resource "azurerm_monitor_action_group" "this" {
  for_each = var.action_groups

  name                = each.key
  resource_group_name = var.resource_group_name
  short_name          = each.value.short_name
  enabled             = each.value.enabled

  dynamic "email_receiver" {
    for_each = each.value.email_receivers
    content {
      name                    = email_receiver.value.name
      email_address           = email_receiver.value.email_address
      use_common_alert_schema = email_receiver.value.use_common_alert_schema
    }
  }

  dynamic "sms_receiver" {
    for_each = each.value.sms_receivers
    content {
      name         = sms_receiver.value.name
      country_code = sms_receiver.value.country_code
      phone_number = sms_receiver.value.phone_number
    }
  }

  dynamic "webhook_receiver" {
    for_each = each.value.webhook_receivers
    content {
      name                    = webhook_receiver.value.name
      service_uri             = webhook_receiver.value.service_uri
      use_common_alert_schema = webhook_receiver.value.use_common_alert_schema
    }
  }

  dynamic "azure_app_push_receiver" {
    for_each = each.value.azure_app_push_receivers
    content {
      name          = azure_app_push_receiver.value.name
      email_address = azure_app_push_receiver.value.email_address
    }
  }

  dynamic "arm_role_receiver" {
    for_each = each.value.arm_role_receivers
    content {
      name                    = arm_role_receiver.value.name
      role_id                 = arm_role_receiver.value.role_id
      use_common_alert_schema = arm_role_receiver.value.use_common_alert_schema
    }
  }

  dynamic "logic_app_receiver" {
    for_each = each.value.logic_app_receivers
    content {
      name                    = logic_app_receiver.value.name
      resource_id             = logic_app_receiver.value.resource_id
      callback_url            = logic_app_receiver.value.callback_url
      use_common_alert_schema = logic_app_receiver.value.use_common_alert_schema
    }
  }

  dynamic "azure_function_receiver" {
    for_each = each.value.azure_function_receivers
    content {
      name                     = azure_function_receiver.value.name
      function_app_resource_id = azure_function_receiver.value.function_app_resource_id
      function_name            = azure_function_receiver.value.function_name
      http_trigger_url         = azure_function_receiver.value.http_trigger_url
      use_common_alert_schema  = azure_function_receiver.value.use_common_alert_schema
    }
  }

  tags = merge(local.common_tags, each.value.tags)
}

###############################################################################
# Metric Alerts
###############################################################################
resource "azurerm_monitor_metric_alert" "this" {
  for_each = var.metric_alerts

  name                     = each.key
  resource_group_name      = var.resource_group_name
  description              = each.value.description
  enabled                  = each.value.enabled
  auto_mitigate            = each.value.auto_mitigate
  frequency                = each.value.frequency
  severity                 = each.value.severity
  window_size              = each.value.window_size
  scopes                   = each.value.scopes
  target_resource_type     = each.value.target_resource_type
  target_resource_location = each.value.target_resource_location

  dynamic "criteria" {
    for_each = each.value.criteria
    content {
      metric_namespace       = criteria.value.metric_namespace
      metric_name            = criteria.value.metric_name
      aggregation            = criteria.value.aggregation
      operator               = criteria.value.operator
      threshold              = criteria.value.threshold
      skip_metric_validation = criteria.value.skip_metric_validation

      dynamic "dimension" {
        for_each = criteria.value.dimension
        content {
          name     = dimension.value.name
          operator = dimension.value.operator
          values   = dimension.value.values
        }
      }
    }
  }

  dynamic "dynamic_criteria" {
    for_each = each.value.dynamic_criteria
    content {
      metric_namespace         = dynamic_criteria.value.metric_namespace
      metric_name              = dynamic_criteria.value.metric_name
      aggregation              = dynamic_criteria.value.aggregation
      operator                 = dynamic_criteria.value.operator
      alert_sensitivity        = dynamic_criteria.value.alert_sensitivity
      evaluation_total_count   = dynamic_criteria.value.evaluation_total_count
      evaluation_failure_count = dynamic_criteria.value.evaluation_failure_count
      skip_metric_validation   = dynamic_criteria.value.skip_metric_validation

      dynamic "dimension" {
        for_each = dynamic_criteria.value.dimension
        content {
          name     = dimension.value.name
          operator = dimension.value.operator
          values   = dimension.value.values
        }
      }
    }
  }

  dynamic "action" {
    for_each = each.value.action_group_names
    content {
      action_group_id = azurerm_monitor_action_group.this[action.value].id
    }
  }

  tags = merge(local.common_tags, each.value.tags)
}

###############################################################################
# Log Alerts (Scheduled Query Rules)
###############################################################################
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "this" {
  for_each = var.log_alerts

  name                 = each.key
  resource_group_name  = var.resource_group_name
  location             = var.location
  description          = each.value.description
  enabled              = each.value.enabled
  severity             = each.value.severity
  evaluation_frequency = each.value.evaluation_frequency
  window_duration      = each.value.window_duration
  scopes               = each.value.scopes

  auto_mitigation_enabled          = each.value.auto_mitigation_enabled
  workspace_alerts_storage_enabled = each.value.workspace_alerts_storage_enabled
  skip_query_validation            = each.value.skip_query_validation

  criteria {
    query                   = each.value.criteria.query
    time_aggregation_method = each.value.criteria.time_aggregation_method
    operator                = each.value.criteria.operator
    threshold               = each.value.criteria.threshold
    metric_measure_column   = each.value.criteria.metric_measure_column
    resource_id_column      = each.value.criteria.resource_id_column

    dynamic "dimension" {
      for_each = each.value.criteria.dimension
      content {
        name     = dimension.value.name
        operator = dimension.value.operator
        values   = dimension.value.values
      }
    }

    dynamic "failing_periods" {
      for_each = each.value.criteria.failing_periods != null ? [each.value.criteria.failing_periods] : []
      content {
        minimum_failing_periods_to_trigger_alert = failing_periods.value.minimum_failing_periods_to_trigger_alert
        number_of_evaluation_periods             = failing_periods.value.number_of_evaluation_periods
      }
    }
  }

  dynamic "action" {
    for_each = length(each.value.action_group_names) > 0 ? [1] : []
    content {
      action_groups = [for ag in each.value.action_group_names : azurerm_monitor_action_group.this[ag].id]
    }
  }

  tags = merge(local.common_tags, each.value.tags)
}

###############################################################################
# Activity Log Alerts
###############################################################################
resource "azurerm_monitor_activity_log_alert" "this" {
  for_each = var.activity_log_alerts

  name                = each.key
  resource_group_name = var.resource_group_name
  description         = each.value.description
  enabled             = each.value.enabled
  scopes              = each.value.scopes

  criteria {
    category       = each.value.criteria.category
    operation_name = each.value.criteria.operation_name
    level          = each.value.criteria.level
    status         = each.value.criteria.status
    resource_type  = each.value.criteria.resource_type
    resource_group = each.value.criteria.resource_group
    resource_id    = each.value.criteria.resource_id
    caller         = each.value.criteria.caller

    dynamic "resource_health" {
      for_each = each.value.criteria.resource_health != null ? [each.value.criteria.resource_health] : []
      content {
        current  = resource_health.value.current
        previous = resource_health.value.previous
        reason   = resource_health.value.reason
      }
    }

    dynamic "service_health" {
      for_each = each.value.criteria.service_health != null ? [each.value.criteria.service_health] : []
      content {
        events    = service_health.value.events
        locations = service_health.value.locations
        services  = service_health.value.services
      }
    }
  }

  dynamic "action" {
    for_each = each.value.action_group_names
    content {
      action_group_id = azurerm_monitor_action_group.this[action.value].id
    }
  }

  tags = merge(local.common_tags, each.value.tags)
}

###############################################################################
# Diagnostic Settings
###############################################################################
resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each = var.diagnostic_settings

  name                           = each.key
  target_resource_id             = each.value.target_resource_id
  log_analytics_workspace_id     = each.value.log_analytics_workspace_id != null ? each.value.log_analytics_workspace_id : local.log_analytics_workspace_id
  storage_account_id             = each.value.storage_account_id
  eventhub_authorization_rule_id = each.value.eventhub_authorization_rule_id
  eventhub_name                  = each.value.eventhub_name
  log_analytics_destination_type = each.value.log_analytics_destination_type
  partner_solution_id            = each.value.partner_solution_id

  dynamic "enabled_log" {
    for_each = each.value.enabled_logs
    content {
      category       = enabled_log.value.category
      category_group = enabled_log.value.category_group
    }
  }

  dynamic "metric" {
    for_each = each.value.metrics
    content {
      category = metric.value.category
      enabled  = metric.value.enabled
    }
  }
}

###############################################################################
# Data Collection Rules
###############################################################################
resource "azurerm_monitor_data_collection_rule" "this" {
  for_each = var.data_collection_rules

  name                = each.key
  resource_group_name = var.resource_group_name
  location            = var.location
  description         = each.value.description
  kind                = each.value.kind

  destinations {
    dynamic "log_analytics" {
      for_each = each.value.destinations.log_analytics
      content {
        workspace_resource_id = log_analytics.value.workspace_resource_id
        name                  = log_analytics.value.name
      }
    }

    dynamic "azure_monitor_metrics" {
      for_each = each.value.destinations.azure_monitor_metrics != null ? [each.value.destinations.azure_monitor_metrics] : []
      content {
        name = azure_monitor_metrics.value.name
      }
    }
  }

  dynamic "data_flow" {
    for_each = each.value.data_flows
    content {
      streams      = data_flow.value.streams
      destinations = data_flow.value.destinations
    }
  }

  dynamic "data_sources" {
    for_each = each.value.data_sources != null ? [each.value.data_sources] : []
    content {
      dynamic "performance_counter" {
        for_each = data_sources.value.performance_counters
        content {
          name                          = performance_counter.value.name
          streams                       = performance_counter.value.streams
          sampling_frequency_in_seconds = performance_counter.value.sampling_frequency_in_seconds
          counter_specifiers            = performance_counter.value.counter_specifiers
        }
      }

      dynamic "windows_event_log" {
        for_each = data_sources.value.windows_event_logs
        content {
          name           = windows_event_log.value.name
          streams        = windows_event_log.value.streams
          x_path_queries = windows_event_log.value.x_path_queries
        }
      }

      dynamic "syslog" {
        for_each = data_sources.value.syslog
        content {
          name           = syslog.value.name
          streams        = syslog.value.streams
          facility_names = syslog.value.facility_names
          log_levels     = syslog.value.log_levels
        }
      }
    }
  }

  tags = merge(local.common_tags, each.value.tags)
}
