resource "kubernetes_namespace" "this" {
  metadata {
    name = var.name
  }
}

resource "kubernetes_resource_quota" "this" {
  metadata {
    name      = "${var.name}-quota"
    namespace = var.name
  }
  spec {
    hard = {
      "limits.cpu"    = var.cpu_limit
      "limits.memory" = var.mem_limit
    }
  }
  depends_on = [kubernetes_namespace.this]
}

resource "kubernetes_limit_range" "this" {
  metadata {
    name      = "${var.name}-limits"
    namespace = var.name
  }
  spec {
    limit {
      type = "Container"
      default = {
        cpu    = "250m"
        memory = "256Mi"
      }
      default_request = {
        cpu    = "100m"
        memory = "128Mi"
      }
    }
  }
  depends_on = [kubernetes_namespace.this]
}