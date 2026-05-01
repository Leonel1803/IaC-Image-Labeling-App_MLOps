variable "table_name" {
  description = "DynamoDB table name for image and label index"
  type        = string
  default     = "ImageIndex"
}

variable "billing_mode" {
  description = "Billing mode for the DynamoDB table"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  type = map(string)
}
