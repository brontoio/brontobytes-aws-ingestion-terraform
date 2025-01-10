locals {
  tags = merge({ name = var.name }, var.tags)
}
