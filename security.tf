# Bastion Host Security Group
module "bastion_security_group" {
  source = "./modules/terraform-aws-security-group"

  name        = "${local.name_prefix}-bastion-sg"
  vpc_id      = module.vpc_core.id
  description = "Security group for bastion host"

  ingress = {
    all-inbound = { from_port = "0", to_port = "0", ip_protocol = "-1", cidr_ipv4 = "0.0.0.0/0", description = "SSH access from specified CIDR" }
  }

  egress = {
    all-outbound = { from_port = "0", to_port = "0", ip_protocol = "-1", cidr_ipv4 = "0.0.0.0/0", description = "All outbound traffic" }
  }

  tags = {
    Name = "${local.name_prefix}-bastion-sg"
    Type = "Bastion"
  }
}

# EKS Node Group Security Group
module "eks_nodegroup_security_group" {
  source = "./modules/terraform-aws-security-group"

  name        = "${local.name_prefix}-eks-nodegroup-sg"
  vpc_id      = module.vpc_core.id
  description = "Security group for EKS node group"

  ingress = {
    all-from-self    = { from_port = "0", to_port = "0", ip_protocol = "-1", self = true, description = "All traffic from self" }
    ssh-from-bastion = { from_port = "22", to_port = "22", ip_protocol = "tcp", referenced_security_group_id = module.bastion_security_group.id, description = "SSH from bastion host" }
  }

  egress = {
    all-outbound = { from_port = "0", to_port = "0", ip_protocol = "-1", cidr_ipv4 = "0.0.0.0/0", description = "All outbound traffic" }
  }

  tags = {
    Name = "${local.name_prefix}-eks-nodegroup-sg"
    Type = "EKS-NodeGroup"
  }
}

# EKS Cluster Security Group
module "eks_cluster_security_group" {
  source = "./modules/terraform-aws-security-group"

  name        = "${local.name_prefix}-eks-cluster-sg"
  vpc_id      = module.vpc_core.id
  description = "Security group for EKS cluster control plane"

  ingress = {
    https-from-nodegroup = { from_port = "443", to_port = "443", ip_protocol = "tcp", referenced_security_group_id = module.eks_nodegroup_security_group.id, description = "HTTPS from node group" }
    https-from-bastion   = { from_port = "443", to_port = "443", ip_protocol = "tcp", referenced_security_group_id = module.bastion_security_group.id, description = "HTTPS from bastion host" }
  }

  egress = {
    kubelet-to-nodegroup = { from_port = "1025", to_port = "65535", ip_protocol = "tcp", referenced_security_group_id = module.eks_nodegroup_security_group.id, description = "Kubelet API to node group" }
    https-outbound       = { from_port = "443", to_port = "443", ip_protocol = "tcp", cidr_ipv4 = "0.0.0.0/0", description = "HTTPS to internet" }
  }

  tags = {
    Name = "${local.name_prefix}-eks-cluster-sg"
    Type = "EKS-Cluster"
  }

  depends_on = [module.eks_nodegroup_security_group]
}

# 노드 그룹 보안 그룹에 클러스터로부터의 Kubelet API 접근 규칙 추가
resource "aws_vpc_security_group_ingress_rule" "nodegroup_kubelet_from_cluster" {
  security_group_id            = module.eks_nodegroup_security_group.id
  referenced_security_group_id = module.eks_cluster_security_group.id
  from_port                    = 1025
  to_port                      = 65535
  ip_protocol                  = "tcp"
  description                  = "Kubelet API from cluster"

  depends_on = [module.eks_cluster_security_group, module.eks_nodegroup_security_group]
}
