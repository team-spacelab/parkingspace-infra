resource "aws_codepipeline" "frontend" {
  name     = "parkingspace-frontend-pipeline"
  role_arn = aws_iam_role.frontend_pipeline.arn

  artifact_store {
    location = aws_s3_bucket.frontend_deploy.bucket
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
        FullRepositoryId = "team-spacelab/parkingspace-frontend"
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Website"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.frontend.name
      }
    }

    action {
      name = "Bubblewrap"
      category = "Build"
      owner = "AWS"
      provider = "CodeBuild"
      input_artifacts = ["source_output"]
      output_artifacts = ["bubblewrap_output"]
      version = "1"
      configuration = {
        ProjectName = aws_codebuild_project.frontend_bubblewrap.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Website"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        BucketName = aws_s3_bucket.frontend.id
        Extract = true
      }
    }

    action {
      name            = "Bubblewrap"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      input_artifacts = ["bubblewrap_output"]
      version         = "1"

      configuration = {
        BucketName = aws_s3_bucket.frontend.id
        Extract = true
      }
    }
  }
}

resource "aws_codebuild_project" "frontend" {
  name = "parkingspace-frontend-codebuild"
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image = "aws/codebuild/standard:6.0"
    type = "LINUX_CONTAINER"
  }
  service_role = aws_iam_role.frontend_build.arn
  source {
    type = "CODEPIPELINE"
  }
}

resource "aws_codebuild_project" "frontend_bubblewrap" {
  name = "parkingspace-frontend-bubblewrap-codebuild"
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image = "${aws_ecr_repository.bubblewrap.repository_url}:latest"
    type = "LINUX_CONTAINER"
    image_pull_credentials_type = "SERVICE_ROLE"
  }
  source {
    type = "CODEPIPELINE"
    buildspec = "buildspec_bubblewrap.yml"
  }
  service_role = aws_iam_role.frontend_bubblewrap_build.arn
}

resource "aws_s3_bucket" "frontend_deploy" {
  bucket_prefix = "parkingspace-frontend-codepipeline-"
}

resource "aws_s3_bucket_acl" "frontend" {
  bucket = aws_s3_bucket.frontend_deploy.id
  acl    = "private"
}

resource "aws_iam_role" "frontend_pipeline" {
  name = "parkingspace-frontend-codepipeline-role"

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

resource "aws_iam_role_policy" "frontend_pipeline" {
  name = "parkingspace-frontend-codepipeline-policy"
  role = aws_iam_role.frontend_pipeline.id

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
        "${aws_s3_bucket.frontend.arn}",
        "${aws_s3_bucket.frontend.arn}/*",
        "${aws_s3_bucket.frontend_deploy.arn}",
        "${aws_s3_bucket.frontend_deploy.arn}/*"
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

resource "aws_iam_role" "frontend_build" {
  name = "parkingspace-frontend-codebuild-role"

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

resource "aws_iam_role_policy" "frontend_build" {
  name = "parkingspace-frontend-codebuild-policy"
  role = aws_iam_role.frontend_build.id

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
        "${aws_s3_bucket.frontend_deploy.arn}",
        "${aws_s3_bucket.frontend_deploy.arn}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role" "frontend_bubblewrap_build" {
  name = "parkingspace-frontend-bubblewrap-codebuild-role"

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

resource "aws_iam_role_policy" "frontend_bubblewrap_build" {
  name = "parkingspace-frontend-bubblewrap-codebuild-policy"
  role = aws_iam_role.frontend_bubblewrap_build.id

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
        "${aws_s3_bucket.frontend_deploy.arn}",
        "${aws_s3_bucket.frontend_deploy.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:DescribeRepositories"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetRepositoryPolicy",
        "ecr:ListImages",
        "ecr:DescribeImages",
        "ecr:BatchGetImage",
        "ecr:GetLifecyclePolicy",
        "ecr:GetLifecyclePolicyPreview",
        "ecr:ListTagsForResource",
        "ecr:DescribeImageScanFindings"
      ],
      "Resource": "${aws_ecr_repository.bubblewrap.arn}"
    }
  ]
}
EOF
}
