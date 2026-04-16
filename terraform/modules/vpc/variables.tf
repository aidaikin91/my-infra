variable "name" {
    description = "VPC name"
    type = string
}

variable "cidr" {
    description = "VPC CIDR block"
    type        = string
    default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones"
  type        = list(string)
}

variable "private_subnets" {
  description = "Private subnet CIDRs"
  type        = list(string)
}

variable "public_subnets" {
  description = "Public subnet CIDRs"
  type        = list(string)
}

variable "environment" {
  description = "Environment name"
  type        = string
}