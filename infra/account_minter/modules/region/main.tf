locals {
  // If environment is dev, region is not necessary
  name = var.environment == "dev" ? join("-", [var.name, var.environment]) : join("-", [var.name, var.environment, var.aws_region])

  tag_owner = var.owner != "" ? { owner : "${var.owner}" } : {}
}

module "regional_cluster" {
  source = "../account"

  name        = local.name
  aws_region  = var.aws_region
  email       = var.email
  environment = var.environment
  ou_id       = var.ou_id
  role        = "regional-cluster"

  tags = merge(
    var.tags,
    local.tag_owner
  )
}

# module "management_cluster_0" {
#   source = "../account"
# 
#   name        = local.name
#   aws_region  = var.aws_region
#   environment = var.environment
#   ou_id       = var.ou_id
#   role        = "management-cluster-0"
# 
#   tags = merge(
#     var.tags,
#     local.tag_owner
#   )
# }
