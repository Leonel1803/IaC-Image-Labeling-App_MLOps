variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "bucket_name" {
  type = string
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "project_name" {
  type    = string
  default = "image-labeling"
}

variable "transition_days" {
  type    = number
  default = 30
}

variable "dynamodb_table_name" {
  type    = string
  default = "ImageIndex"
}

variable "lambda_source_path" {
  type    = string
  default = "lambda/processor_function.zip"
}

variable "lambda_handler" {
  type    = string
  default = "handler.lambda_handler"
}

variable "lambda_runtime" {
  type    = string
  default = "python3.12"
}

variable "lambda_timeout" {
  type    = number
  default = 30
}

variable "lambda_memory_size" {
  type    = number
  default = 256
}

variable "confidence_threshold" {
  type    = number
  default = 90
}

variable "api_lambda_source_path" {
  type    = string
  default = "lambda/api_function.zip"
}

