resource "aws_iam_role" "this" {
    name = "${var.name}-irsa"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow"
            Principal = {
                Federated = var.oidc_provider_arn
            }
            Action = "sts:AssumeRoleWithWebIdentity"
            Condition = {
              StringEquals = {
                "${var.oidc_provider}:sub" = "system:serviceaccount:${var.namespace}:${var.name}"
                "${var.oidc_provider}:aud" = "sts.amazonaws.com"
            }
          }
        }]
    })
}

resource "aws_iam_role_policy" "this" {
    name = "${var.name}-policy"
    role = aws_iam_role.this.id
    policy = var.policy_json
}

resource "kubernetes_service_account" "this" {
    metadata {
        name = var.name
        namespace = var.namespace
        annotations = {
            "eks.amazonaws.com/role-arn" = aws_iam_role.this.arn
        }
    }
}