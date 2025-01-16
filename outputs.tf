output "ec2_instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.zipkin.id
}

output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_eip.zipkin_ip.public_ip
}

output "ec2_role_arn" {
  description = "ARN of the IAM role attached to the EC2 instance"
  value       = aws_iam_role.ec2_role.arn
}
