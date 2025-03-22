# configure aws provider
provider "aws" {
    region      = var.region
    profile     = "terraform-user"
}


# create vpc
module "vpc" {
    source                                  = "../modules/vpc"
    region                                  = var.region
    project_name                            = var.project_name
    vpc_cidr                                = var.vpc_cidr
    public_subnet_az1_cidr                  = var.public_subnet_az1_cidr
    public_subnet_az2_cidr                  = var.public_subnet_az2_cidr
    private_app_subnet_az1_cidr             = var.private_app_subnet_az1_cidr
    private_app_subnet_az2_cidr             = var.private_app_subnet_az2_cidr
    private_data_subnet_az1_cidr            = var.private_data_subnet_az1_cidr
    private_data_subnet_az2_cidr            = var.private_data_subnet_az2_cidr
}


# Create nat gateway
module "nat_gateway" {
    source                                  = "../modules/nat-gateway"
    public_subnet_az1_id                    = module.vpc.public_subnet_az1_id
    internet_gateway                        = module.vpc.internet_gateway
    public_subnet_az2_id                    = module.vpc.public_subnet_az2_id
    vpc_id                                  = module.vpc.vpc_id
    private_app_subnet_az1_id               = module.vpc.private_app_subnet_az1_id
    private_data_subnet_az1_id              = module.vpc.private_data_subnet_az1_id
    private_app_subnet_az2_id               = module.vpc.private_app_subnet_az2_id
    private_data_subnet_az2_id              = module.vpc.private_data_subnet_az2_id
     
}


# Create security groups
module "security_group" {
    source                                  = "../modules/security-groups"
    vpc_id                                  = module.vpc.vpc_id
}


# Create ecs task execution role
module "ecs_task_execution_role" {
    source                                  = "../modules/ecs-tasks-execution-role"
    project_name                            = module.vpc.project_name
}


# request ssl certificate
module "acm" {
    source                                  = "../modules/acm"
    domain_name                             = var.domain_name
    alternative_name                        = var.alternative_name
}


# Create application load balancer
module "alb" {
    source                                  = "../modules/alb"
    project_name                            = module.vpc.project_name
    alb_security_group_id                   = module.security_group.alb_security_group_id
    public_subnet_az1_id                    = module.vpc.public_subnet_az1_id
    public_subnet_az2_id                    = module.vpc.public_subnet_az2_id
    vpc_id                                  = module.vpc.vpc_id
    certificate_arn                         = module.acm.certificate_arn
}


# Create ecs
module "ecs" {
    source                                  = "../modules/ecs"
    project_name                            = module.vpc.project_name
    ecs_tasks_execution_role_arn            = module.ecs_task_execution_role.ecs_tasks_execution_role_arn
    container_image                         = var.container_image
    region                                  = module.vpc.region
    private_app_subnet_az1_id               = module.vpc.private_app_subnet_az1_id
    private_app_subnet_az2_id               = module.vpc.private_app_subnet_az2_id
    ecs_security_group_id                   = module.security_group.ecs_security_group_id
    alb_target_group_arn                    = module.alb.alb_target_group_arn
}


# Create asg
module "asg" {
    source                                  = "../modules/asg"
    ecs_cluster_name                        = module.ecs.ecs_cluster_name
    ecs_service_name                        = module.ecs.ecs_service_name
} 