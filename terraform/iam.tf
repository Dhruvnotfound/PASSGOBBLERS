resource "aws_iam_user" "dynamodb_user" {
  name          = "passgobbler-tester"
  force_destroy = true
}

resource "aws_iam_access_key" "dynamodb_access_key" {
  user       = aws_iam_user.dynamodb_user.name
  depends_on = [aws_iam_user.dynamodb_user]
}

resource "aws_iam_user_policy" "dynamodb_policy" {
  name = "passgobbler-tester-dynamodb-policy"
  user = aws_iam_user.dynamodb_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "Statement1"
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:ListTables"
        ]
        Resource = aws_dynamodb_table.pass-storage.arn
      }
    ]
  })
}

