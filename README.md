
# Dynamic TCO Automation (Application-Level Thresholds)

This module automates **Dynamic TCO** for Coralogix by enabling or disabling **application-specific TCO policies** based on usage thresholds defined in a simple configuration file.

## Features
- Per-application thresholds
- Automatic quarantine of noisy apps
- Dynamic recovery when usage stabilizes
- Simple CSV-style configuration in `applications.txt`

## applications.txt Format
Each line should contain:
```
application_name, threshold_value
```

Example:
```
shubham-eks-cluster-k8s-logs, 100
cx-server-payments, 10
cx-client-shopping-cart, 1
cloudwatch-ss-test, 1
aws, 2
cx-redis, 1
```

## Repository Structure
```
├── applications.txt
├── provider.tf
├── variables.tf
├── local.tf
├── tcoPolicy.tf
├── webhooks.tf
├── alerts.tf
└── README.md
```

## Workflow Overview

### 1️⃣ User Defines Applications & Thresholds
Each application and its corresponding threshold is read by Terraform from `applications.txt`.

### 2️⃣ Terraform Generates TCO Policies
A TCO block policy is created per application, initially disabled.

### 3️⃣ Terraform Generates Webhooks
- Enable webhook → activates TCO block
- Disable webhook → restores logging

### 4️⃣ Terraform Generates Alerts
Each app gets its own alert triggered when its threshold is crossed.

### 5️⃣ Global Recovery Logic
A global alert disables all policies when system-wide usage stabilizes.

## Running Terraform
```
terraform init
terraform validate
terraform apply
```

## Authentication
```
export TF_VAR_coralogix_api_key="YOUR_API_KEY"
```

## Summary
This module provides a flexible, threshold-based Dynamic TCO solution for Coralogix, making log ingestion safer, cost-controlled, and automated.
