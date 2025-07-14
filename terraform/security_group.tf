# -------------------------------------------------------------------
# LB Security Group
# -------------------------------------------------------------------
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP inbound to ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -------------------------------------------------------------------
# EKS Control‑Plane SG (static rules)
# -------------------------------------------------------------------
resource "aws_security_group" "eks_cluster_sg" {
  name        = "eks-cluster-sg"
  description = "Control plane communication"
  vpc_id      = module.vpc.vpc_id

  # API access (443) from Internet
  ingress {
    description = "Allow API access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -------------------------------------------------------------------
# EKS Node SG (static rules)
# -------------------------------------------------------------------
resource "aws_security_group" "eks_node_sg" {
  name        = "eks-node-sg"
  description = "Worker node communication"
  vpc_id      = module.vpc.vpc_id

  # Nodes need outbound to pull images, talk to AWS, etc.
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -------------------------------------------------------------------
# Now the cross–SG rules (no cycles)
# -------------------------------------------------------------------

# Nodes to Control‑Plane (high ports)
resource "aws_security_group_rule" "node_to_cluster" {
  description              = "Nodes to Control Plane"
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster_sg.id
  source_security_group_id = aws_security_group.eks_node_sg.id
}

# Control‑Plane to Nodes (443)
resource "aws_security_group_rule" "cluster_to_node" {
  description              = "Control Plane to Nodes"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_node_sg.id
  source_security_group_id = aws_security_group.eks_cluster_sg.id
}

# ALB to Nodes (80)
resource "aws_security_group_rule" "alb_to_node" {
  description              = "ALB to Nodes"
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_node_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
}
