# Grafana Dashboard Infrastructure

# Data sources for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# Data source for current AWS region
data "aws_region" "current" {}

# resource "aws_networkflowmonitor_monitor" "this" {
#   monitor_name = "eks-network-flow-monitor"
#   scope_arn = aws_networkflowmonitor_scope.this.scope_arn

#   local_resource {
#     type = "AWS::EKS::Cluster"
#     identifier = module.eks_cluster.arn
#   }
#   remote_resource {
#     type = "AWS::EC2::VPC"
#     identifier = module.vpc_core.id
#   }
# }

# resource "aws_networkflowmonitor_scope" "this" {
#   target {
#     region = "ap-northeast-2"
#     target_identifier {
#       target_type = "ACCOUNT"
#       target_id {
#         account_id = data.aws_caller_identity.current.account_id
#       }
#     }
#   }
# }

# resource "aws_iam_role" "eks_monitor_irsa" {
#   name = "eks-network-flow-monitor-role"
#   assume_role_policy = jsonencode({
#     "Version" : "2012-10-17",
#     "Statement" : [
#       {
#         "Effect" : "Allow",
#         "Principal" : {
#           "Federated" : var.oidc_arn
#         },
#         "Action" : "sts:AssumeRoleWithWebIdentity",
#         "Condition" : {
#           "StringEquals" : {
#             "${var.oidc_endpoint}:sub" : "system:serviceaccount:monitoring:grafana-operator"
#           }
#         }
#       }
#     ]
#   })
# }

# resource "kubernetes_service_account" "eks_monitor_sa" {
#   metadata {
#     name = "grafana-operator"
#     namespace = "monitoring"
#     annotations = {
#       "eks.amazonaws.com/role-arn" : aws_iam_role.eks_monitor_irsa.arn
#     }
#     labels = {
#       "app.kubernetes.io/name" : "grafana-operator"
#     }
#   }
# }
