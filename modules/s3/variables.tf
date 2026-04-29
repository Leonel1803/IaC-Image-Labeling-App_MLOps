variable "bucket_name" {
    type = string
}

variable "environment" {
    type = string
}

variable "transition_days" {
    type = number
    default = 30
}