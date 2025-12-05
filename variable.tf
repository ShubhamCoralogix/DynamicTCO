variable "coralogix_api_key" {
  type        = string
  sensitive   = true
  description = "Your Coralogix Send-Your-Data API Key. Set via env var TF_VAR_coralogix_api_key"
  default = "<<USE_API_KEY>>"
}

variable "coralogix_domain" {
  type        = string
  description = "The domain for the API endpoints (e.g., coralogix.in for AP1)"
  default     = "coralogix.in"
}