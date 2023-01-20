terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-west-1"
}

resource "random_password" "postgres" {
  length  = 16
  special = false
}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

resource "aws_default_subnet" "default_az1b" {
  availability_zone = "us-west-1b"
}

resource "aws_default_subnet" "default_az1c" {
  availability_zone = "us-west-1c"

}

resource "aws_default_security_group" "default" {
  vpc_id = aws_default_vpc.default.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    protocol         = "tcp"
    from_port        = 443
    to_port          = 443
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}

resource "aws_db_instance" "postgres" {
  allocated_storage   = 10
  db_name             = "computerstore"
  engine              = "postgres"
  instance_class      = "db.t3.micro"
  username            = "computerstore_user"
  password            = random_password.postgres.result
  publicly_accessible = true
}

resource "aws_ecr_repository" "computerstore" {
  name                 = "computerstore"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name = "computerstore-ecsTaskRole"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_policy" "task_policy" {
  name        = "computerstore-task-policy"
  description = "Policy that allows access to rds"

  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
       {
           "Effect": "Allow",
           "Action": ["rds:*"],
           "Resource": "*"
       },
       {
            "Effect": "Allow",
            "Action": [
                "ecr:DescribeImageScanFindings",
                "ecr:GetLifecyclePolicyPreview",
                "ecr:GetDownloadUrlForLayer",
                "ecr:DescribeImageReplicationStatus",
                "ecr:ListTagsForResource",
                "ecr:ListImages",
                "ecr:BatchGetRepositoryScanningConfiguration",
                "ecr:BatchGetImage",
                "ecr:DescribeImages",
                "ecr:DescribeRepositories",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetRepositoryPolicy",
                "ecr:GetLifecyclePolicy"
            ],
            "Resource": "*"
        }
   ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-task-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.task_policy.arn
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "computerstore-ecsTaskExecutionRole"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_cluster" "computerstore" {
  name = "computerstore"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "example" {
  cluster_name = aws_ecs_cluster.computerstore.name

  capacity_providers = ["FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE_SPOT"
  }
}

resource "aws_cloudwatch_log_group" "app" {
  name = "computerstore"
}

resource "aws_lb" "app" {
  name                       = "computerstore"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_default_security_group.default.id]
  subnets                    = [aws_default_subnet.default_az1c.id, aws_default_subnet.default_az1b.id]
  enable_deletion_protection = false
}

resource "aws_alb_target_group" "app" {
  name        = "computerstore"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_default_vpc.default.id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/"
    unhealthy_threshold = "2"
  }
  depends_on = [aws_lb.app]
}

resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_acm_certificate" "app" {
  domain_name       = "computerstore.danieltiesling.com"
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_alb_listener" "https" {
  load_balancer_arn = aws_lb.app.arn
  port              = 443
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = aws_acm_certificate.app.arn

  default_action {
    target_group_arn = aws_alb_target_group.app.arn
    type             = "forward"
  }

}

resource "aws_ecs_task_definition" "app" {
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  runtime_platform {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }
  execution_role_arn    = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn         = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([
    {
      name            = "app"
      image           = "${aws_ecr_repository.computerstore.repository_url}:latest"
      essential       = true
      runtimePlatform = {
        "operatingSystemFamily" : "LINUX",
        "cpuArchitecture" : "ARM64"
      },
      environment = [
        {
          "name" : "PROD"
          "value" : "true"
        },
        {
          "name" : "DB_PASSWORD"
          "value" : aws_db_instance.postgres.password
        },
        {
          "name" : "DB_HOST"
          "value" : aws_db_instance.postgres.address
        },
        {
          "name" : "DB_PORT"
          "value" : tostring(aws_db_instance.postgres.port)
        },
        {
          "name" : "API_HOST",
          "value" : "https://computerstore.danieltiesling.com"
        }
      ]
      portMappings = [
        {
          protcol       = "tcp"
          containerPort = 8080
          hostPort      = 8080
        }
      ]
      logConfiguration = {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : aws_cloudwatch_log_group.app.name,
          "awslogs-region" : "us-west-1",
          "awslogs-stream-prefix" : "computerstore"
        }
      }
    }
  ])
  family = "app"
}

resource "aws_ecs_service" "app" {
  name            = "app"
  cluster         = aws_ecs_cluster.computerstore.arn
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = [aws_default_subnet.default_az1c.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_alb_target_group.app.arn
    container_name   = "app"
    container_port   = 8080
  }
}

resource "aws_route53_zone" "computerstore" {
  name = "danieltiesling.com"
}

resource "aws_route53_record" "computerstore" {
  name    = "computerstore.danieltiesling.com"
  type    = "A"
  zone_id = aws_route53_zone.computerstore.zone_id
  alias {
    evaluate_target_health = true
    name                   = "dualstack.${aws_lb.app.dns_name}"
    zone_id                = aws_lb.app.zone_id
  }
}

resource "aws_route53_record" "ssl" {
  zone_id = aws_route53_zone.computerstore.zone_id
  name    = "_063a31852f1c4aac7b1527f28b8d01b3.computerstore.danieltiesling.com"
  type    = "CNAME"
  ttl     = 300
  records = ["_2023da956f5f8eaa9712564042a32694.kqlycvwlbp.acm-validations.aws."]
}

