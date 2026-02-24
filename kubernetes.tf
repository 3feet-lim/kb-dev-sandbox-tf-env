# ENIConfig for Custom Networking (Pod Subnet)
resource "kubernetes_manifest" "eniconfig_az1" {
  manifest = {
    apiVersion = "crd.k8s.amazonaws.com/v1alpha1"
    kind       = "ENIConfig"
    metadata = {
      name = "ap-northeast-2a"
    }
    spec = {
      subnet         = module.subnets.subnets["${local.name_prefix}-pod-subnet-01"].id
      securityGroups = [module.eks_nodegroup_security_group.id]
    }
  }

  depends_on = [module.eks_addons]
}

resource "kubernetes_manifest" "eniconfig_az3" {
  manifest = {
    apiVersion = "crd.k8s.amazonaws.com/v1alpha1"
    kind       = "ENIConfig"
    metadata = {
      name = "ap-northeast-2c"
    }
    spec = {
      subnet         = module.subnets.subnets["${local.name_prefix}-pod-subnet-02"].id
      securityGroups = [module.eks_nodegroup_security_group.id]
    }
  }

  depends_on = [module.eks_addons]
}
