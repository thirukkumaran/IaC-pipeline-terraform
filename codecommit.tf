
resource "aws_codecommit_repository" "app-repo" {
  repository_name = "${var.project_name}-${var.environment}-repo"
  description     = "${var.project_name} ${var.environment} App Repository"
  default_branch = "${var.branch}"

    tags = {
      Project = "${var.project_name}"
      Environment = "${var.environment}"
      }
}
