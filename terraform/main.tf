# ============================================================
# CropGuard AI — Terraform Configuration
# Single EC2: Jenkins + K3s + App
# ============================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ============================================================
# DATA SOURCES — Reference existing resources
# ============================================================

# Existing ECR repository
data "aws_ecr_repository" "cropguard" {
  name = var.ecr_repo_name
}

# Existing EC2 instance
data "aws_instance" "cropguard" {
  instance_id = var.instance_id
}

# Existing VPC
data "aws_vpc" "main" {
  id = var.vpc_id
}

# ============================================================
# IAM — Allow EC2 to pull images from ECR
# (This was the MISSING piece causing "Unable to locate credentials")
# ============================================================

resource "aws_iam_role" "ec2_ecr_role" {
  name = "${var.project_name}-ec2-ecr-role"

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

  tags = {
    Project = var.project_name
  }
}

# ECR read-only access — enough to pull images
resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.ec2_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Also grant ECR push access so Jenkins (on same EC2) can push images
resource "aws_iam_role_policy" "ecr_push" {
  name = "${var.project_name}-ecr-push"
  role = aws_iam_role.ec2_ecr_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = data.aws_ecr_repository.cropguard.arn
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_ecr_role.name
}

# ============================================================
# SECURITY GROUP — Open required ports
# ============================================================

resource "aws_security_group" "cropguard" {
  name        = "${var.project_name}-sg"
  description = "Security group for CropGuard AI (Jenkins + K3s + App)"
  vpc_id      = var.vpc_id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # HTTP — App via K3s LoadBalancer
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "CropGuard AI web app"
  }

  # Jenkins UI
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Jenkins CI/CD UI"
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name    = "${var.project_name}-sg"
    Project = var.project_name
  }
}

# ============================================================
# ELASTIC IP — Permanent public IP that survives reboots
# ============================================================

resource "aws_eip" "cropguard" {
  domain = "vpc"

  tags = {
    Name    = "${var.project_name}-eip"
    Project = var.project_name
  }
}

resource "aws_eip_association" "cropguard" {
  instance_id   = var.instance_id
  allocation_id = aws_eip.cropguard.id
}

# ============================================================
# OUTPUTS — See outputs.tf
# ============================================================

# ============================================================
# IMPORTANT: Manual steps after terraform apply
# ============================================================
# 1. Attach the IAM instance profile to EC2:
#    aws ec2 associate-iam-instance-profile \
#      --instance-id i-0d759917b5e889577 \
#      --iam-instance-profile Name=cropguard-ai-ec2-profile
#
# 2. Attach the security group to EC2:
#    aws ec2 modify-instance-attribute \
#      --instance-id i-0d759917b5e889577 \
#      --groups <sg-id-from-terraform-output>
#
# 3. SCP and run setup-ec2.sh on the EC2 instance
# ============================================================
