resource "aws_secretsmanager_secret" "passgobbler-tester-access-keys" {
  name                    = "passgobblers-tester-keys"
  description             = "contains the access key and secret key for passgobbler api call"
  recovery_window_in_days = 0
}

locals {
  VITE_AWS_ACCESS_KEY_ID     = aws_iam_access_key.dynamodb_access_key.id
  VITE_AWS_SECRET_ACCESS_KEY = aws_iam_access_key.dynamodb_access_key.secret
  ENCRYPTION_KEY             = "3Hs7/0NUrLEhXwJKVsOWqHVLi8Aq4YHzCbexzq7m5LU=" // change
}

resource "aws_secretsmanager_secret_version" "access_keys" {
  secret_id = aws_secretsmanager_secret.passgobbler-tester-access-keys.id
  secret_string = jsonencode({
    VITE_AWS_ACCESS_KEY_ID     = local.VITE_AWS_ACCESS_KEY_ID
    VITE_AWS_SECRET_ACCESS_KEY = local.VITE_AWS_SECRET_ACCESS_KEY
    ENCRYPTION_KEY             = local.ENCRYPTION_KEY
  })
}