variable "name" {
    type = string
}

variable "cpu_limit" {
    type = string
    default = "2"
}

variable "mem_limit" {
    type = string
    default = "4Gi"
}
