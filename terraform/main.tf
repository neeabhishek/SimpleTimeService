provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

##############################################################################
# VPC Creation for EKS (Note: Atleast two AZs needs to be provided for EKS)
##############################################################################

data "aws_availability_zones" "az" {}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "eks-vpc"
  cidr = var.cidr

  azs             = data.aws_availability_zones.az.names
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform = "true"
    Environment = "dev"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                   = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}"   = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }

}

##############################################################################
# AWS IAM Role and Policy Attachment for EKS Cluster and Nodes
##############################################################################

resource "aws_iam_role" "cluster" {
    name = var.cluster_name

    assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = ["sts:AssumeRole","sts:TagSession"]
    }]
  })
}

resource "aws_iam_role" "nodes" {
    name = "eks-node-role"
    
    assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = ["sts:AssumeRole"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_EKSWorkerNodePolicy" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node-AmazonEC2ContainerRegistryPullOnly" {
    role = aws_iam_role.nodes.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSClusterPolicy" {
    role = aws_iam_role.cluster.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSComputePolicy" {
    role = aws_iam_role.cluster.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSComputePolicy"
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSBlockStoragePolicy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSBlockStoragePolicy"
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSLoadBalancingPolicy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy"
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSNetworkingPolicy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSNetworkingPolicy"
}

##############################################################################
# EKS Provisiong
##############################################################################

resource "aws_eks_cluster" "eks" {
    name = var.cluster_name
    version = "1.31"
    role_arn = aws_iam_role.cluster.arn

    access_config {
      authentication_mode = "API"
    }

    bootstrap_self_managed_addons = false

    kubernetes_network_config {
      elastic_load_balancing {
        enabled = true
      }
    }

    compute_config {
    enabled       = true
    node_pools    = ["general-purpose","system"]
    node_role_arn = aws_iam_role.nodes.arn
  }

    storage_config {
      block_storage {
        enabled = true
      }
    }
    
    vpc_config {
      subnet_ids = module.vpc.private_subnets
      endpoint_public_access = true
      endpoint_private_access = true
      public_access_cidrs = ["0.0.0.0/0"]
    }

    depends_on = [
        module.vpc,
        aws_iam_role_policy_attachment.cluster-AmazonEKSClusterPolicy,
        aws_iam_role_policy_attachment.cluster-AmazonEKSComputePolicy,
        aws_iam_role_policy_attachment.cluster-AmazonEKSBlockStoragePolicy,
        aws_iam_role_policy_attachment.cluster-AmazonEKSLoadBalancingPolicy,
        aws_iam_role_policy_attachment.cluster-AmazonEKSNetworkingPolicy
        
    ] 

    tags = {
        Environment = "dev"
        Terraform = "true"
    }
}


##############################################################################
# EKS Cluster Access 
##############################################################################
locals {
  eks_policies = [
    "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAutoNodePolicy",
    "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy",
    "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy",
    "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy",
    "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy",
    "arn:aws:eks::aws:cluster-access-policy/AmazonEKSLoadBalancingClusterPolicy"
  ]
}


data "aws_iam_user" "my_eks_user" {
  user_name = var.iam_user 
}

resource "aws_eks_access_entry" "iam_user_access" {
  cluster_name = aws_eks_cluster.eks.name
  principal_arn = data.aws_iam_user.my_eks_user.arn
  type = "STANDARD"
  depends_on = [ aws_eks_cluster.eks, data.aws_iam_user.my_eks_user ]
}

resource "aws_eks_access_policy_association" "iam_user_policy" {
  for_each = toset(local.eks_policies)
  cluster_name = aws_eks_access_entry.iam_user_access.cluster_name
  principal_arn = aws_eks_access_entry.iam_user_access.principal_arn
  policy_arn = each.value
  access_scope {
    type = "cluster" 
  }

  depends_on = [ aws_eks_access_entry.iam_user_access ]
}
