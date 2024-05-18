resource "random_password" "db_password" {
  length  = 16
  upper   = true
  lower   = true
  numeric = true
  special = true
}

data "archive_file" "lambda_file" {
  type        = "zip"
  source_file = "lambda_secret_rotation.py"
  output_path = "lambda_secret_rotation.zip"
}

resource "aws_lambda_function" "secret_rotation_lambda" {
  filename         = data.archive_file.lambda_file.output_path
  function_name    = "SecretsManagerRotation"
  role             = aws_iam_role.secret_rotation_lambda_role.arn
  handler          = "index.handler"
  runtime          = "python3.8"

  environment {
    variables = {
      SECRET_ID = aws_secretsmanager_secret.db_secret.id
    }
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_endpoint_type = "Interface"
  vpc_id = aws_vpc.my_vpc.id
  service_name = "com.amazonaws.${var.region}.ssm"
  private_dns_enabled = true
  subnet_ids = [ for subnet in aws_subnet.private_subnets: subnet.id]
  security_group_ids = [aws_security_group.private_sg.id]
}

resource "aws_ssm_parameter" "db_endpoint" {
  name        = "/crunch/db/endpoint"
  type        = "SecureString"
  value       = element(split(":", aws_rds_cluster.aurora_cluster.endpoint), 0)
}

resource "aws_secretsmanager_secret" "db_secret" {
  name = "aurora_authbxsbsxbah_info"

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

######################################################
#                    PERMISSIONS  
######################################################

resource "aws_lambda_permission" "allow_secretsmanager_invoke" {
  statement_id  = "AllowSecretsManagerInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.secret_rotation_lambda.function_name
  principal     = "secretsmanager.amazonaws.com"
}


resource "aws_iam_role" "secret_rotation_lambda_role" {
  name = "secret_rotation_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  ]
}

resource "aws_iam_role" "secretsmanager_invoke_lambda_role" {
  name = "secretsmanager_invoke_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "secretsmanager.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaRole",
  ]
}

resource "aws_iam_policy" "secretsmanager_invoke_lambda_policy" {
  name        = "SecretsManagerInvokeLambdaPolicy"
  description = "Policy for allowing Secrets Manager to invoke Lambda functions"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "lambda:InvokeFunction",
          "lambda:GetFunctionConfiguration"
        ],
        Effect   = "Allow",
        Resource = aws_lambda_function.secret_rotation_lambda.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "secretsmanager_invoke_lambda_attachment" {
  role       = aws_iam_role.secretsmanager_invoke_lambda_role.name
  policy_arn = aws_iam_policy.secretsmanager_invoke_lambda_policy.arn
}


#############################################################
#               VPC ENDPOINT
#############################################################

resource "aws_vpc_endpoint" "secretsmanager_endpoint" {
  vpc_endpoint_type = "Interface"
  vpc_id            = aws_vpc.my_vpc.id
  service_name      = "com.amazonaws.${var.region}.secretsmanager"
  subnet_ids = [ for subnet in aws_subnet.private_subnets: subnet.id]
  security_group_ids = [aws_security_group.private_sg.id]
}