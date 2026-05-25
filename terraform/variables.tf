variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "instance_id" {
  description = "Existing EC2 instance ID"
  type        = string
  default     = "i-0d759917b5e889577"
}

variable "ecr_repo_name" {
  description = "Existing ECR repository name"
  type        = string
  default     = "cropguard-ai"
}

variable "vpc_id" {
  description = "Existing VPC ID"
  type        = string
  default     = "vpc-078e4a30ea3c758cf"
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
  default     = "116137269524"
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "cropguard-ai"
}
