resource "coralogix_tco_policies_logs" "apps" {
  policies = local.tco_policies_logs

  # Vital: Prevents Terraform from reverting the "enabled" status 
  # when it runs, allowing the Alert/Webhook to control it.
  lifecycle {
    ignore_changes = [
      policies
    ]
  }
}