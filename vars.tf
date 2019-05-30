variable "region" {
    type = "string"
    default = "eu-west-1"
}

variable "profile" {
    type = "string"
}

variable "build_bucket_name" {
    type = "string"
}

variable "enable_scheduled_builds" {
    type = "string"
    default = "1"
}
