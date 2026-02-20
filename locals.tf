locals {
  # 기본 정보
  service      = "grafana"
  env          = "dev"
  region       = "ap-northeast-2"
  company      = "kb0"
  servicegroup = "smlim"
  name_prefix  = "${local.company}-${local.servicegroup}-${local.service}-${local.env}"
  
  # 네트워크 설정
  vpc_cidr         = "100.71.0.0/24"
  secondary_cidr   = ["100.64.0.0/16"]
  
  # EKS 설정
  eks_version           = "1.33"
  node_instance_type    = "t3.micro"
  node_ami_id          = "ami-0038c2af290cc3fe7"
  node_desired_size    = 1
  node_min_size        = 1
  node_max_size        = 5
  
  # Bastion 설정
  bastion_ami_id       = "ami-00ba84400fe884666"
  ubuntu_ami_id = "ami-010be25c3775061c9"
  bastion_instance_type = "t3.micro"
  bastion_volume_size  = 30
  bastion_ssh_cidr     = "0.0.0.0/0"
  
  # 기능 플래그
  enable_vpc_flow_logs     = true
  enable_internet_gateway  = true
  
  # 추가 태그
  additional_tags = {
    Project     = "AI Learning Management System"
    Environment = "Development"
    Owner       = "Infrastructure Team"
  }
}