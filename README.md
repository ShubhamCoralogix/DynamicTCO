# Dynamic TCO Automation for Coralogix
### Automated Log Quarantine & Recovery via Terraform, Alerts, and Webhooks

This Terraform module implements **Dynamic Total Cost Optimization (TCO)** on Coralogix by automatically **blocking noisy applications or subsystems** when their log usage spikes and **restoring normal logging** once the system recovers.

---

## Overview

Dynamic TCO helps intelligently control ingestion cost by adjusting log routing behavior automatically based on usage thresholds.

This module:
- Monitors per-**application** and per-**subsystem** usage independently.
- Supports **different thresholds** for each application and each subsystem.
- Enables TCO block policies when usage exceeds a defined per-entry limit.
- Restores all policies when global usage recovers below the total system limit.

---

## Repository Structure

```
├── applications.txt   ← Define apps/subsystems and their thresholds here
├── provider.tf
├── variables.tf
├── local.tf           ← Parses applications.txt, builds policy/alert/webhook locals
├── tcoPolicy.tf       ← Applies merged TCO policies to Coralogix
├── webhooks.tf        ← Enable/Disable webhooks for apps and subsystems
├── alerts.tf          ← High-usage (quarantine) + global recovery alerts
└── README.md
```

---

## Configuration: `applications.txt`

This is the **single source of truth** for all managed entries. Each line defines one application or subsystem along with its usage threshold.

### Format
```
type, name, limit
```

| Field  | Values              | Description                                      |
|--------|---------------------|--------------------------------------------------|
| `type` | `app` / `subsystem` | Whether this entry is application- or subsystem-scoped |
| `name` | string              | Exact name as it appears in Coralogix            |
| `limit`| number              | Usage threshold (in units) that triggers blocking |

Lines beginning with `#` are treated as comments and ignored.

### Example
```
# ── Application-wise entries ──────────────────────────────
app, shubham-eks-cluster-k8s-logs, 100
app, cx-server-payments, 10
app, cx-client-shopping-cart, 1
app, cloudwatch-ss-test, 1
app, aws, 2
app, cx-redis, 1

# ── Subsystem-wise entries ────────────────────────────────
subsystem, payment-service, 15
subsystem, cart-service, 5
subsystem, auth-service, 8
```

> **To add a new entry:** just append a line. Re-run `terraform apply` — all policies, alerts, and webhooks are created automatically.

---

## Key Concepts

### Application-wise Quarantine
Each `app` entry gets:
- A TCO block policy filtered on **application name** (disabled by default)
- An **enable** and **disable** webhook scoped to that application
- A **high-usage alert** using a PromQL query on `application_name`

### Subsystem-wise Quarantine
Each `subsystem` entry gets:
- A TCO block policy filtered on **subsystem name** (disabled by default)
- An **enable** and **disable** webhook scoped to that subsystem
- A **high-usage alert** using a PromQL query on `subsystem_name`

### Per-Entry Thresholds
Each application and subsystem has its **own independent threshold** defined in `applications.txt`. The global recovery threshold is automatically computed as the **sum of all app and subsystem limits**.

### System Recovery
A single global alert:
- Fires when total log usage drops below `sum(all app limits + all subsystem limits)`
- Disables **all** app and subsystem TCO block policies
- Restores normal logging across the board

---

## How It Works

### 1. Terraform Apply
- Reads `applications.txt`
- Parses entries into separate `app_limits` and `subsystem_limits` maps
- Creates TCO policies, high-usage alerts, and enable/disable webhooks for every entry
- Preserves any **unmanaged** policies already in Coralogix (they are never deleted or modified)
- Preserves the current `enabled/disabled` state of managed policies (so Terraform never undoes webhook-driven changes)

### 2. High Usage Event (Application or Subsystem)
- A per-entry alert fires when usage exceeds that entry's threshold
- The corresponding **enable webhook** activates the TCO block policy
- Logs from that specific application or subsystem are blocked

### 3. Recovery Event
- The global alert fires when **total** system usage falls below the combined threshold
- **All** disable webhooks fire (for every app and every subsystem)
- All TCO block policies are deactivated and logging resumes

---

## Resource Naming Convention

| Resource type    | App naming pattern                 | Subsystem naming pattern                       |
|------------------|------------------------------------|------------------------------------------------|
| TCO Policy       | `{name} - Alert Managed Webhook`   | `{name} - Subsystem Alert Managed Webhook`     |
| Enable Webhook   | `Enable-TCO-App-BlockLogs-{name}`  | `Enable-TCO-Subsystem-BlockLogs-{name}`        |
| Disable Webhook  | `Disable-TCO-App-AllowLogs-{name}` | `Disable-TCO-Subsystem-AllowLogs-{name}`       |
| High-Usage Alert | `{name}_App_HighUsage_BlockLogs`   | `{name}_Subsystem_HighUsage_BlockLogs`         |

---

## Security

Use an environment variable to supply the Coralogix API key — never commit it to source control:
```bash
export TF_VAR_coralogix_api_key="your-api-key-here"
```

---

## Testing

- Lower individual thresholds in `applications.txt` to simulate block events for specific apps or subsystems.
- Lower the total combined threshold to test the global recovery alert.
- Run `terraform plan` after changes to preview all resource modifications before applying.

---

## Summary

This module automates cost protection by:
- Supporting **both application-wise and subsystem-wise** TCO policies in a single config
- Allowing **independent thresholds** per application and per subsystem
- Auto-blocking noisy apps or subsystems when they breach their limit
- Auto-recovering all policies when the system returns to a healthy usage level
- Leveraging Terraform + Coralogix Alerts + Webhooks + TCO Policies