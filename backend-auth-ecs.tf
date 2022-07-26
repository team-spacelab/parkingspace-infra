resource "aws_ecs_task_definition" "auth" {
  family = "parkingspace-backend-auth"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  cpu = 256
  memory = 512

  container_definitions = jsonencode([{
    name = "auth"
    image = "${aws_ecr_repository.auth.name}"
    cpu = 256
    memory = 512
    essential = true
    portMappings = [{
      containerPort = 80
    }]
  }])

  runtime_platform {
    operating_system_family = "LINUX"
  }
}

resource "aws_ecr_repository" "auth" {
  name = "parkingspace-backend-auth"
}
