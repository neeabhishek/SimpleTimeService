data "aws_eks_cluster" "get" {
  name = aws_eks_cluster.eks.name
  depends_on = [aws_eks_cluster.eks]
}

data "aws_security_group" "cluster_sg" {
  id = data.aws_eks_cluster.get.vpc_config[0].cluster_security_group_id
}

resource "aws_security_group" "worker_sg" {
  name        = "${var.cluster_name}-worker-sg"
  description = "Worker nodes SG"
  vpc_id      = module.vpc.vpc_id

  egress {
    description     = "Allow to EKS control plane"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [data.aws_security_group.cluster_sg.id]
  }
}

resource "aws_security_group_rule" "cp_to_worker" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = data.aws_security_group.cluster_sg.id
  source_security_group_id = aws_security_group.worker_sg.id
}