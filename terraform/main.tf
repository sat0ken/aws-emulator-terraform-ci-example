# S3 (input) にファイルが置かれたら Lambda が集計し、結果を S3 (output) に書き出す構成。
#
#   S3 input ──ObjectCreated──> Lambda (processor) ──PutObject──> S3 output (results/<key>.json)
#
# 入力と出力のバケットを分けて、Lambda の出力で Lambda 自身が再起動されるループを防いでいる。

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  name          = "${var.project}-${var.environment}"
  account_id    = data.aws_caller_identity.current.account_id
  function_name = "${local.name}-processor"
}

# -----------------------------------------------------------------------------
# S3
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "input" {
  bucket        = "${local.name}-input-${local.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket" "output" {
  bucket        = "${local.name}-output-${local.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "input" {
  bucket = aws_s3_bucket.input.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "output" {
  bucket = aws_s3_bucket.output.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# Lambda
# -----------------------------------------------------------------------------
data "archive_file" "processor" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/processor"
  output_path = "${path.module}/.build/processor.zip"
}

resource "aws_cloudwatch_log_group" "processor" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = var.log_retention_in_days
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "processor" {
  name               = local.function_name
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "processor" {
  statement {
    sid       = "ReadInput"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.input.arn}/*"]
  }

  statement {
    sid       = "WriteOutput"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.output.arn}/*"]
  }

  statement {
    sid       = "WriteLogs"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.processor.arn}:*"]
  }
}

resource "aws_iam_role_policy" "processor" {
  name   = "processor"
  role   = aws_iam_role.processor.id
  policy = data.aws_iam_policy_document.processor.json
}

resource "aws_lambda_function" "processor" {
  function_name    = local.function_name
  role             = aws_iam_role.processor.arn
  runtime          = "python3.13"
  handler          = "handler.handler"
  filename         = data.archive_file.processor.output_path
  source_code_hash = data.archive_file.processor.output_base64sha256
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

  environment {
    variables = {
      OUTPUT_BUCKET = aws_s3_bucket.output.bucket
    }
  }

  # ロググループを先に作っておく（Lambda に自動作成させると保持期間を管理できない）
  depends_on = [aws_cloudwatch_log_group.processor, aws_iam_role_policy.processor]
}

# -----------------------------------------------------------------------------
# S3 イベント通知 -> Lambda
# -----------------------------------------------------------------------------
resource "aws_lambda_permission" "allow_s3" {
  statement_id   = "AllowInvokeFromInputBucket"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.processor.function_name
  principal      = "s3.amazonaws.com"
  source_arn     = aws_s3_bucket.input.arn
  source_account = local.account_id
}

resource "aws_s3_bucket_notification" "input" {
  bucket = aws_s3_bucket.input.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.processor.arn
    events              = ["s3:ObjectCreated:*"]
  }

  # S3 は通知設定の保存時に Lambda を呼べるか検証するので、権限を先に付ける
  depends_on = [aws_lambda_permission.allow_s3]
}
