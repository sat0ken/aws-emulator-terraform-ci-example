# AWS Emulator で実行するときだけ terraform/ にコピーして使う override ファイル。
# （Terraform は *_override.tf を通常の設定にマージする）
# https://developer.hashicorp.com/terraform/language/files/override
#
# 本番用の terraform/*.tf には手を入れずに、エミュレーター固有の差分だけをここに閉じ込める。

provider "aws" {
  # AWS provider v6 は、アカウント ID が分かっていると S3 バケットのタグ操作に
  # S3 Control API (ListTagsForResource / TagResource) を使う。
  # S3 Control はホスト名にアカウント ID を付けて送られる
  # (例: https://000000000000.127.0.0.1:9297) ため、エミュレーターには届かない。
  # アカウント ID の取得を止めると、従来の GetBucketTagging / PutBucketTagging に
  # フォールバックするので、これを回避できる。
  #
  # プロバイダーは起動時のクレデンシャル検証 (sts:GetCallerIdentity) の結果からも
  # アカウント ID を得るため、両方を止める必要がある。
  # アカウント ID が必要な箇所は data.aws_caller_identity を使えば引き続き取得できる。
  skip_credentials_validation = true
  skip_requesting_account_id  = true
}
