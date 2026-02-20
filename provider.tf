provider "aws" {
  region = local.region

  default_tags {
    tags = {
      Company      = local.company
      Servicegroup = local.servicegroup
      Service      = local.service
      Env          = local.env
    }
  }
}

provider "kubernetes" {
  host                   = module.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(module.eks_cluster.certificate_authority)
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = ["eks", "get-token", "--cluster-name", module.eks_cluster.name]
  }
}