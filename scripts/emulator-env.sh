# shellcheck shell=bash
# ローカルで起動した AWS Emulator に AWS CLI / Terraform を向けるための環境変数を設定する。
#
#   source scripts/emulator-env.sh        # ポート 9297
#   source scripts/emulator-env.sh 9300   # 別ポートで起動した場合
#
# https://docs.aws.amazon.com/emulator/latest/userguide/point-sdk-to-emulator.html

_aws_emulator_port="${1:-9297}"
_aws_emulator_dir="${HOME}/.aws/emulator/${_aws_emulator_port}"

if [ ! -f "${_aws_emulator_dir}/config" ]; then
  echo "warning: ${_aws_emulator_dir}/config がありません。エミュレーターは起動していますか？" >&2
fi

# 環境変数の資格情報は credentials ファイルより優先されるので、本物の資格情報は外す
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_PROFILE

export AWS_ENDPOINT_URL="https://127.0.0.1:${_aws_emulator_port}"
export AWS_SHARED_CREDENTIALS_FILE="${_aws_emulator_dir}/emulator_credentials"
export AWS_CONFIG_FILE="${_aws_emulator_dir}/config"
export AWS_CA_BUNDLE="${_aws_emulator_dir}/ca.pem"
export AWS_EC2_METADATA_DISABLED=true
export AWS_DISABLE_HOST_PREFIX_INJECTION=true
export AWS_REGION=ap-northeast-1
export AWS_DEFAULT_REGION=ap-northeast-1

echo "AWS CLI / Terraform を ${AWS_ENDPOINT_URL} (AWS Emulator) に向けました。" >&2

unset _aws_emulator_port _aws_emulator_dir
