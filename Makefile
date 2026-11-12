# ローカルで CI と同じ流れ（plan -> apply）を実行するための Makefile。
# 事前にエミュレーターを起動し、`source scripts/emulator-env.sh` しておくこと。

TF       ?= terraform
TF_DIR   := terraform
OVERRIDE := $(TF_DIR)/aws_provider_override.tf

.PHONY: check-emulator
check-emulator: # エミュレーターに接続していることを確認する（本物の AWS への誤操作防止）
	@account=$$(aws sts get-caller-identity --query Account --output text 2>/dev/null); \
	if [ "$$account" != "000000000000" ]; then \
	  echo "AWS Emulator に接続していません (account=$$account)。先に 'source scripts/emulator-env.sh' を実行してください。" >&2; \
	  exit 1; \
	fi

$(OVERRIDE): emulator/aws_provider_override.tf
	cp $< $@

.PHONY: lint
lint: # fmt チェック + validate（AWS に接続しない）
	$(TF) fmt -check -recursive -diff
	$(TF) -chdir=$(TF_DIR) init -backend=false
	$(TF) -chdir=$(TF_DIR) validate

.PHONY: init
init: $(OVERRIDE)
	$(TF) -chdir=$(TF_DIR) init

.PHONY: plan
plan: check-emulator init
	$(TF) -chdir=$(TF_DIR) plan -out=tfplan

.PHONY: apply
apply: plan
	$(TF) -chdir=$(TF_DIR) apply tfplan

.PHONY: clean
clean: # ローカルの生成物を削除（エミュレーターを再起動したら state も消す）
	rm -rf $(TF_DIR)/.terraform $(TF_DIR)/.build $(TF_DIR)/terraform.tfstate* $(TF_DIR)/tfplan $(OVERRIDE)
