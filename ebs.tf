resource "aws_ebs_volume" "indexer_data" {
  for_each = { for k, v in local.splunk_instances : k => v if v.role == "indexer" }

  availability_zone = local.azs[each.value.az_index]
  size              = var.indexer_data_volume_size
  type              = "gp3"
  encrypted         = true

  tags = merge(local.common_tags, {
    Name      = "${var.project_name}-${each.value.name}-hot-warm"
    Component = "Indexer Hot/Warm Storage"
  })
}

resource "aws_volume_attachment" "indexer_data" {
  for_each = aws_ebs_volume.indexer_data

  device_name = "/dev/sdf"
  volume_id   = each.value.id
  instance_id = aws_instance.splunk[each.key].id
}
