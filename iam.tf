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

# Bastion CloudWatch ReadOnly 정책
module "bastion_cloudwatch_readonly_policy" {
  source = "./modules/terraform-aws-iam-policy"

  name        = "${local.name_prefix}-bastion-cw-readonly"
  description = "CloudWatch and resource read-only access for Bastion"
  policy      = file("${path.module}/data/policy/bastion-cloudwatch-readonly.json")
}

# Bastion 인스턴스 프로파일
module "bastion_instance_profile" {
  source = "./modules/terraform-aws-instance-profile"

  name        = "${local.name_prefix}-bastion-profile"
  description = "Bastion EC2 Instance Profile"

  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSServicePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    module.bastion_cloudwatch_readonly_policy.arn
  ]
}

# CloudWatch Observability IRSA (Container Insights)
module "cloudwatch_observability_irsa_role" {
  source = "./modules/terraform-aws-iam-role"

  name        = "${local.name_prefix}-eks-cw-observability-irsa"
  description = "CloudWatch Observability IRSA Role"

  assume_role_policy = templatefile("${path.module}/data/policy/cloudwatch-observability-irsa-trust.json.tpl", {
    oidc_arn = module.eks_cluster.oidc_arn
    oidc_url = replace(module.eks_cluster.url, "https://", "")
  })

  policy_arns = [
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
  ]
}
