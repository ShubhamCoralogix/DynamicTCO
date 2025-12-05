# ---------------------------------------------------------
# 1. PER-APP ALERTS: QUARANTINE LOGIC
# Trigger: High Usage (> 30)
# Action: Enable Policy (Block Logs) for THAT app only
# ---------------------------------------------------------
resource "coralogix_alert" "app_high_usage_block" {
  for_each    = toset(local.application_names)
  name        = "${each.value}_HighUsage_BlockLogs"
  description = "Usage > 30. Enables TCO Policy to BLOCK logs."
  enabled     = true
  priority    = "P1"

  labels = {
    application_name = each.value
    alert_type       = "tco_quarantine"
  }

  notification_group = {
    webhooks_settings = [{
      retriggering_period = {
        minutes = 60
      }
      notify_on      = "Triggered Only"
      integration_id = coralogix_webhook.enable_tco_policy[each.value].external_id
      #recipients     = []
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
            threshold      = 30
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

# ---------------------------------------------------------
# 2. GLOBAL ALERT: RECOVERY LOGIC
# Trigger: Total Usage < 50
# Action: Disable Policy (Allow Logs) for ALL apps
# ---------------------------------------------------------
resource "coralogix_alert" "global_low_usage_recovery" {
  name        = "Global_System_Recovery_UnblockAll"
  description = "Total Usage < 50. Disables TCO Policy (Unblocks logs) for ALL apps."
  enabled     = true
  priority    = "P2"

  labels = {
    alert_type = "tco_recovery"
  }

  # DYNAMIC LOGIC:
  # Using a 'for' loop inside the list to attach EVERY application's disable webhook
  notification_group = {
    webhooks_settings = [
      for app in local.application_names : {
        retriggering_period = {
          minutes = 1440 # Run once a day max if it stays low
        }
        notify_on      = "Triggered Only"
        integration_id = coralogix_webhook.disable_tco_policy[app].external_id
        #recipients     = []
      }
    ]
  }

  type_definition = {
    metric_threshold = {
      metric_filter = {
        # Global query for total units
        promql = "sum(cx_data_usage_units{pillar=\"logs\"})"
      }
      # Recovery Logic: No data usually means 0 usage, so we trigger on undetected
      undetected_values_management = {
        trigger_on_undetected_values = true
        auto_retire_ratio            = "Never"
      }
      missing_values = {
        min_non_null_values_pct = 0 # Allow missing values for global calculation stability
      }
      rules = [
        {
          condition = {
            condition_type = "LESS_THAN"
            threshold      = 30
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