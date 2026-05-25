output "elastic_ip" {
  description = "Elastic IP address for the EC2 instance (permanent URL)"
  value       = aws_eip.cropguard.public_ip
}

output "app_url" {
  description = "CropGuard AI application URL"
  value       = "http://${aws_eip.cropguard.public_ip}"
}

output "jenkins_url" {
  description = "Jenkins CI/CD URL"
  value       = "http://${aws_eip.cropguard.public_ip}:8080"
}

output "ecr_repo_url" {
  description = "ECR repository URL"
  value       = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.ecr_repo_name}"
}

output "ssh_command" {
  description = "SSH command to connect to EC2"
  value       = "ssh -i <your-key>.pem ubuntu@${aws_eip.cropguard.public_ip}"
}

output "iam_role_name" {
  description = "IAM role attached to EC2"
  value       = aws_iam_role.ec2_ecr_role.name
}
