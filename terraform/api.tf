
data "archive_file" "zip" {
  type        = "zip"
  source_file = "lambda_function.js"
  output_path = "lambda_function.zip"
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_secrets_manager_role"

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
}

resource "aws_iam_policy" "lambda_policy" {
  name = "lambda_secrets_manager_policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_role_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "passgobblers_api" {
  filename      = data.archive_file.zip.output_path
  function_name = "passgobblers-api"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.handler"
  runtime       = "nodejs18.x"

  environment {
    variables = {
      SECRET_NAME = aws_secretsmanager_secret.passgobbler-tester-access-keys.name
    }
  }
}


// API 


resource "aws_api_gateway_rest_api" "secrets_api" {
  name = "PASSGOBBLERS Secrets API"
}

resource "aws_api_gateway_resource" "secrets_resource" {
  rest_api_id = aws_api_gateway_rest_api.secrets_api.id
  parent_id   = aws_api_gateway_rest_api.secrets_api.root_resource_id
  path_part   = "secrets"
}

resource "aws_api_gateway_method" "get_secrets_method" {
  rest_api_id   = aws_api_gateway_rest_api.secrets_api.id
  resource_id   = aws_api_gateway_resource.secrets_resource.id
  http_method   = "GET"
  authorization = "NONE"
}


resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.secrets_api.id
  resource_id             = aws_api_gateway_resource.secrets_resource.id
  http_method             = aws_api_gateway_method.get_secrets_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.passgobblers_api.invoke_arn

}

resource "aws_api_gateway_method" "options_method" {
  rest_api_id   = aws_api_gateway_rest_api.secrets_api.id
  resource_id   = aws_api_gateway_resource.secrets_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.secrets_api.id
  resource_id = aws_api_gateway_resource.secrets_resource.id
  http_method = aws_api_gateway_method.options_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id = aws_api_gateway_rest_api.secrets_api.id
  resource_id = aws_api_gateway_resource.secrets_resource.id
  http_method = aws_api_gateway_method.options_method.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_integration_response" "options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.secrets_api.id
  resource_id = aws_api_gateway_resource.secrets_resource.id
  http_method = aws_api_gateway_method.options_method.http_method
  status_code = aws_api_gateway_method_response.options_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# Update existing GET method to include CORS headers
resource "aws_api_gateway_method_response" "get_200" {
  rest_api_id = aws_api_gateway_rest_api.secrets_api.id
  resource_id = aws_api_gateway_resource.secrets_resource.id
  http_method = aws_api_gateway_method.get_secrets_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "get_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.secrets_api.id
  resource_id = aws_api_gateway_resource.secrets_resource.id
  http_method = aws_api_gateway_method.get_secrets_method.http_method
  status_code = aws_api_gateway_method_response.get_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  depends_on = [
    aws_api_gateway_integration.lambda_integration
  ]
}

resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.passgobblers_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.secrets_api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "secrets_api_deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_integration.options_integration,
    aws_api_gateway_integration_response.options_integration_response,
    aws_api_gateway_integration_response.get_integration_response,
  ]

  rest_api_id = aws_api_gateway_rest_api.secrets_api.id
  stage_name  = "prod"
}