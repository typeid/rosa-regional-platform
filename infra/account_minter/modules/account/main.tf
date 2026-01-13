locals {
  name  = "${var.name}-${var.role}"
  email = "${var.email}+${local.name}@redhat.com"
}

resource "aws_organizations_account" "account" {
  name      = local.name
  email     = local.email
  parent_id = var.ou_id

  tags = var.tags
}
