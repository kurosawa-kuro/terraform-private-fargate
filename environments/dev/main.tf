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
  
  # ECR設定
  repository_name = "${local.app_name}-${local.environment}"
  
  # ALB設定
  alb_name = "${local.app_name}-${local.environment}-alb"
  target_group_name = "${local.app_name}-${local.environment}-tg"
  health_check_path = "/health"
  
  # ECS設定
  cluster_name = "${local.app_name}-${local.environment}-cluster"
  service_name = "${local.app_name}-${local.environment}-service"
  task_definition_name = "${local.app_name}-${local.environment}-task"
  container_name = "${local.app_name}"
  container_port = 3000
  desired_count = 2
  cpu = 256
  memory = 512
  
  # IAM設定
  name_prefix = "${local.app_name}-${local.environment}"
}

# VPCモジュール
module "vpc" {
  source = "../../modules/vpc"
  
  vpc_name = local.vpc_name
  vpc_cidr = local.vpc_cidr
  availability_zones = local.availability_zones
  public_subnet_cidrs = local.public_subnet_cidrs
  private_subnet_cidrs = local.private_subnet_cidrs
}

# ECRモジュール
module "ecr" {
  source = "../../modules/ecr"
  
  repository_name = local.repository_name
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
  container_image = "${module.ecr.repository_url}:latest"
  desired_count = local.desired_count
  cpu = local.cpu
  memory = local.memory
  execution_role_arn = module.iam.ecs_task_execution_role_arn
  task_role_arn = module.iam.ecs_task_role_arn
} 