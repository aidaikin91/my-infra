locals {
  environment  = "dev"
  cluster_name = "weather-platform-dev"
  region       = "us-east-1"
}

# ---- VPC ----
module "vpc" {
  source = "../../modules/vpc"

  name            = "weather-platform-${local.environment}"
  cidr            = "10.0.0.0/16"
  azs             = ["${local.region}a", "${local.region}b"]
  private_subnets = ["10.0.10.0/24", "10.0.20.0/24"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  environment     = local.environment
}

# ---- EKS ----
module "eks" {
  source = "../../modules/eks"

  cluster_name = local.cluster_name
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnets
  environment  = local.environment
}

# ---- ECR Repositories ----
module "ecr_weather_api" {
  source = "../../modules/ecr"
  name   = "weather-api"
}

module "ecr_search_history" {
  source = "../../modules/ecr"
  name   = "search-history"
}

# ---- Namespaces ----
module "namespace_weather" {
  source    = "../../modules/namespace"
  name      = "weather-api"
  cpu_limit = "1"
  mem_limit = "1Gi"
}

module "namespace_search" {
  source    = "../../modules/namespace"
  name      = "search-history"
  cpu_limit = "1"
  mem_limit = "1Gi"
}

# ---- RDS (Weather API cache) ----
module "rds" {
  source = "../../modules/rds"

  name                      = "weather-db"
  vpc_id                    = module.vpc.vpc_id
  subnet_ids                = module.vpc.private_subnets
  allowed_security_group_id = module.eks.node_security_group_id
  environment               = local.environment
}

# ---- DynamoDB (Search History) ----
module "dynamodb" {
  source = "../../modules/dynamodb"

  table_name  = "search-history"
  hash_key    = "userId"
  range_key   = "searchedAt"
  environment = local.environment
}

# ---- Secrets ----
module "weather_api_secret" {
  source = "../../modules/secrets"

  name = "weather-api/db"
  secret_values = {
    host     = module.rds.endpoint
    port     = "5432"
    username = module.rds.username
    password = module.rds.password
    dbname   = module.rds.db_name
  }
}

module "openweather_secret" {
  source = "../../modules/secrets"

  name = "weather-api/openweather"
  secret_values = {
    api_key = var.openweather_api_key
  }
}

# ---- IRSA for Weather API ----
module "irsa_weather_api" {
  source = "../../modules/irsa"

  name              = "weather-api"
  namespace         = "weather-api"
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider     = module.eks.oidc_provider

  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = [
          module.weather_api_secret.secret_arn,
          module.openweather_secret.secret_arn
        ]
      }
    ]
  })
}

# ---- IRSA for Search History ----
module "irsa_search_history" {
  source = "../../modules/irsa"

  name              = "search-history"
  namespace         = "search-history"
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider     = module.eks.oidc_provider

  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query"
        ]
        Resource = [module.dynamodb.table_arn]
      }
    ]
  })
}

# ---- NGINX Ingress Controller ----
resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"
  create_namespace = true

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }
}

# ---- Prometheus + Grafana ----
resource "helm_release" "monitoring" {
  name       = "monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "monitoring"
  create_namespace = true

  set {
    name  = "grafana.adminPassword"
    value = "admin123"  # change this in prod!
  }
}

# ---- ArgoCD ----
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"
  create_namespace = true

  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }
}