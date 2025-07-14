output "eks_private_endpoint" {
  description = "The private API server DNS (for editing kubeconfig)"
  value       = aws_eks_cluster.eks.endpoint
}