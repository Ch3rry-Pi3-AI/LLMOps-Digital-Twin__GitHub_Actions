# ------------------------------------------------------------
# 🌐 API Gateway URL
# ------------------------------------------------------------
output "api_gateway_url" {
  # URL of the deployed API Gateway endpoint
  description = "URL of the API Gateway"
  value       = aws_apigatewayv2_api.main.api_endpoint
}

# ------------------------------------------------------------
# ☁️ CloudFront Distribution URL
# ------------------------------------------------------------
output "cloudfront_url" {
  # Public HTTPS URL served by CloudFront
  description = "URL of the CloudFront distribution"
  value       = "https://${aws_cloudfront_distribution.main.domain_name}"
}

# ------------------------------------------------------------
# 📦 S3 Bucket — Frontend Hosting
# ------------------------------------------------------------
output "s3_frontend_bucket" {
  # Name of the bucket hosting the static frontend site
  description = "Name of the S3 bucket for frontend"
  value       = aws_s3_bucket.frontend.id
}

# ------------------------------------------------------------
# 🗄️ S3 Bucket — Conversation Memory Storage
# ------------------------------------------------------------
output "s3_memory_bucket" {
  # Name of the memory storage bucket
  description = "Name of the S3 bucket for memory storage"
  value       = aws_s3_bucket.memory.id
}

# ------------------------------------------------------------
# 🤖 Lambda Function Name
# ------------------------------------------------------------
output "lambda_function_name" {
  # Name of the deployed Lambda function
  description = "Name of the Lambda function"
  value       = aws_lambda_function.api.function_name
}

# ------------------------------------------------------------
# 🌍 Custom Domain (Optional)
# ------------------------------------------------------------
output "custom_domain_url" {
  # Root URL if a custom domain is enabled, otherwise empty
  description = "Root URL of the production site"
  value       = var.use_custom_domain ? "https://${var.root_domain}" : ""
}
