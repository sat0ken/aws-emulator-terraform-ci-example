variable "region" {
  description = "デプロイ先のリージョン。"
  type        = string
  default     = "ap-northeast-1"
}

variable "project" {
  description = "リソース名のプレフィックスに使うプロジェクト名。"
  type        = string
  default     = "textstats"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,20}$", var.project))
    error_message = "project は英小文字で始まる 3〜21 文字の英小文字・数字・ハイフンにしてください。"
  }
}

variable "environment" {
  description = "環境名（dev / stg / prd など）。"
  type        = string
  default     = "dev"
}

variable "lambda_timeout" {
  description = "Lambda のタイムアウト（秒）。"
  type        = number
  default     = 30
}

variable "lambda_memory_size" {
  description = "Lambda のメモリサイズ (MB)。"
  type        = number
  default     = 256
}

variable "log_retention_in_days" {
  description = "Lambda のログの保持期間（日）。"
  type        = number
  default     = 14
}
