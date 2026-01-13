data "aws_organizations_organization" "org" {}

resource "aws_organizations_organizational_unit" "rrp" {
  name      = "ROSA Regional Platform"
  parent_id = data.aws_organizations_organization.org.roots[0].id
}

module "regions" {
  source = "./modules/region"

  for_each = var.region_definitions

  name        = each.value.name
  aws_region  = each.value.aws_region
  email       = var.email
  environment = each.value.environment
  ou_id       = aws_organizations_organizational_unit.rrp.id
  owner       = lookup(each.value, "owner", "")
}

variable "region_definitions" {
  description = "Region Configuration"
  type        = map(any)
  default     = {}
}
