# ------------------------------------------------------------
# 🔤 Project Name
# ------------------------------------------------------------
variable "project_name" {
  # Name prefix applied to all resources
  description = "Name prefix for all resources"
  type        = string

  # Enforce lowercase letters, numbers, and hyphens
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

# ------------------------------------------------------------
# 🌱 Environment (dev / test / prod)
# ------------------------------------------------------------
variable "environment" {
  # Environment identifier for resource segregation
  description = "Environment name (dev, test, prod)"
  type        = string

  # Restrict allowed values
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be one of: dev, test, prod."
  }
}

# ------------------------------------------------------------
# 🤖 AWS Bedrock Model ID
# ------------------------------------------------------------
variable "bedrock_model_id" {
  # Default model used for inference
  description = "Bedrock model ID"
  type        = string
  default     = "amazon.nova-micro-v1:0"
}

# ------------------------------------------------------------
# ⏱️ Lambda Timeout (seconds)
# ------------------------------------------------------------
variable "lambda_timeout" {
  # Maximum execution time for the Lambda function
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 60
}

# ------------------------------------------------------------
# 🚦 API Gateway Throttle: Burst Limit
# ------------------------------------------------------------
variable "api_throttle_burst_limit" {
  # Maximum burst of requests API Gateway will allow instantly
  description = "API Gateway throttle burst limit"
  type        = number
  default     = 10
}

# ------------------------------------------------------------
# 🚥 API Gateway Throttle: Rate Limit
# ------------------------------------------------------------
variable "api_throttle_rate_limit" {
  # Sustained limit on requests per second
  description = "API Gateway throttle rate limit"
  type        = number
  default     = 5
}

# ------------------------------------------------------------
# 🌐 Custom Domain Support
# ------------------------------------------------------------
variable "use_custom_domain" {
  # Whether to attach a custom domain to CloudFront
  description = "Attach a custom domain to CloudFront"
  type        = bool
  default     = false
}

# ------------------------------------------------------------
# 🏷️ Root Domain (Optional)
# ------------------------------------------------------------
variable "root_domain" {
  # Apex domain name for optional custom domain setup
  description = "Apex domain name, e.g. mydomain.com"
  type        = string
  default     = ""
}
