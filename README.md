# AI 학습 관리 시스템 인프라 구축 명세서

## 기본 정보
### 기본규칙
- 모든 리소스에는 name_prefix-리소스이름
- 같은 종류의 리소스가 있을 경우 01, 02, 03 붙일 것.
- 필수태그는 provider default_tags 기능을 사용해서 전체 리소스에 적용

### 필수태그
- Company : local.company
- Servicegroup : local.servicegroup
- Service : local.service
- Env : local.env

### 지역변수
- service : "grafana"
- env : "dev"
- region : "ap-northeast-2"
- company : "kb0"
- servicegroup : "smlim"
- name_prefix: "${local.company}-${local.servicegroup}-${local.service}-${local.env}"

## Network
### VPC
- CIDR: 100.71.0.0/24
- Secondary CIDR: 100.64.0.0/16
- IGW: 활성화
- VPC Flow log: 활성화

### Subnet
- a, c 2개의 AZ 사용
- 각각의 AZ에 dmz, app, db subnet을 하나씩 생성
- primary subnet을 똑같이 나눠서 dmz, app, db에 분배
- pod subnet은 24 옥텟을 가지는 서브넷 2개 생성 (Secondary CIDR 사용)

### Nat gateway
- dmz subnet에 생성
- public connectivity type

### Route Table
- Subnet 종류 별로 하나씩 생성. AZ마다 RT를 구분할 필요는 없음.
- 라우트는 수동 설정

## Compute
### EKS Cluster 역할 생성
- EKS_CNI_Policy 추가
- EKSClusterPolicy 추가

### EKS Nodegroup 역할 생성
- EKS_CNI_Policy 추가
- EKSClusterPolicy 추가
- EC2ContainerRegistryReadOnly 추가

### EKS cluster
- app subnet에 EKS cluster 생성
- VERSION은 1.33
- EKS Cluster 역할 사용

### EKS nodegroup
- app subnet에 생성
- 노드그룹은 1개
- desired, min, max 는 1로 설정
- VERSION은 1.33
- EKS nodegroup 역할 사용

### EKS addons
- vpc-cni
- kube-proxy
- eks version에 맞는 default 버젼을 사용

### Launch Template
- ami-00ba84400fe884666
- t3.micro

---

## Terraform Infrastructure Implementation

This directory contains the complete Terraform implementation of the AI Learning Management System infrastructure as specified above.

### Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.0 installed
3. **TFLint** (optional, for linting)

### Directory Structure

```
terraform-infra-dev/grafana_dashboard/
├── .gitignore              # Git ignore file
├── .tflint.hcl            # TFLint configuration
├── README.md              # This file
├── compute.tf             # EKS cluster, node group, and bastion host resources
├── locals.tf              # Local variables and configuration
├── main.tf                # Main configuration and data sources
├── network.tf             # VPC, subnets, NAT gateway, route tables
├── outputs.tf             # Output values
├── provider.tf            # AWS provider configuration
├── security.tf            # Security groups
└── versions.tf            # Terraform and provider version constraints
```

### Quick Start

1. **Clone and navigate to the directory:**
   ```bash
   cd terraform-infra-dev/grafana_dashboard
   ```

2. **Initialize Terraform:**
   ```bash
   terraform init
   ```

3. **Plan the deployment:**
   ```bash
   terraform plan
   ```

4. **Apply the configuration:**
   ```bash
   terraform apply
   ```

### Infrastructure Components

#### Network Layer
- **VPC**: 100.71.0.0/24 with secondary CIDR 100.64.0.0/16
- **Subnets**: 
  - DMZ subnets (public): 100.71.0.0/27, 100.71.0.32/27
  - APP subnets (private): 100.71.0.64/27, 100.71.0.96/27
  - DB subnets (private): 100.71.0.128/27, 100.71.0.160/27
  - POD subnets (private): 100.64.0.0/24, 100.64.1.0/24
- **NAT Gateway**: In DMZ subnet for private subnet internet access
- **Route Tables**: Separate route tables for each subnet type

#### Compute Layer
- **EKS Cluster**: Version 1.33 in APP subnets
- **EKS Node Group**: Single node group with t3.micro instances
- **Launch Template**: Custom launch template with specified AMI
- **IAM Roles**: Properly configured roles for cluster and node groups
- **EKS Addons**: vpc-cni and kube-proxy with default versions
- **Bastion Host**: t3.micro instance in DMZ subnet for secure access
  - Root volume: 30GB gp3 encrypted
  - Pre-installed tools: AWS CLI, kubectl, eksctl
  - SSH access from configurable CIDR range

### Configuration

All configuration is centralized in `locals.tf`:

- **Network settings**: VPC CIDR blocks, subnet configurations
- **EKS settings**: Kubernetes version, node instance types, scaling parameters
- **Bastion settings**: Instance type, volume size, SSH access CIDR
- **Feature flags**: VPC Flow Logs, Internet Gateway enablement
- **Tags**: Additional resource tags

To modify any settings, simply edit the values in `locals.tf`.

### Outputs

The configuration provides comprehensive outputs including:
- VPC and subnet IDs
- EKS cluster information
- NAT Gateway details
- Route table IDs
- IAM role ARNs

### Tagging Strategy

All resources are automatically tagged using AWS provider default tags:
- **Company**: kb0
- **Servicegroup**: smlim
- **Service**: grafana
- **Env**: dev

### Security Considerations

- Private subnets for application and database tiers
- NAT Gateway for secure outbound internet access
- Proper IAM roles with minimal required permissions
- VPC Flow Logs enabled for network monitoring
- **Security Groups**:
  - **Bastion SG**: SSH access (port 22) from configurable CIDR
  - **EKS Cluster SG**: HTTPS (port 443) from node group and bastion, Kubelet API (1025-65535) to node group
  - **EKS Node Group SG**: Kubelet API from cluster, SSH from bastion, inter-node communication
  - **Cross-references**: Security groups reference each other for secure communication

### Maintenance

- **Linting**: Run `tflint` to check for issues
- **Formatting**: Run `terraform fmt` to format code
- **Validation**: Run `terraform validate` to validate configuration
- **Updates**: Review and update provider versions regularly

### Troubleshooting

Common issues and solutions:

1. **Module not found**: Ensure you're running from the correct directory and modules exist in `../../modules/`
2. **Permission denied**: Check AWS credentials and IAM permissions
3. **Resource conflicts**: Ensure resource names are unique in your AWS account
4. **Version conflicts**: Check Terraform and provider version requirements

### Support

For issues or questions regarding this infrastructure:
1. Check the Terraform documentation
2. Review AWS EKS documentation
3. Consult the module documentation in `../../modules/`

