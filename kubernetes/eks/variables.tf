variable "project" {
  type        = string
  description = "Application Name"
}

variable "region" {
  type        = string
  default = "us-east-1"
}

variable "zones" {
  type        = list(string)
  default = ["us-east-1a", "us-east-1b"]
}