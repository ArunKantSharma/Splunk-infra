data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
    #values =["ami-06067086cf86c58e6"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  az_labels = {
    "0" = "a"
    "1" = "b"
    "2" = "c"
  }

  common_tags = merge(var.tags, {
    Project = var.project_name
  })

  # Splunk TCP ports used across the cluster
  splunk_ports = {
    web_ui           = 8000
    management       = 8089
    forwarder        = 9997
    hec              = 8088
    kv_store         = 8191
    cluster_rep_8080 = 8080
    cluster_rep_8081 = 8081
    https            = 443
    ssh              = 22
  }

  # All 13 EC2 instances from the architecture diagram
  splunk_instances = {
    license_deployer = {
      name      = "license-manager-deployer"
      role      = "cluster-management"
      az_index  = 0
      component = "License Manager + Deployment Server + Deployer"
    }
    indexer_cluster_master = {
      name      = "indexer-cluster-master"
      role      = "cluster-management"
      az_index  = 0
      component = "Indexer Cluster Master"
    }
    search_head_1 = {
      name         = "search-head-1"
      role         = "search-head-cluster"
      az_index     = 0
      component    = "Search Head Cluster Node 1"
      behind_alb   = true
    }
    search_head_2 = {
      name         = "search-head-2"
      role         = "search-head-cluster"
      az_index     = 1
      component    = "Search Head Cluster Node 2"
      behind_alb   = true
    }
    search_head_3 = {
      name         = "search-head-3"
      role         = "search-head-cluster"
      az_index     = 2
      component    = "Search Head Cluster Node 3"
      behind_alb   = true
    }
    indexer_1 = {
      name      = "indexer-1"
      role      = "indexer"
      az_index  = 0
      component = "Indexer 1"
    }
    indexer_2 = {
      name      = "indexer-2"
      role      = "indexer"
      az_index  = 0
      component = "Indexer 2"
    }
    indexer_3 = {
      name      = "indexer-3"
      role      = "indexer"
      az_index  = 1
      component = "Indexer 3"
    }
    indexer_4 = {
      name      = "indexer-4"
      role      = "indexer"
      az_index  = 1
      component = "Indexer 4"
    }
    indexer_5 = {
      name      = "indexer-5"
      role      = "indexer"
      az_index  = 2
      component = "Indexer 5"
    }
    indexer_6 = {
      name      = "indexer-6"
      role      = "indexer"
      az_index  = 2
      component = "Indexer 6"
    }
    enterprise_security = {
      name      = "enterprise-security"
      role      = "standalone-search-head"
      az_index  = 0
      component = "Splunk Enterprise Security"
    }
    monitoring_console = {
      name      = "monitoring-console"
      role      = "standalone-search-head"
      az_index  = 1
      component = "Monitoring Console"
    }
  }

  search_head_cluster_keys = [
    "search_head_1",
    "search_head_2",
    "search_head_3",
  ]

  indexer_keys = [
    "indexer_1",
    "indexer_2",
    "indexer_3",
    "indexer_4",
    "indexer_5",
    "indexer_6",
  ]
}
