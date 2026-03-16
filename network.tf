# VPC with primary and secondary CIDR blocks using module
module "vpc_core" {
  source = "./modules/terraform-aws-vpc-core"

  name                 = "${local.name_prefix}-vpc"
  cidr_block           = local.vpc_cidr
  secondary_cidr_block = local.secondary_cidr

  igw_enable         = local.enable_internet_gateway
  vpc_flowlog_enable = local.enable_vpc_flow_logs
  #vpc_flowlog_name     = "${local.name_prefix}-vpc-flowlog"

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

# Subnets
module "subnets" {
  source = "./modules/terraform-aws-subnets"

  vpc_id = module.vpc_core.id

  subnets = [
    # DMZ Subnets (Primary CIDR) - AZ a and c - Equally divided
    {
      name                    = "${local.name_prefix}-dmz-subnet-01"
      availability_zone_id    = "apne2-az1"     # ap-northeast-2a
      cidr_block              = "100.71.0.0/27" # 32 IPs
      map_public_ip_on_launch = true
      tags = {
        Name = "${local.name_prefix}-dmz-subnet-01"
        Type = "DMZ"
      }
    },
    {
      name                    = "${local.name_prefix}-dmz-subnet-02"
      availability_zone_id    = "apne2-az3"      # ap-northeast-2c
      cidr_block              = "100.71.0.32/27" # 32 IPs
      map_public_ip_on_launch = true
      tags = {
        Name = "${local.name_prefix}-dmz-subnet-02"
        Type = "DMZ"
      }
    },
    # APP Subnets (Primary CIDR) - AZ a and c - Equally divided
    {
      name                    = "${local.name_prefix}-app-subnet-01"
      availability_zone_id    = "apne2-az1"      # ap-northeast-2a
      cidr_block              = "100.71.0.64/27" # 32 IPs
      map_public_ip_on_launch = false
      tags = {
        Name = "${local.name_prefix}-app-subnet-01"
        Type = "APP"
      }
    },
    {
      name                    = "${local.name_prefix}-app-subnet-02"
      availability_zone_id    = "apne2-az3"      # ap-northeast-2c
      cidr_block              = "100.71.0.96/27" # 32 IPs
      map_public_ip_on_launch = false
      tags = {
        Name = "${local.name_prefix}-app-subnet-02"
        Type = "APP"
      }
    },
    # DB Subnets (Primary CIDR) - AZ a and c - Equally divided
    {
      name                    = "${local.name_prefix}-db-subnet-01"
      availability_zone_id    = "apne2-az1"       # ap-northeast-2a
      cidr_block              = "100.71.0.128/27" # 32 IPs
      map_public_ip_on_launch = false
      tags = {
        Name = "${local.name_prefix}-db-subnet-01"
        Type = "DB"
      }
    },
    {
      name                    = "${local.name_prefix}-db-subnet-02"
      availability_zone_id    = "apne2-az3"       # ap-northeast-2c
      cidr_block              = "100.71.0.160/27" # 32 IPs
      map_public_ip_on_launch = false
      tags = {
        Name = "${local.name_prefix}-db-subnet-02"
        Type = "DB"
      }
    },
    # POD Subnets (Secondary CIDR - /24 subnets)
    {
      name                    = "${local.name_prefix}-pod-subnet-01"
      availability_zone_id    = "apne2-az1"     # ap-northeast-2a
      cidr_block              = "100.64.0.0/24" # 256 IPs
      map_public_ip_on_launch = false
      tags = {
        Name = "${local.name_prefix}-pod-subnet-01"
        Type = "POD"
      }
    },
    {
      name                    = "${local.name_prefix}-pod-subnet-02"
      availability_zone_id    = "apne2-az3"     # ap-northeast-2c
      cidr_block              = "100.64.1.0/24" # 256 IPs
      map_public_ip_on_launch = false
      tags = {
        Name = "${local.name_prefix}-pod-subnet-02"
        Type = "POD"
      }
    }
  ]
  depends_on = [module.vpc_core]
}

# NAT Gateway for private subnet internet access
module "nat_gateway" {
  source = "./modules/terraform-aws-natgateway"

  natgateway = [
    {
      name              = "${local.name_prefix}-nat-gateway-01"
      subnet_id         = module.subnets.subnets["kb0-smlim-grafana-dev-dmz-subnet-01"].id # dmz-subnet-01
      connectivity_type = "public"
    }
  ]

  tags = {
    Name = "${local.name_prefix}-nat-gateway-01"
  }
}

# Route Tables
module "dmz_route_table" {
  source = "./modules/terraform-aws-route-table"

  name   = "${local.name_prefix}-dmz-rt"
  vpc_id = module.vpc_core.id
  subnet_ids = [
    module.subnets.subnets["kb0-smlim-grafana-dev-dmz-subnet-01"].id, # dmz-subnet-01
    module.subnets.subnets["kb0-smlim-grafana-dev-dmz-subnet-02"].id  # dmz-subnet-02
  ]

  routes = [
    {
      destination_cidr_block = "0.0.0.0/0"
      gateway_id             = module.vpc_core.igw_id
    }
  ]

  tags = {
    Name = "${local.name_prefix}-dmz-rt"
    Type = "DMZ"
  }
}

module "app_route_table" {
  source = "./modules/terraform-aws-route-table"

  name   = "${local.name_prefix}-app-rt"
  vpc_id = module.vpc_core.id
  subnet_ids = [
    module.subnets.subnets["kb0-smlim-grafana-dev-app-subnet-01"].id, # app-subnet-01
    module.subnets.subnets["kb0-smlim-grafana-dev-app-subnet-02"].id  # app-subnet-02
  ]

  routes = [
    {
      destination_cidr_block = "0.0.0.0/0"
      nat_gateway_id         = module.nat_gateway.natgateways["${local.name_prefix}-nat-gateway-01"].id
    },
    {
      destination_cidr_block = "100.72.0.0/22"
      transit_gateway_id     = local.tgw_id
    },
    {
      destination_cidr_block = "100.71.64.0/22"
      transit_gateway_id     = local.tgw_id
    }
  ]

  tags = {
    Name = "${local.name_prefix}-app-rt"
    Type = "APP"
  }
}

module "db_route_table" {
  source = "./modules/terraform-aws-route-table"

  name   = "${local.name_prefix}-db-rt"
  vpc_id = module.vpc_core.id
  subnet_ids = [
    module.subnets.subnets["kb0-smlim-grafana-dev-db-subnet-01"].id, # db-subnet-01
    module.subnets.subnets["kb0-smlim-grafana-dev-db-subnet-02"].id  # db-subnet-02
  ]

  tags = {
    Name = "${local.name_prefix}-db-rt"
    Type = "DB"
  }
}

module "pod_route_table" {
  source = "./modules/terraform-aws-route-table"

  name   = "${local.name_prefix}-pod-rt"
  vpc_id = module.vpc_core.id
  subnet_ids = [
    module.subnets.subnets["kb0-smlim-grafana-dev-pod-subnet-01"].id, # pod-subnet-01
    module.subnets.subnets["kb0-smlim-grafana-dev-pod-subnet-02"].id  # pod-subnet-02
  ]

  routes = [
    {
      destination_cidr_block = "0.0.0.0/0"
      nat_gateway_id         = module.nat_gateway.natgateways["${local.name_prefix}-nat-gateway-01"].id
    }
  ]

  tags = {
    Name = "${local.name_prefix}-pod-rt"
    Type = "POD"
  }
}


module "vpc_endpoint" {
  source = "./modules/terraform-aws-endpoint"


  vpc_id                                         = module.vpc_core.id
  private_dns_only_for_inbound_resolver_endpoint = false
  vpce_list = [
    {
      service_name      = "com.amazonaws.ap-northeast-2.s3"
      vpc_endpoint_type = "Gateway"
      route_table_ids = [

      ]
      vpce_name = "${local.name_prefix}-s3-gateway-endpoint"
    },
    {
      service_name      = "com.amazonaws.ap-northeast-2.logs"
      vpc_endpoint_type = "Interface"
      subnet_ids = [
        module.subnets.subnets["${local.name_prefix}-app-subnet-01"].id
      ]
      security_group_ids = [module.vpce_security_group.id]
      vpce_name          = "${local.name_prefix}-logs-interface-endpoint"
    },
    {
      service_name      = "com.amazonaws.ap-northeast-2.monitoring"
      vpc_endpoint_type = "Interface"
      subnet_ids = [
        module.subnets.subnets["${local.name_prefix}-app-subnet-01"].id
      ]
      security_group_ids = [module.vpce_security_group.id]
      vpce_name          = "${local.name_prefix}-monitoring-interface-endpoint"
    },
    {
      service_name      = "com.amazonaws.ap-northeast-2.bedrock-runtime"
      vpc_endpoint_type = "Interface"
      subnet_ids = [
        module.subnets.subnets["${local.name_prefix}-app-subnet-01"].id
      ]
      security_group_ids = [module.vpce_security_group.id]
      vpce_name          = "${local.name_prefix}-bedrock-interface-endpoint"
    },
    {
      service_name      = "com.amazonaws.ap-northeast-2.s3"
      vpc_endpoint_type = "Interface"
      subnet_ids = [
        module.subnets.subnets["${local.name_prefix}-app-subnet-01"].id
      ]
      security_group_ids = [module.vpce_security_group.id]
      vpce_name          = "${local.name_prefix}-s3-interface-endpoint"
    },
    {
      service_name      = "com.amazonaws.ap-northeast-2.ec2"
      vpc_endpoint_type = "Interface"
      subnet_ids = [
        module.subnets.subnets["${local.name_prefix}-app-subnet-01"].id
      ]
      security_group_ids = [module.vpce_security_group.id]
      vpce_name          = "${local.name_prefix}-ec2-interface-endpoint"
    },
    {
      service_name      = "com.amazonaws.ap-northeast-2.eks"
      vpc_endpoint_type = "Interface"
      subnet_ids = [
        module.subnets.subnets["${local.name_prefix}-app-subnet-01"].id
      ]
      security_group_ids = [module.vpce_security_group.id]
      vpce_name          = "${local.name_prefix}-eks-interface-endpoint"
    },
    {
      service_name      = "com.amazonaws.ap-northeast-2.sts"
      vpc_endpoint_type = "Interface"
      subnet_ids = [
        module.subnets.subnets["${local.name_prefix}-app-subnet-01"].id
      ]
      security_group_ids = [module.vpce_security_group.id]
      vpce_name          = "${local.name_prefix}-sts-interface-endpoint"
    },
    {
      service_name      = "com.amazonaws.ap-northeast-2.ecr.api"
      vpc_endpoint_type = "Interface"
      subnet_ids = [
        module.subnets.subnets["${local.name_prefix}-app-subnet-01"].id
      ]
      security_group_ids = [module.vpce_security_group.id]
      vpce_name          = "${local.name_prefix}-ecr-api-interface-endpoint"
    },
    {
      service_name      = "com.amazonaws.ap-northeast-2.ecr.dkr"
      vpc_endpoint_type = "Interface"
      subnet_ids = [
        module.subnets.subnets["${local.name_prefix}-app-subnet-01"].id
      ]
      security_group_ids = [module.vpce_security_group.id]
      vpce_name          = "${local.name_prefix}-ecr-dkr-interface-endpoint"
    },
  ]
}

# Transit Gateway Attachment
module "tgw_attachment" {
  source = "./modules/terraform-aws-tgw-attachment"

  name               = "${local.name_prefix}-tgw-attachment"
  transit_gateway_id = local.tgw_id
  vpc_id             = module.vpc_core.id
  subnet_ids = [
    module.subnets.subnets["kb0-smlim-grafana-dev-dmz-subnet-01"].id,
    module.subnets.subnets["kb0-smlim-grafana-dev-dmz-subnet-02"].id
  ]

  tags = {
    Name = "${local.name_prefix}-tgw-attachment"
  }
}

# Private Agent NLB 타겟 그룹
module "private_agent_tg" {
  source = "./modules/terraform-aws-tg-nlb"

  name        = "${local.name_prefix}-pa-tg"
  vpc_id      = module.vpc_core.id
  protocol    = "TCP"
  port        = 3000
  target_type = "instance"

  targets = [
    { id = module.private_agent_instance.id }
  ]

  tags = {
    Name = "${local.name_prefix}-prv-agent-tg"
  }
}

# Private Agent NLB (internet-facing)
module "private_agent_nlb" {
  source = "./modules/terraform-aws-nlb"

  name     = "${local.name_prefix}-pa-nlb"
  internal = false

  subnets = [
    module.subnets.subnets["kb0-smlim-grafana-dev-dmz-subnet-01"].id,
    module.subnets.subnets["kb0-smlim-grafana-dev-dmz-subnet-02"].id
  ]

  security_groups = [module.bastion_security_group.id]

  enable_deletion_protection = false
  access_log_enabled         = false

  listeners = [
    {
      port             = 80
      protocol         = "TCP"
      target_group_arn = module.private_agent_tg.arn
    }
  ]

  tags = {
    Name = "${local.name_prefix}-prv-agent-nlb"
  }
}
