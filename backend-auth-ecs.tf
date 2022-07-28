resource "aws_ecs_task_definition" "auth" {
  family = "parkingspace-backend-auth"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  cpu = 256
  memory = 512

  container_definitions = jsonencode([{
    name = "auth"
    image = "${aws_ecr_repository.auth.name}:latest"
    cpu = 256
    memory = 512
    essential = true
    portMappings = [{
      containerPort = 3000
    }]
  }])

  runtime_platform {
    operating_system_family = "LINUX"
  }
}

resource "aws_ecs_service" "auth" {
  name = "auth"
  cluster = aws_ecs_cluster.backend.id
  task_definition = aws_ecs_task_definition.auth.arn

  desired_count = 2
  ordered_placement_strategy {
    type = "binpack"
    field = "cpu"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.auth.arn
    container_name = "auth"
    container_port = 3000
  }

  network_configuration {
    subnets = [
      aws_subnet.backend_a.id,
      aws_subnet.backend_c.id
    ]
    security_groups = [
      aws_security_group.backend.id
    ]
  }

  placement_constraints {
    type = "memberOf"
    expression = "attribute:ecs.availablity-zone in [ap-northeast-2a, ap-northeast-2c]"
  }

  lifecycle {
    ignore_changes = [
      desired_count
    ]
  }
}

resource "aws_ecr_repository" "auth" {
  name = "parkingspace-backend-auth"
}

resource "aws_appautoscaling_target" "auth" {
  max_capacity = 8
  min_capacity = 2

  resource_id = "service/${aws_ecs_cluster.backend.name}/${aws_ecs_service.auth.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace = "ecs"
}

resource "aws_appautoscaling_policy" "auth_mem" {
  name = "by-memory"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.auth.resource_id
  scalable_dimension = aws_appautoscaling_target.auth.scalable_dimension
  service_namespace = aws_appautoscaling_target.auth.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value = 80
  }
}

resource "aws_appautoscaling_policy" "auth_cpu" {
  name = "by-cpu"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.auth.resource_id
  scalable_dimension = aws_appautoscaling_target.auth.scalable_dimension
  service_namespace = aws_appautoscaling_target.auth.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 60
  }
}
