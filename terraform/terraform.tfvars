# ------------------------------------------------------------
# 🔤 Core Project Settings
# ------------------------------------------------------------
# Name prefix applied to all resources (used in tags and naming)
project_name = "twin"

# Environment identifier (dev / test / prod)
environment = "dev"

# ------------------------------------------------------------
# 🤖 Model & Lambda Configuration
# ------------------------------------------------------------
# Default AWS Bedrock model used for the Digital Twin
bedrock_model_id = "amazon.nova-micro-v1:0"

# Maximum Lambda execution time in seconds
lambda_timeout = 60

# ------------------------------------------------------------
# 🚦 API Gateway Throttling
# ------------------------------------------------------------
# Maximum burst of requests that API Gateway allows instantly
api_throttle_burst_limit = 10

# Sustained request rate per second
api_throttle_rate_limit = 5

# ------------------------------------------------------------
# 🌐 Custom Domain Settings
# ------------------------------------------------------------
# Whether to use a custom domain with CloudFront and Route53
use_custom_domain = false

# Root (apex) domain for production, e.g. "mydomain.com"
# Leave empty when use_custom_domain = false
root_domain = ""
