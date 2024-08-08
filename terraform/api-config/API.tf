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


# Output the API URL
output "api_url" {
  value = "${aws_api_gateway_deployment.secrets_api_deployment.invoke_url}/secrets"
}