resource "aws_s3_bucket" "artifacts-bucket" {
  bucket = "${var.project_name}-${var.environment}-codebuild-artifacts"
  acl    = "private"
}



resource "aws_s3_bucket_policy" "artifacts-bucket-policy" {
  bucket = "${aws_s3_bucket.artifacts-bucket.id}"
 //name =

 policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "${var.project_name}-${var.environment}-artifacts-bucket-policy",
  "Statement": [
    {
      "Sid": "IPAllow",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
                "${aws_iam_role.codebuild-role.arn}"
                ]
              },
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.artifacts-bucket.arn}",
        "${aws_s3_bucket.artifacts-bucket.arn}/*"
      ]
    }
  ]
}
POLICY
}
//

resource "aws_cloudwatch_log_group" "iac-pipeline-logs-group" {
name = "${var.project_name}-${var.environment}-iac-pipeline-logs-group"
}

resource "aws_cloudwatch_log_stream" "iac-pipeline-logs-stream" {
name           = "${var.project_name}-${var.environment}-iac-pipeline-logs-stream"
log_group_name = "${aws_cloudwatch_log_group.iac-pipeline-logs-group.name}"
}


resource "aws_s3_bucket" "logs-bucket" {
  bucket = "${var.project_name}-${var.environment}-codebuild-logs"
  acl    = "private"
}


resource "aws_s3_bucket_policy" "logs-bucket-policy" {
  bucket = "${aws_s3_bucket.logs-bucket.id}"
 //name =

 policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "${var.project_name}-${var.environment}-logs-bucket-policy",
  "Statement": [
    {
      "Sid": "IPAllow",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
                "${aws_iam_role.codebuild-role.arn}"
                ]
              },
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": [
          "${aws_s3_bucket.logs-bucket.arn}",
          "${aws_s3_bucket.logs-bucket.arn}/*"
          ]
    }
  ]
}
POLICY
}

resource "aws_iam_role" "codebuild-role" {
  name = "${var.project_name}-${var.environment}-codebuild-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


resource "aws_iam_role_policy" "codebuild-role-policy" {
  name = "${var.project_name}--${var.environment}-codebuild-policy"
  role = "${aws_iam_role.codebuild-role.name}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "${aws_cloudwatch_log_group.iac-pipeline-logs-group.arn}",
        "${aws_cloudwatch_log_stream.iac-pipeline-logs-stream.arn}"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.artifacts-bucket.arn}",
        "${aws_s3_bucket.artifacts-bucket.arn}/*",
        "${aws_s3_bucket.logs-bucket.arn}",
        "${aws_s3_bucket.logs-bucket.arn}/*",
        "${aws_s3_bucket.codepipeline_bucket.arn}",
        "${aws_s3_bucket.codepipeline_bucket.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codecommit:*"
      ],
      "Resource": "${aws_codecommit_repository.app-repo.arn}"
    }
  ]
}
POLICY
}



resource "aws_codebuild_project" "codebuild-project" {
  name          = "${var.project_name}-${var.environment}-codebuild-project"
  description = "${var.project_name} ${var.environment} codebuild pipeline"
  build_timeout = "10"
  service_role  = "${aws_iam_role.codebuild-role.arn}"
  badge_enabled = true

/*
  cache {
    type     = "S3"
    location = "${aws_s3_bucket.artifacts-bucket.bucket}"
  }
  */

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:1.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
}

/*    environment_variable {
      name  = "SOME_KEY2"
      value = "SOME_VALUE2"
      type  = "PARAMETER_STORE"
    } */

  source {
    type            = "CODECOMMIT"
    location    = "${aws_codecommit_repository.app-repo.repository_name}"
    git_clone_depth = 1
      }

  artifacts {
        type = "S3"
        location    = "${aws_s3_bucket.artifacts-bucket.arn}"
      }

  logs_config {

  s3_logs {
        status  = "ENABLED"
        location = "${aws_s3_bucket.logs-bucket.arn}"
      }

      cloudwatch_logs {
        group_name  = "${aws_cloudwatch_log_group.iac-pipeline-logs-group.name}"
        stream_name = "${aws_cloudwatch_log_stream.iac-pipeline-logs-stream.name}"
      }

    }


  tags = {
    Project = "${var.project_name}"
    Environment = "${var.environment}"
    }
}
