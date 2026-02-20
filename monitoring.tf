# # # Monitoring Namespace
# resource "kubernetes_namespace" "monitoring" {
#   metadata {
#     name = "monitoring"
#     labels = {
#       name         = "monitoring"
#       purpose      = "observability"
#       component    = "monitoring-stack"
#       managed-by   = "terraform"
#     }
#   }

#   depends_on = [module.eks_cluster]
# }

# # Service Accounts
# resource "kubernetes_service_account" "prometheus" {
#   metadata {
#     name      = "prometheus"
#     namespace = kubernetes_namespace.monitoring.metadata[0].name
#     labels = {
#       app       = "prometheus"
#       component = "monitoring-stack"
#     }
#   }
# }

# resource "kubernetes_service_account" "grafana" {
#   metadata {
#     name      = "grafana"
#     namespace = kubernetes_namespace.monitoring.metadata[0].name
#     labels = {
#       app       = "grafana"
#       component = "monitoring-stack"
#     }
#   }
# }

# resource "kubernetes_service_account" "kube_state_metrics" {
#   metadata {
#     name      = "kube-state-metrics"
#     namespace = kubernetes_namespace.monitoring.metadata[0].name
#     labels = {
#       app       = "kube-state-metrics"
#       component = "monitoring-stack"
#     }
#   }
# }

# # Cluster Roles
# resource "kubernetes_cluster_role" "prometheus" {
#   metadata {
#     name = "prometheus"
#     labels = {
#       app       = "prometheus"
#       component = "monitoring-stack"
#     }
#   }

#   rule {
#     api_groups = [""]
#     resources = [
#       "nodes",
#       "nodes/proxy",
#       "nodes/metrics",
#       "services",
#       "endpoints",
#       "pods",
#       "ingresses",
#       "configmaps"
#     ]
#     verbs = ["get", "list", "watch"]
#   }

#   rule {
#     api_groups = ["extensions"]
#     resources  = ["ingresses"]
#     verbs      = ["get", "list", "watch"]
#   }

#   rule {
#     api_groups = ["networking.k8s.io"]
#     resources  = ["ingresses"]
#     verbs      = ["get", "list", "watch"]
#   }

#   rule {
#     non_resource_urls = ["/metrics"]
#     verbs             = ["get"]
#   }
# }

# resource "kubernetes_cluster_role" "kube_state_metrics" {
#   metadata {
#     name = "kube-state-metrics"
#     labels = {
#       app       = "kube-state-metrics"
#       component = "monitoring-stack"
#     }
#   }

#   rule {
#     api_groups = [""]
#     resources = [
#       "configmaps",
#       "secrets",
#       "nodes",
#       "pods",
#       "services",
#       "resourcequotas",
#       "replicationcontrollers",
#       "limitranges",
#       "persistentvolumeclaims",
#       "persistentvolumes",
#       "namespaces",
#       "endpoints"
#     ]
#     verbs = ["list", "watch"]
#   }

#   rule {
#     api_groups = ["apps"]
#     resources = [
#       "statefulsets",
#       "daemonsets",
#       "deployments",
#       "replicasets"
#     ]
#     verbs = ["list", "watch"]
#   }

#   rule {
#     api_groups = ["batch"]
#     resources  = ["cronjobs", "jobs"]
#     verbs      = ["list", "watch"]
#   }

#   rule {
#     api_groups = ["autoscaling"]
#     resources  = ["horizontalpodautoscalers"]
#     verbs      = ["list", "watch"]
#   }

#   rule {
#     api_groups = ["authentication.k8s.io"]
#     resources  = ["tokenreviews"]
#     verbs      = ["create"]
#   }

#   rule {
#     api_groups = ["authorization.k8s.io"]
#     resources  = ["subjectaccessreviews"]
#     verbs      = ["create"]
#   }

#   rule {
#     api_groups = ["policy"]
#     resources  = ["poddisruptionbudgets"]
#     verbs      = ["list", "watch"]
#   }

#   rule {
#     api_groups = ["certificates.k8s.io"]
#     resources  = ["certificatesigningrequests"]
#     verbs      = ["list", "watch"]
#   }

#   rule {
#     api_groups = ["storage.k8s.io"]
#     resources  = ["storageclasses", "volumeattachments"]
#     verbs      = ["list", "watch"]
#   }

#   rule {
#     api_groups = ["admissionregistration.k8s.io"]
#     resources  = ["mutatingwebhookconfigurations", "validatingwebhookconfigurations"]
#     verbs      = ["list", "watch"]
#   }

#   rule {
#     api_groups = ["networking.k8s.io"]
#     resources  = ["networkpolicies", "ingresses"]
#     verbs      = ["list", "watch"]
#   }

#   rule {
#     api_groups = ["coordination.k8s.io"]
#     resources  = ["leases"]
#     verbs      = ["list", "watch"]
#   }
# }

# # Cluster Role Bindings
# resource "kubernetes_cluster_role_binding" "prometheus" {
#   metadata {
#     name = "prometheus"
#     labels = {
#       app       = "prometheus"
#       component = "monitoring-stack"
#     }
#   }

#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = kubernetes_cluster_role.prometheus.metadata[0].name
#   }

#   subject {
#     kind      = "ServiceAccount"
#     name      = "observability-sa"
#     namespace = "observability"
#   }
# }

# resource "kubernetes_cluster_role_binding" "kube_state_metrics" {
#   metadata {
#     name = "kube-state-metrics"
#     labels = {
#       app       = "kube-state-metrics"
#       component = "monitoring-stack"
#     }
#   }

#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = kubernetes_cluster_role.kube_state_metrics.metadata[0].name
#   }

#   subject {
#     kind      = "ServiceAccount"
#     name      = kubernetes_service_account.kube_state_metrics.metadata[0].name
#     namespace = kubernetes_namespace.monitoring.metadata[0].name
#   }
# }