################################################
#                  CLUSTER                     #
################################################

resource "aws_ecs_cluster" "take_home_cluster" {
  name = "take-home-cluster"
}

################################################
#             TASK DEFINITION                  #
################################################

resource "aws_ecs_task_definition" "my_task" {
  family                    = "takehome-family"
  requires_compatibilities  = ["FARGATE"]
  network_mode              = "awsvpc"
  execution_role_arn        = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn             = aws_iam_role.ecs_task_execution_role.arn
  cpu = 512
  memory = 2048
  container_definitions = jsonencode([
    {
      name  = "take-home-container",
      image = "${aws_ecr_repository.take_home_repo.repository_url}:latest",
      portMappings = [
        {
          containerPort = var.applicatio_port,
          hostPort      = var.applicatio_port,
        },
      ],
      logConfiguration = {
      logDriver = "awslogs",
      options = {
        "awslogs-group" = aws_cloudwatch_log_group.ecs_container_logs.name,
        "awslogs-region" = var.region,
        "awslogs-stream-prefix" = "take-home-container",
      }
    },
    secrets = [
        {
          name  = "PG_HOST"
          valueFrom = aws_ssm_parameter.db_endpoint.name
        },
        {
          name  = "POSTGRES_USER"
          valueFrom = "${aws_secretsmanager_secret.db_secret.arn}:username::"
        },
        {
          name  = "POSTGRES_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.db_secret.arn}:password::"
        }
      ],
    environment = [
        {
            name = "PG_PORT"
            value = var.db_port
        },
        {
            name = "POSTGRES_DB"
            value = var.db_instance_name
        }
      ]
    },
  ])
}

################################################
#               SERVICE                        #
################################################

resource "aws_ecs_service" "my_service" {
  name            = "take-home-service"
  cluster         = aws_ecs_cluster.take_home_cluster.id
  task_definition = aws_ecs_task_definition.my_task.arn
  launch_type     = "FARGATE"
  desired_count = 1
  network_configuration {
    subnets = [ for p_subnet in aws_subnet.private_subnets: p_subnet.id]
    security_groups = [
        aws_security_group.private_sg.id
    ]
  }
  
  load_balancer {
    target_group_arn = aws_lb_target_group.my_target_group.arn
    container_name   = "take-home-container"
    container_port   = var.applicatio_port
  }

  depends_on = [aws_ecs_task_definition.my_task]
}

################################################
#             IAM ROLE                         #
################################################


resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_task_execution_role.name

}

resource "aws_iam_role_policy_attachment" "ssm_readonly_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
  role       = aws_iam_role.ecs_task_execution_role.name
}

resource "aws_iam_role_policy_attachment" "ecr_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
  role       = aws_iam_role.ecs_task_execution_role.name
}

resource "aws_iam_role_policy_attachment" "sns_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSIoTDeviceDefenderPublishFindingsToSNSMitigationAction"
  role       = aws_iam_role.ecs_task_execution_role.name
}

resource "aws_iam_role_policy_attachment" "secretsmanager_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  role       = aws_iam_role.ecs_task_execution_role.name
}