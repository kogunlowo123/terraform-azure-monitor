# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-01-15

### Added

- Log Analytics workspace with configurable SKU, retention, and daily quota
- Log Analytics solution deployment (SecurityInsights, ContainerInsights, etc.)
- Application Insights with workspace-based integration
- Action groups with email, SMS, webhook, push, ARM role, Logic App, and Azure Function receivers
- Metric alerts with static and dynamic criteria, dimensions, and auto-mitigation
- Scheduled query rule alerts (log alerts v2) with failing periods
- Activity log alerts for service health, resource health, and administrative operations
- Diagnostic settings with log categories, category groups, and metrics
- Data collection rules for performance counters, Windows Event Logs, and Syslog
- Comprehensive input validation
- Basic, advanced, and complete usage examples
- MIT License
