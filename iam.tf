# EBS CSI Driver IRSA (IAM Role for Service Account)
module "ebs_csi_irsa_role" {
  source = "./modules/terraform-aws-iam-role"

  name        = "${local.name_prefix}-eks-ebs-csi-irsa"
  description = "EBS CSI Driver IRSA Role"

  assume_role_policy = templatefile("${path.module}/data/policy/ebs-csi-irsa-trust.json.tpl", {
    oidc_arn = module.eks_cluster.oidc_arn
    oidc_url = replace(module.eks_cluster.url, "https://", "")
  })

  policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  ]
}
