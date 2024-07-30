resource "aws_secretsmanager_secret" "passgobbler-tester-access-keys" {
  name        = "passgobblers-tester-ak"
  description = "contains the access key and secret key for passgobbler api call"
}

locals {
  VITE_AWS_ACCESS_KEY_ID     = aws_iam_access_key.dynamodb_access_key.id
  VITE_AWS_SECRET_ACCESS_KEY = aws_iam_access_key.dynamodb_access_key.secret
}

resource "aws_secretsmanager_secret_version" "access_keys" {
  secret_id = aws_secretsmanager_secret.passgobbler-tester-access-keys.id
  secret_string = jsonencode({
    VITE_AWS_ACCESS_KEY_ID     = local.VITE_AWS_ACCESS_KEY_ID
    VITE_AWS_SECRET_ACCESS_KEY = local.VITE_AWS_SECRET_ACCESS_KEY
  })
}