resource "aws_ecs_cluster" "app_cluster" {
  name = "passgobblers-cluster"
}

resource "aws_vpc" "app_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "passgobblers-vpc"
  }
}

# Create subnets
resource "aws_subnet" "app_subnet_1" {
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "app_subnet_2" {
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_internet_gateway" "app_gateway" {
  vpc_id = aws_vpc.app_vpc.id
}

resource "aws_route_table" "app_route" {
  vpc_id = aws_vpc.app_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app_gateway.id
  }
}

resource "aws_route_table_association" "app_route_public_1" {
  route_table_id = aws_route_table.app_route.id
  subnet_id = aws_subnet.app_subnet_1.id
}

resource "aws_route_table_association" "app_route_public_2" {
  route_table_id = aws_route_table.app_route.id
  subnet_id = aws_subnet.app_subnet_2.id
}

resource "aws_security_group" "app_sg" {
  name        = "passgobblers-sg"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.app_vpc.id

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "app_service" {
  name            = "passgobblers-service"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.app_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = [aws_subnet.app_subnet_1.id, aws_subnet.app_subnet_2.id]
    assign_public_ip = true
    security_groups  = [aws_security_group.app_sg.id]
  }
}

resource "aws_ecs_task_definition" "app_task" {
  family                   = "passgobblers-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([{
    name  = "passgobblers-container"
    image = "dhruvnotfound/passgobbler:test" //change 
    portMappings = [{
      containerPort = 3000
      hostPort      = 3000
    }]
    # environment = [
    #   {
    #     name  = "VITE_AWS_ACCESS_KEY_ID"
    #     value = aws_iam_access_key.dynamodb_access_key.id
    #   },
    #   {
    #     name  = "VITE_AWS_SECRET_ACCESS_KEY"
    #     value = aws_iam_access_key.dynamodb_access_key.secret
    #   },
    #   {
    #     name  = "ENCRYPTION_KEY"
    #     value = var.encryption_key
    #   }
    # ]
  }])
}

# variable "encryption_key" {
#   default = "3Hs7/0NUrLEhXwJKVsOWqHVLi8Aq4YHzCbexzq7m5LU="
#   sensitive = true
# }