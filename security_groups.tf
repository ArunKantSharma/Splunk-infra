resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for Splunk Application Load Balancer"
  vpc_id      = aws_vpc.splunk.id

  ingress {
    description = "HTTPS from internet"
    from_port   = local.splunk_ports.https
    to_port     = local.splunk_ports.https
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  ingress {
    description = "Splunk Web UI from internet"
    from_port   = local.splunk_ports.web_ui
    to_port     = local.splunk_ports.web_ui
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  ingress {
    description     = "Splunk Web UI from NLB"
    from_port       = local.splunk_ports.web_ui
    to_port         = local.splunk_ports.web_ui
    protocol        = "tcp"
    security_groups = [aws_security_group.nlb.id]
  }

  ingress {
    description     = "HTTPS from NLB"
    from_port       = local.splunk_ports.https
    to_port         = local.splunk_ports.https
    protocol        = "tcp"
    security_groups = [aws_security_group.nlb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-alb-sg"
  })
}

resource "aws_security_group" "nlb" {
  name        = "${var.project_name}-nlb-sg"
  description = "Security group for Splunk Network Load Balancer"
  vpc_id      = aws_vpc.splunk.id

  ingress {
    description = "HTTPS from internet"
    from_port   = local.splunk_ports.https
    to_port     = local.splunk_ports.https
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  ingress {
    description = "Splunk Web UI from internet"
    from_port   = local.splunk_ports.web_ui
    to_port     = local.splunk_ports.web_ui
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-nlb-sg"
  })
}

resource "aws_security_group" "splunk_nodes" {
  name        = "${var.project_name}-nodes-sg"
  description = "Security group for all Splunk EC2 instances"
  vpc_id      = aws_vpc.splunk.id

  # SSH
  ingress {
    description = "SSH administration"
    from_port   = local.splunk_ports.ssh
    to_port     = local.splunk_ports.ssh
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  # Splunk Web UI - from ALB and VPC
  ingress {
    description     = "Splunk Web UI from ALB"
    from_port       = local.splunk_ports.web_ui
    to_port         = local.splunk_ports.web_ui
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "Splunk Web UI internal"
    from_port   = local.splunk_ports.web_ui
    to_port     = local.splunk_ports.web_ui
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # HTTPS
  ingress {
    description = "HTTPS"
    from_port   = local.splunk_ports.https
    to_port     = local.splunk_ports.https
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr, var.admin_cidr]
  }

  # splunkd management / REST API
  ingress {
    description = "Splunk management port 8089"
    from_port   = local.splunk_ports.management
    to_port     = local.splunk_ports.management
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Forwarder receiving port
  ingress {
    description = "Splunk forwarder receiving port 9997"
    from_port   = local.splunk_ports.forwarder
    to_port     = local.splunk_ports.forwarder
    protocol    = "tcp"
    cidr_blocks = concat([var.vpc_cidr], var.forwarder_cidr_blocks)
  }

  # HEC
  ingress {
    description = "HTTP Event Collector 8088"
    from_port   = local.splunk_ports.hec
    to_port     = local.splunk_ports.hec
    protocol    = "tcp"
    cidr_blocks = concat([var.vpc_cidr], var.forwarder_cidr_blocks)
  }

  # KV Store
  ingress {
    description = "KV Store 8191"
    from_port   = local.splunk_ports.kv_store
    to_port     = local.splunk_ports.kv_store
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Cluster replication
  ingress {
    description = "Indexer/SH cluster replication 8080"
    from_port   = local.splunk_ports.cluster_rep_8080
    to_port     = local.splunk_ports.cluster_rep_8080
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Indexer/SH cluster replication 8081"
    from_port   = local.splunk_ports.cluster_rep_8081
    to_port     = local.splunk_ports.cluster_rep_8081
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-nodes-sg"
  })
}

resource "aws_security_group" "efs" {
  name        = "${var.project_name}-efs-sg"
  description = "Security group for Splunk EFS cold storage"
  vpc_id      = aws_vpc.splunk.id

  ingress {
    description     = "NFS from Splunk indexers"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.splunk_nodes.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-efs-sg"
  })
}
