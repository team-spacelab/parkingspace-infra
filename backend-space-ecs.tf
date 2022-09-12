resource "aws_ecs_task_definition" "space" {
  family = "parkingspace-backend-space"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  cpu = 512
  memory = 1024
  task_role_arn = aws_iam_role.space_taskrole.arn
  execution_role_arn = aws_iam_role.space_fargate.arn

  container_definitions = jsonencode([{
    name = "space"
    image = "${aws_ecr_repository.space.name}:latest"
    cpu = 512
    memory = 1024
    essential = true
    portMappings = [{
      containerPort = 3000
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group = "${aws_cloudwatch_log_group.backend_inside.name}"
        awslogs-region = "ap-northeast-2"
        awslogs-stream-prefix = "space"
      }
    }
  }])

  runtime_platform {
    operating_system_family = "LINUX"
  }
}

resource "aws_iam_role" "space_taskrole" {
  name = "parkingspace-space-task-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "space_taskrole" {
  name = "parkingspace-space-task-policy"  
  role = aws_iam_role.space_taskrole.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "UploadSpacefile",
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.uploads.arn}/*",
      "Action": [
        "s3:PutObject"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role" "space_fargate" {
  name = "parkingspace-space-fargate-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "space_fargate" {
  name = "parkingspace-space-fargate-policy"  
  role = aws_iam_role.space_fargate.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowPushPull",
      "Effect": "Allow",
      "Resource": "${aws_ecr_repository.space.arn}",
      "Action": [
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer"
      ]
    },
    {
      "Sid": "AllowAuth",
      "Effect": "Allow",
      "Resource": "*",
      "Action": [
        "ecr:GetAuthorizationToken"
      ]
    },
    {
      "Sid": "CloudWatchLog",
      "Effect": "Allow",
      "Resource": "*",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    }
  ]
}
EOF
}

resource "aws_ecs_service" "space" {
  name = "space"
  cluster = aws_ecs_cluster.backend.id
  task_definition = aws_ecs_task_definition.space.arn
  launch_type = "FARGATE"

  desired_count = 2

  load_balancer {
    target_group_arn = aws_lb_target_group.space.arn
    container_name = "space"
    container_port = 3000
  }

  network_configuration {
    assign_public_ip = true
    subnets = [
      aws_subnet.backend_a.id,
      aws_subnet.backend_c.id
    ]
    security_groups = [
      aws_security_group.backend.id
    ]
  }

  lifecycle {
    ignore_changes = [
      desired_count,
      task_definition
    ]
  }
}

resource "aws_ecr_repository" "space" {
  name = "parkingspace-backend-space"
}

resource "aws_appautoscaling_target" "space" {
  max_capacity = 8
  min_capacity = 2

  resource_id = "service/${aws_ecs_cluster.backend.name}/${aws_ecs_service.space.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace = "ecs"
}

resource "aws_appautoscaling_policy" "space_mem" {
  name = "by-memory"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.space.resource_id
  scalable_dimension = aws_appautoscaling_target.space.scalable_dimension
  service_namespace = aws_appautoscaling_target.space.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value = 80
  }
}

resource "aws_appautoscaling_policy" "space_cpu" {
  name = "by-cpu"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.space.resource_id
  scalable_dimension = aws_appautoscaling_target.space.scalable_dimension
  service_namespace = aws_appautoscaling_target.space.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 60
  }
}
