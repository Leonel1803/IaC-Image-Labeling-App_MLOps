variable "function_name" {
  description = "Lambda function name"
  type        = string
}

variable "lambda_role_arn" {
  description = "IAM role ARN for Lambda"
  type        = string
}

variable "source_path" {
  description = "Path to Lambda deployment package zip"
  type        = string
}

variable "handler" {
  description = "Lambda handler"
  type        = string
  default     = "handler.lambda_handler"
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.12"
}

variable "timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "Lambda memory in MB"
  type        = number
  default     = 256
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name"
  type        = string
}

variable "confidence_threshold" {
  description = "Rekognition confidence threshold"
  type        = number
  default     = 90
}

variable "source_bucket_arn" {
  description = "S3 bucket ARN allowed to invoke Lambda"
  type        = string
  default     = null
}

variable "allow_s3_invoke" {
  description = "Whether to create S3 invoke permission"
  type        = bool
  default     = false
}

variable "environment_variables" {
  description = "Additional Lambda environment variables"
  type        = map(string)
  default     = {}
}
