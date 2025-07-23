variable "cidr" {
    type = string
    default = "10.0.0.0/16"
    description = "CIDR Block for EKS-VPC"
}

variable "region" {
    type = string
    default = ""
    description = "Region where the N/W component and EKS will be provisioned"  
}

variable "access_key" {
    type = string
    default = ""
    description = "IAM user access keys"
}

variable "secret_key" {
    type = string
    default = ""
    description = "IAM user secret keys"
}

variable "cluster_name" {
    type = string
    default = "dev-eks"
}
variable "iam_user" {
    type = string
    default = "eks-admin"
}
