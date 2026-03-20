# =============================================================
# 1. PER-APP ALERTS: QUARANTINE LOGIC
#    Trigger : App usage > per-app limit
#    Action  : Enable TCO block policy for THAT app only
# =============================================================
resource "coralogix_alert" "app_high_usage_block" {
  for_each = toset(local.application_names)

  name        = "${each.value}_App_HighUsage_BlockLogs"
  description = "App '${each.value}' usage > ${local.app_limits[each.value]}. Enables TCO Policy to BLOCK logs."
  enabled     = true
  priority    = "P1"

  labels = {
    policy_scope     = "application"
    application_name = each.value
    alert_type       = "tco_quarantine"
  }

  notification_group = {
    webhooks_settings = [{
      retriggering_period = {
        minutes = 60
      }
      notify_on      = "Triggered Only"
      integration_id = coralogix_webhook.enable_tco_policy_app[each.value].external_id
    }]
  }

  type_definition = {
    metric_threshold = {
      metric_filter = {
        promql = "sum(cx_data_usage_units{application_name=~\"${each.value}\", pillar=\"logs\"})"
      }
      missing_values = {
        min_non_null_values_pct = 100
      }
      rules = [
        {
          condition = {
            condition_type = "MORE_THAN"
            threshold      = local.app_limits[each.value]
            of_the_last    = "5m"
            for_over_pct   = 100
          }
          override = {
            priority = "P1"
          }
        }
      ]
    }
  }
}

# =============================================================
# 2. PER-SUBSYSTEM ALERTS: QUARANTINE LOGIC
#    Trigger : Subsystem usage > per-subsystem limit
#    Action  : Enable TCO block policy for THAT subsystem only
# =============================================================
resource "coralogix_alert" "subsystem_high_usage_block" {
  for_each = toset(local.subsystem_names)

  name        = "${each.value}_Subsystem_HighUsage_BlockLogs"
  description = "Subsystem '${each.value}' usage > ${local.subsystem_limits[each.value]}. Enables TCO Policy to BLOCK logs."
  enabled     = true
  priority    = "P1"

  labels = {
    policy_scope    = "subsystem"
    subsystem_name  = each.value
    alert_type      = "tco_quarantine"
  }

  notification_group = {
    webhooks_settings = [{
      retriggering_period = {
        minutes = 60
      }
      notify_on      = "Triggered Only"
      integration_id = coralogix_webhook.enable_tco_policy_subsystem[each.value].external_id
    }]
  }

  type_definition = {
    metric_threshold = {
      metric_filter = {
        promql = "sum(cx_data_usage_units{subsystem_name=~\"${each.value}\", pillar=\"logs\"})"
      }
      missing_values = {
        min_non_null_values_pct = 100
      }
      rules = [
        {
          condition = {
            condition_type = "MORE_THAN"
            threshold      = local.subsystem_limits[each.value]
            of_the_last    = "5m"
            for_over_pct   = 100
          }
          override = {
            priority = "P1"
          }
        }
      ]
    }
  }
}

# =============================================================
# 3. GLOBAL ALERT: RECOVERY LOGIC
#    Trigger : Total usage (apps + subsystems) < total_system_limit
#    Action  : Disable ALL app and subsystem TCO block policies
# =============================================================
resource "coralogix_alert" "global_low_usage_recovery" {
  name        = "Global_System_Recovery_UnblockAll"
  description = "Total usage < ${local.total_system_limit}. Disables ALL TCO Policies (apps + subsystems)."
  enabled     = true
  priority    = "P2"

  labels = {
    alert_type = "tco_recovery"
  }

  notification_group = {
    # Fire every disable webhook: app policies first, then subsystem policies
    webhooks_settings = concat(
      [
        for app in local.application_names : {
          retriggering_period = {
            minutes = 1440
          }
          notify_on      = "Triggered Only"
          integration_id = coralogix_webhook.disable_tco_policy_app[app].external_id
        }
      ],
      [
        for sub in local.subsystem_names : {
          retriggering_period = {
            minutes = 1440
          }
          notify_on      = "Triggered Only"
          integration_id = coralogix_webhook.disable_tco_policy_subsystem[sub].external_id
        }
      ]
    )
  }

  type_definition = {
    metric_threshold = {
      metric_filter = {
        promql = "sum(cx_data_usage_units{pillar=\"logs\"})"
      }
      undetected_values_management = {
        trigger_on_undetected_values = true
        auto_retire_ratio            = "Never"
      }
      missing_values = {
        min_non_null_values_pct = 0
      }
      rules = [
        {
          condition = {
            condition_type = "LESS_THAN"
            threshold      = local.total_system_limit
            of_the_last    = "10m"
            for_over_pct   = 100
          }
          override = {
            priority = "P3"
          }
        }
      ]
    }
  }
}