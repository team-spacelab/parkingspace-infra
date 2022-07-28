resource "aws_codepipeline" "auth" {
  name     = "parkingspace-auth-pipeline"
  role_arn = aws_iam_role.auth_pipeline.arn

  artifact_store {
    location = aws_s3_bucket.auth_deploy.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.conn.arn
        FullRepositoryId = "team-spacelab/parkingspace-auth"
        BranchName       = "main"
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
        ProjectName = aws_codebuild_project.auth.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ClusterName = aws_ecs_cluster.backend.name
        ServiceName = aws_ecs_service.auth.name
        FileName = "imagedefinitions.json"
        DeploymentTimeout = "5"
      }
    }
  }
}

resource "aws_codebuild_project" "auth" {
  name = "parkingspace-auth-codebuild"
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image = "aws/codebuild/standard:6.0"
    type = "LINUX_CONTAINER"
    privileged_mode = true
  }
  service_role = aws_iam_role.auth_build.arn
  source {
    type = "CODEPIPELINE"
  }
}

resource "aws_s3_bucket" "auth_deploy" {
  bucket_prefix = "parkingspace-auth-codepipeline-"
}

resource "aws_s3_bucket_acl" "auth" {
  bucket = aws_s3_bucket.auth_deploy.id
  acl    = "private"
}

resource "aws_iam_role" "auth_pipeline" {
  name = "parkingspace-auth-codepipeline-role"

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

resource "aws_iam_role_policy" "auth_pipeline" {
  name = "parkingspace-auth-codepipeline-policy"
  role = aws_iam_role.auth_pipeline.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObjectAcl",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.auth_deploy.arn}",
        "${aws_s3_bucket.auth_deploy.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codestar-connections:UseConnection"
      ],
      "Resource": "${aws_codestarconnections_connection.conn.arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "auth_build" {
  name = "parkingspace-auth-codebuild-role"

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

resource "aws_iam_role_policy" "auth_build" {
  name = "parkingspace-auth-codebuild-policy"
  role = aws_iam_role.auth_build.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObjectAcl",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.auth_deploy.arn}",
        "${aws_s3_bucket.auth_deploy.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
          "ecr:CompleteLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:InitiateLayerUpload",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage"
      ],
      "Resource": "${aws_ecr_repository.auth.arn}"
    },
    {
        "Effect": "Allow",
        "Action": "ecr:GetAuthorizationToken",
        "Resource": "*"
    }
  ]
}
EOF
}

