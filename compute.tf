# EKS Cluster IAM Role
module "eks_cluster_role" {
  source = "./modules/terraform-aws-iam-role"

  name        = "${local.name_prefix}-eks-cluster-role"
  description = "EKS Cluster Service Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  ]
}

# EKS NodeGroup IAM Role
module "eks_nodegroup_role" {
  source = "./modules/terraform-aws-iam-role"

  name        = "${local.name_prefix}-eks-nodegroup-role"
  description = "EKS NodeGroup Service Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  ]
}

# EKS Cluster
module "eks_cluster" {
  source = "./modules/terraform-aws-eks"

  name        = "${local.name_prefix}-eks-cluster"
  eks_version = local.eks_version
  role_arn    = module.eks_cluster_role.arn

  subnet_ids = [
    module.subnets.subnets["kb0-smlim-grafana-dev-app-subnet-01"].id, # app-subnet-01
    module.subnets.subnets["kb0-smlim-grafana-dev-app-subnet-02"].id  # app-subnet-02
  ]

  security_group_ids = [module.eks_cluster_security_group.id]

  endpoint_public_access  = true
  endpoint_private_access = true

  tags = {
    Name = "${local.name_prefix}-eks-cluster"
  }
}

# Launch Template for EKS NodeGroup
module "eks_launch_template" {
  source = "./modules/terraform-aws-launch-template"

  name          = "${local.name_prefix}-eks-lt-01"
  description   = "Launch Template for EKS NodeGroup"
  image_id      = local.node_ami_id
  instance_type = "t3.medium"

  vpc_security_group_ids = [module.eks_nodegroup_security_group.id]

  lt_eks_vars = {
    eks_cluster_name                  = module.eks_cluster.name
    eks_cluster_endpoint              = module.eks_cluster.endpoint
    eks_cluster_certificate_authority = module.eks_cluster.certificate_authority
    eks_cluster_service_ipv4_cidr     = module.eks_cluster.service_ipv4_cidr
  }

  block_device_mappings = [
    {
      device_name = "/dev/xvda"
      volume_size = 100
      volume_type = "gp3"
    }
  ]

  tags = {
    Name = "${local.name_prefix}-eks-lt-01"
  }

  instance_tags = {
    Name = "${local.name_prefix}-eks-node"
  }
}

# EKS NodeGroup
module "eks_nodegroup" {
  source = "./modules/terraform-aws-eks-ng"

  cluster_name      = module.eks_cluster.name
  node_group_name   = "${local.name_prefix}-eks-nodegroup-01"
  node_role_arn     = module.eks_nodegroup_role.arn

  subnet_ids = [
    module.subnets.subnets["kb0-smlim-grafana-dev-app-subnet-01"].id, # app-subnet-01
    module.subnets.subnets["kb0-smlim-grafana-dev-app-subnet-02"].id  # app-subnet-02
  ]

  desired_size = local.node_desired_size
  min_size     = local.node_min_size
  max_size     = local.node_max_size

  update_config = {
    max_unavailable_percentage = 50
  }

  launch_template_name    = module.eks_launch_template.name
  launch_template_version = module.eks_launch_template.latest_version

  tags = {
    Name = "${local.name_prefix}-eks-nodegroup-01"
  }
}

# EKS Addons
module "eks_addons" {
  source = "./modules/terraform-aws-eks-addon"

  cluster_name = module.eks_cluster.name

  addon = [
    { addon_name = "vpc-cni" },
    { addon_name = "kube-proxy" }
  ]
}

# Bastion Host
module "bastion_host" {
  source = "./modules/terraform-aws-ec2"

  name                   = "${local.name_prefix}-bastion-01"
  ami                    = local.bastion_ami_id
  instance_type          = local.bastion_instance_type
  key_name = "smlim"
  subnet_id              = module.subnets.subnets["kb0-smlim-grafana-dev-dmz-subnet-01"].id  # dmz-subnet-01
  vpc_security_group_ids = [module.bastion_security_group.id]
  
  volume_size            = local.bastion_volume_size
  volume_type            = "gp3"
  encrypted              = true
  delete_on_termination  = false
  disable_api_termination = false

  tags = {
    Name = "${local.name_prefix}-bastion-01"
    Type = "Bastion"
    Role = "Management"
  }

  volume_tags = {
    Name = "${local.name_prefix}-bastion-01-root"
    Type = "Bastion"
  }
}

module "test_instance" {
  source = "./modules/terraform-aws-ec2"

  name                   = "${local.name_prefix}-test-01"
  ami                    = local.ubuntu_ami_id
  instance_type          = "c7i.large"
  key_name               = "smlim"
  subnet_id              = module.subnets.subnets["kb0-smlim-grafana-dev-dmz-subnet-01"].id  # dmz-subnet-01
  vpc_security_group_ids = [module.bastion_security_group.id]
  
  volume_size            = local.bastion_volume_size
  volume_type            = "gp3"
  encrypted              = true
  delete_on_termination  = false
  disable_api_termination = false

  tags = {
    Name = "${local.name_prefix}-test-01"
    Type = "test"
    Role = "Management"
  }

  volume_tags = {
    Name = "${local.name_prefix}-test-01-root"
    Type = "test"
  }
}

# module "test_instance2" {
#   source = "./modules/terraform-aws-ec2"

#   name                   = "${local.name_prefix}-test-02"
#   ami                    = local.ubuntu_ami_id
#   instance_type          = "c7i.large"
#   key_name               = "smlim"
#   subnet_id              = module.subnets.subnets["kb0-smlim-grafana-dev-app-subnet-01"].id  # dmz-subnet-01
#   vpc_security_group_ids = [module.bastion_security_group.id]
  
#   volume_size            = local.bastion_volume_size
#   volume_type            = "gp3"
#   encrypted              = true
#   delete_on_termination  = false
#   disable_api_termination = false

#   tags = {
#     Name = "${local.name_prefix}-test-02"
#     Type = "test"
#     Role = "Management"
#   }

#   volume_tags = {
#     Name = "${local.name_prefix}-test-02-root"
#     Type = "test"
#   }
# }