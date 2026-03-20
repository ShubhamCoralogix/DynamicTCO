# Dynamic TCO Automation for Coralogix
### Automated Log Quarantine & Recovery via Terraform, Alerts, and Webhooks

This Terraform module implements **Dynamic Total Cost Optimization (TCO)** on Coralogix by automatically **blocking noisy applications** when their log usage spikes and **restoring normal logging** once the system recovers.

## Overview

Dynamic TCO helps intelligently control ingestion cost by adjusting log routing behavior automatically based on usage thresholds.

This module:
- Monitors per-application usage.
- Enables TCO block policies when usage spikes.
- Restores policies when global usage recovers.

## Repository Structure
```
├── applications.txt
├── provider.tf
├── variables.tf
├── local.tf
├── tcoPolicy.tf
├── webhooks.tf
├── alert.tf
└── README.md
```

## Key Concepts

### Application Quarantine
Each application gets:
- A TCO block policy (disabled by default)
- Enable/Disable webhooks
- A high-usage alert

### System Recovery
A global alert:
- Detects low usage
- Disables all TCO policies
- Restores normal logging

## How It Works

### Terraform Apply
- Reads applications.txt
- Creates TCO policies, alerts, and webhooks

### High Usage Event
- App alert fires
- Enable webhook activates TCO block policy
- Logs from that app are blocked

### Recovery Event
- Global alert fires
- Disable webhooks deactivate all TCO policies
- Logging resumes

## Security
Use environment variables to supply the Coralogix API key:
```
export TF_VAR_coralogix_api_key="xxxx"
```

## Testing
- Lower thresholds to simulate block/unblock events.

## Summary
This module automates cost protection by:
- Auto-blocking noisy apps
- Auto-recovering to normal state
- Leveraging Terraform + Coralogix alerts + webhooks + TCO policies
