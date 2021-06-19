variable "lambda_name" {
  description = "PHP daily lambda resource name"
  type        = string
  default     = "lambda-phpdaily"
}

variable "lambda_handler" {
  description = "PHP daily lambda handler"
  type        = string
  default     = "lambda_function.lambda_handler"
}

variable "lambda_timeout" {
  description = "PHP daily lambda timeout"
  type        = number
  default     = 60
}

variable "lambda_schedule" {
  description = "PHP daily lambda event rule schedule"
  type        = string
  default     = "rate(23 hours)"
}
