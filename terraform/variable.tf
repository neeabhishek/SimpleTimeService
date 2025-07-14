variable "access_key" {
    description = "Access key of IAM user"
    type = string
    default = "" ###Use your IAM user access keys.
}
variable "secret_key" {
    description = "Secret key of IAM user"
    type = string
    default = "" ###Use your IAM user secret keys.
}
variable "region" {
    description = "Region where the resources needs to deployed"
    type = string
    default = "" ###Use the region of your choice.
}