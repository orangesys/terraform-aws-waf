variable "blacklist" {
  description = "blacklist"
  type        = list(any)
  default     = []
}

variable "env" {
  description = "enviornment variable"
  type        = string
  default     = "test"
}

variable "app_name" {
  description = "application name"
  type        = string
}

variable "is_cloudfront" {
  description = "whether create for cloudfront"
  type        = bool
  default     = false
}

variable "tags" {
  description = "A mapping of tags to assign to the WAF"
  type        = map(string)
  default     = {}
}
