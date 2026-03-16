resource "coralogix_tco_policies_logs" "apps" {
  policies = local.tco_policies_logs
  # No ignore_changes needed: the merge logic in local.tf already preserves
  # existing unmanaged policies and the current enabled/disabled state of
  # managed policies, so Terraform will never revert webhook-driven changes.
}
