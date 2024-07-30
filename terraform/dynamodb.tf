## make sure the user have the following polices
##           {
#    "Version": "2012-10-17",
#    "Statement": [
#        {
#            "Sid": "Statement1",
#            "Effect": "Allow",
#            "Action": [
#                "dynamodb:PutItem",
#                "dynamodb:GetItem",
#                "dynamodb:UpdateItem",
#                "dynamodb:DeleteItem",
#                "dynamodb:Scan",
#                "dynamodb:Query",
#                "dynamodb:ListTables"
#            ],
#            "Resource": [
#                arn:aws:dynamodb:{Region}:{Account}:table/{TableName} ## change the {} here to yours
#            ]
#        }
#    ]
#}


resource "aws_dynamodb_table" "pass-storage" {
  name         = "passgobblers-storage"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "site"
  range_key    = "username"

  attribute {
    name = "site"
    type = "S"
  }
  attribute {
    name = "username"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = "passgobblers"
    Environment = "dev"
  }
}