# Configuracion que contiene los recursos para definir el Backend

# Bucket que contiene los TF State
resource "aws_s3_bucket" "bucket-state" {
    bucket = "s3-dev-aws-${var.account}-backend"
    object_lock_enabled = true

    tags = {
        Description  = "Bucket que almacena el backend de Terraform en la cuenta"
        Environment  = "Desarrollo"
        CreationDate = var.date

    }
}

resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.bucket-state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encryption" {
  bucket = aws_s3_bucket.bucket-state.id
    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
        }
    }
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.bucket-state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Tabla Dynamo para guardar los LOCK FILE

resource "aws_dynamodb_table" "terraform-lock" {
    name           = "dynamodb-dev-aws-${var.account}-backend"
    read_capacity  = 5
    write_capacity = 5
    hash_key       = "LockID"
    attribute {
        name = "LockID"
        type = "S"
    }
    server_side_encryption {
        enabled = true
    }

    tags = {
    Description  = "Tabla que almacena el backend de Terraform en la cuenta"
    Environment  = "Desarrollo"
    CreationDate = var.date
    }
}

# Rol que permite leer y escribir en S3 y DynamoDB
resource "aws_iam_role" "test_role_lab123" {
  name = "test_role_lab123"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "my_inline_policy"

    policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "S3access",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject"
            ],
            "Resource": "arn:aws:s3:::s3-dev-aws-demolab1234-backend/*"
        },
        {
            "Sid": "DynamoAccess",
            "Effect": "Allow",
            "Action": [
                "dynamodb:PutItem",
                "dynamodb:GetItem"
            ],
            "Resource": "arn:aws:dynamodb:us-east-1:862298378590:table/dynamodb-dev-aws-demolab1234-backend"
        }
      ]
    })
  }

  tags = {
    tag-key = "tag-value"
  }
}

