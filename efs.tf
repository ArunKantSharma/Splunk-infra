resource "aws_efs_file_system" "splunk_cold" {
  creation_token   = "${var.project_name}-cold-buckets"
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  tags = merge(local.common_tags, {
    Name      = "${var.project_name}-cold-buckets"
    Component = "Shared cold bucket storage for all indexers"
  })
}

resource "aws_efs_mount_target" "splunk_cold" {
  count = 3

  file_system_id  = aws_efs_file_system.splunk_cold.id
  subnet_id       = aws_subnet.private[count.index].id
  security_groups = [aws_security_group.efs.id]
}
