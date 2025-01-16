variable "aws_region" {
  description = "AWS Region to deploy the resources"
  type        = string
}

variable "vpc_name" {
  description = "Name of the existing VPC"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "Instance type for the EC2 instance"
  type        = string
  default     = "t2.micro"
}

variable "ec2_role_name" {
  description = "IAM Role name for EC2"
  type        = string
}

variable "security_group_name" {
  description = "Name of the security group"
  type        = string
}

variable "environment" {
  description = "Environment for the deployment (dev, hom, prod)"
  type        = string
}
