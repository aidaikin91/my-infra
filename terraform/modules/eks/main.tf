module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.4"

  cluster_name = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id = var.vpc_id
  subnet_ids = var.subnet_ids

  cluster_endpoint_public_access = true

  # Minimal managed node group - just to get started
  # Karpenter will handle the rest
  eks_managed_node_groups = {
    initial = {
        instance_types = ["t3.medium"]
        min_size = 1
        max_size = 2
        desired_size = 2
    
   # Use spot instances to save money
   capacity_type = "SPOT"
    }
  }
   # Allow Karpenter to manage nodes
   node_security_group_tags = {
    "karpenter.sh/discovery" = var.cluster_name
   }

   tags = {
    Environment = var.environment
   }
}
