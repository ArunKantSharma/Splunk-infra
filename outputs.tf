output "vpc_id" {
  description = "Splunk VPC ID"
  value       = aws_vpc.splunk.id
}

output "nlb_dns_name" {
  description = "Network Load Balancer DNS name (static Elastic IPs attached)"
  value       = aws_lb.nlb.dns_name
}

output "nlb_elastic_ip" {
  description = "Static Elastic IP on the NLB"
  value       = aws_eip.nlb.public_ip
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = aws_lb.alb.dns_name
}

output "splunk_web_url" {
  description = "Splunk Web UI URL via ALB"
  value       = "http://${aws_lb.alb.dns_name}:${local.splunk_ports.web_ui}"
}

output "route53_fqdn" {
  description = "Route 53 FQDN for Splunk Web (if domain configured)"
  value       = var.domain_name != "" ? "${var.splunk_web_subdomain}.${var.domain_name}" : null
}

output "efs_id" {
  description = "EFS file system ID for cold bucket storage"
  value       = aws_efs_file_system.splunk_cold.id
}

output "efs_dns_name" {
  description = "EFS DNS name for mounting on indexers"
  value       = aws_efs_file_system.splunk_cold.dns_name
}

output "ec2_instances" {
  description = "Map of all Splunk EC2 instances with private IPs"
  value = {
    for k, inst in aws_instance.splunk : k => {
      name       = local.splunk_instances[k].name
      role       = local.splunk_instances[k].role
      component  = local.splunk_instances[k].component
      instance_id = inst.id
      private_ip  = inst.private_ip
      az          = inst.availability_zone
    }
  }
}

output "search_head_cluster_ips" {
  description = "Private IPs of Search Head Cluster nodes (behind ALB)"
  value = [
    for k in local.search_head_cluster_keys : aws_instance.splunk[k].private_ip
  ]
}

output "indexer_private_ips" {
  description = "Private IPs of all 6 indexers (for forwarder configuration)"
  value = [
    for k in local.indexer_keys : aws_instance.splunk[k].private_ip
  ]
}

output "security_group_id" {
  description = "Security group ID for Splunk nodes"
  value       = aws_security_group.splunk_nodes.id
}
