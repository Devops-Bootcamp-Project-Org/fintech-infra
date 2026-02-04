##############################################
# EKS Module
##############################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.32"

  enable_cluster_creator_admin_permissions = true
  cluster_endpoint_public_access           = true

  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnets
  control_plane_subnet_ids = var.private_subnets

  cluster_additional_security_group_ids = var.security_group_ids

  create_cloudwatch_log_group = true
  cluster_enabled_log_types   = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  bootstrap_self_managed_addons = true

  cluster_addons = {
    vpc-cni = { most_recent = true, service_account_role_arn = var.cni_role_arn, resolve_conflicts = "OVERWRITE" }
    coredns = { most_recent = true, resolve_conflicts = "OVERWRITE" }
    kube-proxy = { most_recent = true, resolve_conflicts = "OVERWRITE" }
    eks-pod-identity-agent = { most_recent = true, resolve_conflicts = "OVERWRITE" }
    aws-ebs-csi-driver = { most_recent = true, resolve_conflicts = "OVERWRITE" }
  }

  eks_managed_node_group_defaults = {
    ami_type       = "AL2023_x86_64_STANDARD"
    instance_types = ["t3.medium"]
    min_size       = 3
    max_size       = 5
    desired_size   = 3
    iam_role_additional_policies = {
      AmazonEKSWorkerNodePolicy          = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
      AmazonEKS_CNI_Policy               = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
      AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      AmazonEC2FullAccess                = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
    }
  }

  eks_managed_node_groups = {
    eks-node-group-1 = {}
  }

  access_entries = var.access_entries

  tags = local.common_tags
}

##############################################
# EKS Data + Auth (waits for cluster)
##############################################

data "aws_eks_cluster" "main" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "main" {
  name = module.eks.cluster_name
}

data "aws_caller_identity" "current" {}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

##############################################
# Kubernetes Namespaces
##############################################

resource "kubernetes_namespace" "fintech" {
  metadata {
    name = "fintech"
    labels = { app = "fintech" }
    annotations = { name = "fintech" }
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = { app = "monitoring" }
    annotations = { name = "monitoring" }
  }
}

resource "kubernetes_namespace" "fintech_dev" {
  metadata {
    name = "fintech-dev"
    labels = { app = "fintech-dev" }
    annotations = { name = "fintech-dev" }
  }
}

##############################################
# Kubernetes RBAC
##############################################

resource "kubernetes_cluster_role_binding" "platform_admins_binding" {
  metadata { name = "platform-admins-binding" }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "Group"
    name      = "platform-admins"
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_cluster_role_binding" "eks_admins_binding" {
  metadata { name = "eks-admins-binding" }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "Group"
    name      = "eks-admins"
    api_group = "rbac.authorization.k8s.io"
  }
}
