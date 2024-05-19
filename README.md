# Take Home Assignment

![](https://github.com/schottz/CrunchTakeHomeAssignment/blob/main/architecture.dot.png)

# Project Overview
The architecture goes beyond the assignment's scope and takes advantage of the attack surface reduction practice, that avoids as much as possible exposing services directly to the internet.

For that purpose, excepting the Load Balancer, all resources were kept inside private subnets, taking advantage of AWS VPC Endpoint service to avoid internet access on the interactions between AWS services.

```bash
resource "aws_vpc_endpoint" "ecr_endpoint" {
  vpc_endpoint_type = "Interface"
  vpc_id = aws_vpc.my_vpc.id
  service_name = "com.amazonaws.${var.region}.ecr.dkr"
  private_dns_enabled = true
  subnet_ids = [ for subnet in aws_subnet.private_subnets: subnet.id]
  security_group_ids = [aws_security_group.private_sg.id]
}
```

The database credentials are stored in the AWS Secrets Manager service and have a Lambda function aimed to rotate de credencials in a 30 day basis.

```bash
resource "aws_secretsmanager_secret" "db_secret" {
  name = "aurora_authbxsxbah_info"

  tags = {
    Name = "AuroraAuthInfo"
  }
}

resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = "root"
    password = random_password.db_password.result
  })
}

resource "aws_secretsmanager_secret_rotation" "rotation_policy" {
  secret_id           = aws_secretsmanager_secret.db_secret.id
  rotation_lambda_arn = aws_lambda_function.secret_rotation_lambda.arn

  rotation_rules {
    automatically_after_days = 30
  }
}
```

To avoid any attack coming from inside the container, a npm user was set up and is being used to run the application

```bash
RUN mkdir -p /app/log /home/npm && \ 
    chown -R npm:npm /app /home/npm && \
    touch /app/log/access.log && \
    chmod o+rwx /app/log/access.log
    
USER npm 
```

The application logs are being sent to a CloudWatch log group

```bash
resource "aws_cloudwatch_log_group" "ecs_container_logs" {
  name = "/ecs/take-home-container-logs"
}
```
# Deployment Instructions

## Github Actions Setup
### Basic Settings
On the project's main page, go to Settings > Secrets and Variables > Actions.

Then set the secrets needed by the pipeline to run on yout AWS account:
- AWS_REGION
- AWS_SECRET_ACCESS_KEY 
- AWS_ACCESS_KEY_ID 

### Infrastructure Provisioning
```bash
	#!/bin/bash
	git clone https://github.com/schottz/CrunchTakeHomeAssignment
	cd CrunchTakeHomeAssignment/Terraform
	terraform init
	terraform apply -auto-approve
```

### Application Deployment
1. Go to Actions menu on project's main page and re-run the workflow. This will build a new Docker image and push it to the AWS ECR Registry.
2. That's it! Wait for application to start.

# Postscript

The application wasn't working properly. Despite it starts, it complains about some typescript issue. Didn't find a way of fixing it rightaway and didn't want to take too long on this.

I didn't enable the monitoring alarms, but I think the code I've wrote can give a pretty good idea of how I work.