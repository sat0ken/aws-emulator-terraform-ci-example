output "account_id" {
  description = "接続先のアカウント ID。エミュレーターなら 000000000000 になる。"
  value       = local.account_id
}

output "input_bucket" {
  description = "ファイルをアップロードするバケット。"
  value       = aws_s3_bucket.input.bucket
}

output "output_bucket" {
  description = "集計結果 (results/<key>.json) が書き出されるバケット。"
  value       = aws_s3_bucket.output.bucket
}

output "function_name" {
  description = "処理を行う Lambda 関数名。"
  value       = aws_lambda_function.processor.function_name
}

output "log_group_name" {
  description = "Lambda のロググループ名。"
  value       = aws_cloudwatch_log_group.processor.name
}
