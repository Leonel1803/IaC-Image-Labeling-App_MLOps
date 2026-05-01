variable "name_prefix" {
  description = "Prefix for IAM resources"
  type        = string
}

variable "s3_bucket_arn" {
  description = "S3 bucket ARN"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "DynamoDB table ARN"
  type        = string
}

variable "tags" {
  type = map(string)
}
