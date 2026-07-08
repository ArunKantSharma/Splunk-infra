variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "aws_profile" {
  description = "AWS CLI profile from local ~/.aws/credentials"
  type        = string
  default     = "default"
}

variable "project_name" {
  description = "Prefix for all Splunk infrastructure resources"
  type        = string
  default     = "splunk"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_type" {
  description = "EC2 instance type for all Splunk nodes"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "EC2 key pair name in AWS (not the .ppk/.pem filename — use the key name only, e.g. Splunk-server)"
  type        = string
  default     = "Splunk-server"
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 30
}

variable "indexer_data_volume_size" {
  description = "Additional EBS volume size per indexer for hot/warm data (GB)"
  type        = number
  default     = 100
}

variable "admin_cidr" {
  description = "CIDR allowed for SSH and Splunk Web UI access"
  type        = string
  default     = "0.0.0.0/0"
}

variable "forwarder_cidr_blocks" {
  description = "CIDR blocks allowed to send data on TCP 9997 (on-prem forwarders)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "domain_name" {
  description = "Route 53 hosted zone domain for Splunk Web (e.g. example.com). Leave empty to skip DNS."
  type        = string
  default     = ""
}

variable "splunk_web_subdomain" {
  description = "Subdomain for Splunk Web UI (e.g. splunk -> splunk.example.com)"
  type        = string
  default     = "splunk"
}

variable "certificate_arn" {
  description = "Optional ACM certificate ARN for ALB HTTPS listener. Required if domain_name is not set but HTTPS is needed."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Application = "splunk"
    ManagedBy   = "terraform"
  }
}

