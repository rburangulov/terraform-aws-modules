resource "aws_ecr_repository" "ecs" {
  name                 = var.name
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}
