provider "aws" {
  region = "ap-northeast-1"
}

locals {
  app_name = "express-api"
  environment = "dev"
  vpc_name = "${local.app_name}-${local.environment}-vpc"
  
  # VPC設定
  vpc_cidr = "10.0.0.0/16"
  availability_zones = ["ap-northeast-1a", "ap-northeast-1c"]
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
  single_nat_gateway = true  # コスト最適化のため
  
  # ECR設定
  repository_name = "${local.app_name}-${local.environment}"
  encryption_type = "KMS"  # リポジトリの暗号化を有効化
  
  # ALB設定
  alb_name = "${local.app_name}-${local.environment}-alb"
  target_group_name = "${local.app_name}-${local.environment}-tg"
  health_check_path = "/health"
  enable_https = false  # 本番環境では true に設定し、certificateを用意
  # ssl_certificate_arn = "arn:aws:acm:ap-northeast-1:123456789012:certificate/xxxxx" # 本番環境用
  
  # セキュリティ設定
  allowed_cidr_blocks = ["0.0.0.0/0"]  # 本番環境では制限すべき
  allowed_egress_cidr_blocks = ["0.0.0.0/0"]  # 本番環境では制限すべき
  
  # ECS設定
  cluster_name = "${local.app_name}-${local.environment}-cluster"
  service_name = "${local.app_name}-${local.environment}-service"
  task_definition_name = "${local.app_name}-${local.environment}-task"
  container_name = "${local.app_name}"
  container_port = 3000
  image_tag = "latest"  # 本番環境では特定のバージョンを指定すべき
  desired_count = 2
  cpu = 256
  memory = 512
  log_retention_days = 30
  
  # Auto Scaling設定
  enable_autoscaling = true
  min_capacity = 1
  max_capacity = 4
  cpu_target_value = 70
  memory_target_value = 70
  
  # IAM設定
  name_prefix = "${local.app_name}-${local.environment}"
  
  # 共通タグ
  common_tags = {
    Project     = local.app_name
    Environment = local.environment
    ManagedBy   = "terraform"
  }
}

# VPCモジュール
module "vpc" {
  source = "../../modules/vpc"
  
  vpc_name = local.vpc_name
  vpc_cidr = local.vpc_cidr
  availability_zones = local.availability_zones
  public_subnet_cidrs = local.public_subnet_cidrs
  private_subnet_cidrs = local.private_subnet_cidrs
  single_nat_gateway = local.single_nat_gateway
  tags = local.common_tags
}

# ECRモジュール
module "ecr" {
  source = "../../modules/ecr"
  
  repository_name = local.repository_name
  encryption_type = local.encryption_type
  tags = local.common_tags
}

# IAMモジュール
module "iam" {
  source = "../../modules/iam"
  
  name_prefix = local.name_prefix
}

# ALBモジュール
module "alb" {
  source = "../../modules/alb"
  
  alb_name = local.alb_name
  vpc_id = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  target_group_name = local.target_group_name
  health_check_path = local.health_check_path
  container_port = local.container_port
  enable_https = local.enable_https
  # ssl_certificate_arn = local.ssl_certificate_arn # 本番環境用
  allowed_cidr_blocks = local.allowed_cidr_blocks
  allowed_egress_cidr_blocks = local.allowed_egress_cidr_blocks
  tags = local.common_tags
}

# ECSモジュール
module "ecs" {
  source = "../../modules/ecs"
  
  cluster_name = local.cluster_name
  service_name = local.service_name
  task_definition_name = local.task_definition_name
  vpc_id = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  alb_security_group_id = module.alb.alb_security_group_id
  target_group_arn = module.alb.target_group_arn
  container_name = local.container_name
  container_port = local.container_port
  container_image = module.ecr.repository_url
  image_tag = local.image_tag
  desired_count = local.desired_count
  cpu = local.cpu
  memory = local.memory
  log_retention_days = local.log_retention_days
  execution_role_arn = module.iam.ecs_task_execution_role_arn
  task_role_arn = module.iam.ecs_task_role_arn
  enable_autoscaling = local.enable_autoscaling
  min_capacity = local.min_capacity
  max_capacity = local.max_capacity
  cpu_target_value = local.cpu_target_value
  memory_target_value = local.memory_target_value
  allowed_egress_cidr_blocks = local.allowed_egress_cidr_blocks
  tags = local.common_tags
} 