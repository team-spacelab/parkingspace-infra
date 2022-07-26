resource "aws_ecs_cluster" "backend" {
  name = "parkingspace-backend-ecs-cluster"

  setting {
    name = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"

      log_configuration {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.backend.name
      }
    }
  }
}

resource "aws_cloudwatch_log_group" "backend" {
  name = "parkingspace-backend-ecs"
}
