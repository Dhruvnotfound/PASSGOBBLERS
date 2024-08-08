data "archive_file" "zip" {
  type        = "zip"
  source_file = "lambda_function.js"
  output_path = "lambda_function.zip"
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
