variable "resource_group_name" {
  description = "Name of the resource group where resources will be created."
  type        = string

  validation {
    condition     = length(var.resource_group_name) > 0 && length(var.resource_group_name) <= 90
    error_message = "Resource group name must be between 1 and 90 characters."
  }
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
}

variable "create_log_analytics_workspace" {
  description = "Whether to create a Log Analytics workspace."
  type        = bool
  default     = true
}

variable "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace."
  type        = string
  default     = ""
}

variable "log_analytics_sku" {
  description = "SKU for the Log Analytics workspace."
  type        = string
  default     = "PerGB2018"

  validation {
    condition     = contains(["Free", "PerGB2018", "PerNode", "Premium", "Standard", "Standalone"], var.log_analytics_sku)
    error_message = "SKU must be one of: Free, PerGB2018, PerNode, Premium, Standard, Standalone."
  }
}

variable "log_analytics_retention_days" {
  description = "Data retention in days for the Log Analytics workspace (30-730)."
  type        = number
  default     = 30

  validation {
    condition     = var.log_analytics_retention_days >= 30 && var.log_analytics_retention_days <= 730
    error_message = "Retention must be between 30 and 730 days."
  }
}

variable "log_analytics_daily_quota_gb" {
  description = "Daily ingestion quota in GB (-1 means unlimited)."
  type        = number
  default     = -1
}

variable "log_analytics_internet_ingestion_enabled" {
  description = "Whether internet ingestion is enabled."
  type        = bool
  default     = true
}

variable "log_analytics_internet_query_enabled" {
  description = "Whether internet query is enabled."
  type        = bool
  default     = true
}

variable "log_analytics_solutions" {
  description = "Map of Log Analytics solutions to install."
  type = map(object({
    publisher = string
    product   = string
  }))
  default = {}
}

variable "create_application_insights" {
  description = "Whether to create an Application Insights resource."
  type        = bool
  default     = false
}

variable "application_insights_name" {
  description = "Name of the Application Insights resource."
  type        = string
  default     = ""
}

variable "application_insights_type" {
  description = "Type of Application Insights."
  type        = string
  default     = "web"

  validation {
    condition     = contains(["ios", "java", "MobileCenter", "Node.JS", "other", "phone", "store", "web"], var.application_insights_type)
    error_message = "Application type must be one of: ios, java, MobileCenter, Node.JS, other, phone, store, web."
  }
}

variable "application_insights_daily_data_cap_gb" {
  description = "Daily data volume cap in GB for Application Insights."
  type        = number
  default     = null
}

variable "application_insights_daily_data_cap_notifications_disabled" {
  description = "Whether notifications for daily data cap are disabled."
  type        = bool
  default     = false
}

variable "application_insights_retention_days" {
  description = "Retention period in days for Application Insights."
  type        = number
  default     = 90

  validation {
    condition     = contains([30, 60, 90, 120, 180, 270, 365, 550, 730], var.application_insights_retention_days)
    error_message = "Retention must be one of: 30, 60, 90, 120, 180, 270, 365, 550, 730."
  }
}

variable "application_insights_sampling_percentage" {
  description = "Sampling percentage for Application Insights (0-100)."
  type        = number
  default     = 100
}

variable "application_insights_disable_ip_masking" {
  description = "Whether to disable IP masking in Application Insights."
  type        = bool
  default     = false
}

variable "action_groups" {
  description = "Map of monitor action groups to create."
  type = map(object({
    short_name = string
    enabled    = optional(bool, true)

    email_receivers = optional(list(object({
      name                    = string
      email_address           = string
      use_common_alert_schema = optional(bool, true)
    })), [])

    sms_receivers = optional(list(object({
      name         = string
      country_code = string
      phone_number = string
    })), [])

    webhook_receivers = optional(list(object({
      name                    = string
      service_uri             = string
      use_common_alert_schema = optional(bool, true)
    })), [])

    azure_app_push_receivers = optional(list(object({
      name          = string
      email_address = string
    })), [])

    arm_role_receivers = optional(list(object({
      name                    = string
      role_id                 = string
      use_common_alert_schema = optional(bool, true)
    })), [])

    logic_app_receivers = optional(list(object({
      name                    = string
      resource_id             = string
      callback_url            = string
      use_common_alert_schema = optional(bool, true)
    })), [])

    azure_function_receivers = optional(list(object({
      name                     = string
      function_app_resource_id = string
      function_name            = string
      http_trigger_url         = string
      use_common_alert_schema  = optional(bool, true)
    })), [])

    tags = optional(map(string), {})
  }))
  default = {}
}

variable "metric_alerts" {
  description = "Map of metric alerts to create."
  type = map(object({
    description              = optional(string, "")
    enabled                  = optional(bool, true)
    auto_mitigate            = optional(bool, true)
    frequency                = optional(string, "PT5M")
    severity                 = optional(number, 3)
    window_size              = optional(string, "PT15M")
    target_resource_type     = optional(string, null)
    target_resource_location = optional(string, null)
    scopes                   = list(string)
    action_group_names       = optional(list(string), [])

    criteria = optional(list(object({
      metric_namespace = string
      metric_name      = string
      aggregation      = string
      operator         = string
      threshold        = number

      dimension = optional(list(object({
        name     = string
        operator = string
        values   = list(string)
      })), [])

      skip_metric_validation = optional(bool, false)
    })), [])

    dynamic_criteria = optional(list(object({
      metric_namespace  = string
      metric_name       = string
      aggregation       = string
      operator          = string
      alert_sensitivity = string

      dimension = optional(list(object({
        name     = string
        operator = string
        values   = list(string)
      })), [])

      evaluation_total_count   = optional(number, 4)
      evaluation_failure_count = optional(number, 4)
      skip_metric_validation   = optional(bool, false)
    })), [])

    tags = optional(map(string), {})
  }))
  default = {}
}

variable "log_alerts" {
  description = "Map of scheduled query rule alerts to create."
  type = map(object({
    description          = optional(string, "")
    enabled              = optional(bool, true)
    severity             = optional(number, 3)
    evaluation_frequency = optional(string, "PT5M")
    window_duration      = optional(string, "PT15M")
    scopes               = list(string)
    action_group_names   = optional(list(string), [])

    criteria = object({
      query                   = string
      time_aggregation_method = string
      operator                = string
      threshold               = number
      metric_measure_column   = optional(string, null)
      resource_id_column      = optional(string, null)

      dimension = optional(list(object({
        name     = string
        operator = string
        values   = list(string)
      })), [])

      failing_periods = optional(object({
        minimum_failing_periods_to_trigger_alert = number
        number_of_evaluation_periods             = number
      }), null)
    })

    auto_mitigation_enabled          = optional(bool, true)
    workspace_alerts_storage_enabled = optional(bool, false)
    skip_query_validation            = optional(bool, false)

    tags = optional(map(string), {})
  }))
  default = {}
}

variable "activity_log_alerts" {
  description = "Map of activity log alerts to create."
  type = map(object({
    description        = optional(string, "")
    enabled            = optional(bool, true)
    scopes             = list(string)
    action_group_names = optional(list(string), [])

    criteria = object({
      category       = string
      operation_name = optional(string, null)
      level          = optional(string, null)
      status         = optional(string, null)
      resource_type  = optional(string, null)
      resource_group = optional(string, null)
      resource_id    = optional(string, null)
      caller         = optional(string, null)

      resource_health = optional(object({
        current  = optional(list(string), null)
        previous = optional(list(string), null)
        reason   = optional(list(string), null)
      }), null)

      service_health = optional(object({
        events    = optional(list(string), null)
        locations = optional(list(string), null)
        services  = optional(list(string), null)
      }), null)
    })

    tags = optional(map(string), {})
  }))
  default = {}
}

variable "diagnostic_settings" {
  description = "Map of diagnostic settings to create."
  type = map(object({
    target_resource_id             = string
    log_analytics_workspace_id     = optional(string, null)
    storage_account_id             = optional(string, null)
    eventhub_authorization_rule_id = optional(string, null)
    eventhub_name                  = optional(string, null)
    log_analytics_destination_type = optional(string, null)
    partner_solution_id            = optional(string, null)

    enabled_logs = optional(list(object({
      category       = optional(string, null)
      category_group = optional(string, null)
    })), [])

    metrics = optional(list(object({
      category = string
      enabled  = optional(bool, true)
    })), [])
  }))
  default = {}
}

variable "data_collection_rules" {
  description = "Map of data collection rules to create."
  type = map(object({
    description = optional(string, "")
    kind        = optional(string, null)

    destinations = object({
      log_analytics = optional(list(object({
        workspace_resource_id = string
        name                  = string
      })), [])

      azure_monitor_metrics = optional(object({
        name = string
      }), null)
    })

    data_flows = list(object({
      streams      = list(string)
      destinations = list(string)
    }))

    data_sources = optional(object({
      performance_counters = optional(list(object({
        name                          = string
        streams                       = list(string)
        sampling_frequency_in_seconds = number
        counter_specifiers            = list(string)
      })), [])

      windows_event_logs = optional(list(object({
        name           = string
        streams        = list(string)
        x_path_queries = list(string)
      })), [])

      syslog = optional(list(object({
        name           = string
        streams        = list(string)
        facility_names = list(string)
        log_levels     = list(string)
      })), [])
    }), null)

    tags = optional(map(string), {})
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
