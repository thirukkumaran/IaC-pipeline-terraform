resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "${var.project_name}-${var.environment}-codepipeline-artifacts"
  acl    = "private"
}

resource "aws_s3_bucket_policy" "codepipeline_bucket_policy" {
  bucket = "${aws_s3_bucket.codepipeline_bucket.id}"
 //name =

 policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "${var.project_name}-${var.environment}-codepipeline-bucket-policy",
  "Statement": [
    {
      "Sid": "IPAllow",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
                "${aws_iam_role.codepipeline_role.arn}"
                ]
              },
      "Action":  [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": [
             "${aws_s3_bucket.codepipeline_bucket.arn}",
           "${aws_s3_bucket.codepipeline_bucket.arn}/*"

         ]
    }
  ]
}
POLICY
}
//

resource "aws_iam_role" "codepipeline_role" {
  name = "${var.project_name}-${var.environment}-codepipeline-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${var.project_name}-${var.environment}-codepipeline-policy"
  role = "${aws_iam_role.codepipeline_role.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.codepipeline_bucket.arn}",
        "${aws_s3_bucket.codepipeline_bucket.arn}/*",
        "${aws_s3_bucket.artifacts-bucket.arn}",
        "${aws_s3_bucket.artifacts-bucket.arn}/*",
        "${aws_s3_bucket.logs-bucket.arn}",
        "${aws_s3_bucket.logs-bucket.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codecommit:*",
        "codebuild:*"
      ],
      "Resource":  [
        "${aws_codecommit_repository.app-repo.arn}",
        "${aws_codebuild_project.codebuild-project.arn}"
      ]
    }
  ]
}
EOF
}



/*
data "aws_kms_alias" "s3kmskey" {
  name = "alias/myKmsKey"
}
*/

resource "aws_codepipeline" "codepipeline" {
  name     = "${var.project_name}-${var.environment}-codepipeline"
  role_arn = "${aws_iam_role.codepipeline_role.arn}"


  artifact_store {
    location = "${aws_s3_bucket.codepipeline_bucket.bucket}"
    type     = "S3"

  /*  encryption_key {
      id   = "${data.aws_kms_alias.s3kmskey.arn}"
      type = "KMS"
    } */
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName   = "${aws_codecommit_repository.app-repo.repository_name}"
        BranchName = "${var.branch}"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = "${aws_codebuild_project.codebuild-project.name}"
      }
    }
  }

  tags = {
    Project = "${var.project_name}"
    Environment = "${var.environment}"
    }

/*  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CloudFormation"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration {
        ActionMode     = "REPLACE_ON_FAILURE"
        Capabilities   = "CAPABILITY_AUTO_EXPAND,CAPABILITY_IAM"
        OutputFileName = "CreateStackOutput.json"
        StackName      = "MyStack"
        TemplatePath   = "build_output::sam-templated.yaml"
      }
    }
  } */
}
