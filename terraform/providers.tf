# エミュレーター専用の設定（endpoints / skip_* など）はここに一切書かない。
# 接続先は環境変数（AWS_ENDPOINT_URL, AWS_CA_BUNDLE, AWS_SHARED_CREDENTIALS_FILE など）で
# 切り替えるため、本番 AWS とエミュレーターで同じコードをそのまま使える。
provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
