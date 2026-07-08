resource "aws_instance" "splunk" {
  for_each = local.splunk_instances

  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = var.key_pair_name
  subnet_id     = aws_subnet.private[each.value.az_index].id

  vpc_security_group_ids = [aws_security_group.splunk_nodes.id]

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge(local.common_tags, {
    Name      = "${var.project_name}-${each.value.name}"
    Role      = each.value.role
    Component = each.value.component
    AZ        = local.azs[each.value.az_index]
  })
}
