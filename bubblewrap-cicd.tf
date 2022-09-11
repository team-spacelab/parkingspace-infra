resource "aws_ecr_repository" "bubblewrap" {
  name = "parkingspace-cicd-bubblewrap"
}

resource "aws_codepipeline" "bubblewrap" {
  name     = "parkingspace-bubblewrap-pipeline"
  role_arn = aws_iam_role.bubblewrap_pipeline.arn

  artifact_store {
    location = aws_s3_bucket.bubblewrap_deploy.bucket
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
        FullRepositoryId = "team-spacelab/parkingspace-bubblewrap"
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
        ProjectName = aws_codebuild_project.bubblewrap.name
      }
    }
  }
}

resource "aws_codebuild_project" "bubblewrap" {
  name = "parkingspace-bubblewrap-codebuild"
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image = "aws/codebuild/standard:6.0"
    type = "LINUX_CONTAINER"
    privileged_mode = true
  }
  service_role = aws_iam_role.bubblewrap_build.arn
  source {
    type = "CODEPIPELINE"
  }
}

resource "aws_s3_bucket" "bubblewrap_deploy" {
  bucket_prefix = "parkingspace-bubblewrap-codepipeline-"
}

resource "aws_s3_bucket_acl" "bubblewrap" {
  bucket = aws_s3_bucket.bubblewrap_deploy.id
  acl    = "private"
}

resource "aws_iam_role" "bubblewrap_pipeline" {
  name = "parkingspace-bubblewrap-codepipeline-role"

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

resource "aws_iam_role_policy" "bubblewrap_pipeline" {
  name = "parkingspace-bubblewrap-codepipeline-policy"
  role = aws_iam_role.bubblewrap_pipeline.id

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
        "${aws_s3_bucket.bubblewrap_deploy.arn}",
        "${aws_s3_bucket.bubblewrap_deploy.arn}/*"
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

resource "aws_iam_role" "bubblewrap_build" {
  name = "parkingspace-bubblewrap-codebuild-role"

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

resource "aws_iam_role_policy" "bubblewrap_build" {
  name = "parkingspace-bubblewrap-codebuild-policy"
  role = aws_iam_role.bubblewrap_build.id

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
        "ecr:GetAuthorizationToken",
        "ecr:DescribeRepositories"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect":"Allow",
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
        "ecr:DescribeImageScanFindings",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:PutImage"
      ],
      "Resource": [
        "${aws_ecr_repository.bubblewrap.arn}"
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
        "${aws_s3_bucket.bubblewrap_deploy.arn}",
        "${aws_s3_bucket.bubblewrap_deploy.arn}/*"
      ]
    }
  ]
}
EOF
}

