terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5"
    }
  }
}

variable "r2_access_key" {}
variable "r2_secret_key" {}
variable "r2_account_id" {}

provider "aws" {
  alias = "aws"
  region = "us-east-2"
}

provider "aws" {
  alias = "r2"
  region = "auto"

  access_key = var.r2_access_key
  secret_key = var.r2_secret_key

  skip_credentials_validation = true
  skip_region_validation      = true
  skip_requesting_account_id  = true

  endpoints {
    s3 = "https://${var.r2_account_id}.r2.cloudflarestorage.com"
  }
}


# Bucket
resource "aws_s3_bucket" "byteshare-blob" {
  provider = aws.r2
  bucket = "byteshare-blob"
}

resource "aws_s3_bucket_lifecycle_configuration" "expire-object" {
  provider = aws.r2
  bucket = aws_s3_bucket.byteshare-blob.id

  rule {
    id     = "expire_object"
    status = "Enabled"
    expiration {
      days = 60
    }
  }
}

resource "aws_s3_bucket_cors_configuration" "allow-cors" {
  provider = aws.r2
  bucket = aws_s3_bucket.byteshare-blob.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "GET", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["Content-Length", "Content-Type"]
  }
}

# DynamoDB table
resource "aws_dynamodb_table" "byteshare-upload-metadata" {
  provider = aws.aws
  name         = "byteshare-upload-metadata"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "upload_id"

  attribute {
    name = "upload_id"
    type = "S"
  }

  attribute {
    name = "creator_id"
    type = "S"
  }

  global_secondary_index {
    name               = "userid-gsi"
    hash_key           = "creator_id"
    projection_type    = "ALL"
  }
}

resource "aws_dynamodb_table" "byteshare-user" {
  provider = aws.aws
  name         = "byteshare-user"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_id"

  attribute {
    name = "user_id"
    type = "S"
  }
}

resource "aws_dynamodb_table" "byteshare-feedback" {
  provider = aws.aws
  name         = "byteshare-feedback"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "feedback_id"

  attribute {
    name = "feedback_id"
    type = "S"
  }
}

resource "aws_dynamodb_table" "byteshare-subscriber" {
  provider = aws.aws
  name         = "byteshare-subscriber"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "email"
  range_key    = "created_at"

  attribute {
    name = "email"
    type = "S"
  }
  attribute {
    name = "created_at"
    type = "S"
  }
}


resource "aws_dynamodb_table" "byteshare-apikey" {
  provider = aws.aws
  name         = "byteshare-apikey"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_id"

  attribute {
    name = "user_id"
    type = "S"
  }
  attribute {
    name = "apikey"
    type = "S"
  }
  

  global_secondary_index {
    name               = "apikey-gsi"
    hash_key           = "apikey"
    projection_type    = "ALL"
  }
}


resource "aws_iam_role" "api_gateway_invoke_role" {
  provider = aws.aws
  name               = "ByteShareAPIInvokeRole"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : aws_iam_user.unprivileged_user.arn
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "api_gateway_invoke_policy_attachment" {
  provider = aws.aws
  name = "api_gateway_invoke_policy_attachment"
  policy_arn = "arn:aws:iam::aws:policy/AmazonAPIGatewayInvokeFullAccess"
  roles       = [aws_iam_role.api_gateway_invoke_role.name]
}

resource "aws_iam_user" "unprivileged_user" {
  provider = aws.aws
  name = "byteshare-ui"
}

resource "aws_iam_policy" "assume_role_policy" {
  provider = aws.aws
  name        = "assume_role_policy"
  description = "Allows user to assume the role"
  policy      = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "sts:AssumeRole",
        "Resource" : aws_iam_role.api_gateway_invoke_role.arn
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "assume_role_policy_attachment" {
  provider = aws.aws
  user       = aws_iam_user.unprivileged_user.name
  policy_arn = aws_iam_policy.assume_role_policy.arn
}