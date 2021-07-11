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

variable "twitter_consumer_key" {
  description = "API key that a service provider to identify the consumer"
  type        = string
}

variable "twitter_consumer_secret" {
  description = "Secret that is used to request access  to a user's resources from a service provider"
  type        = string
}

variable "twitter_access_token" {
  description = "Token that defines the access privileges of the consumer over a particular user's resources"
  type        = string
}

variable "twitter_access_secret" {
  description = "Secret that is used with access token to access user's resources"
  type        = string
}
