# Terraform Private Fargate - Makefile
# 環境変数の設定
ENV ?= dev

# 共通変数
TF_DIR = environments/$(ENV)
TF_VARS = -var-file=$(TF_DIR)/terraform.tfvars
TF_CMD = cd $(TF_DIR) && terraform

# ヘルプ
help:
	@echo "使用可能なコマンド:"
	@echo "  make init ENV=dev     - 初期化 (デフォルト: dev環境)"
	@echo "  make plan ENV=dev     - 実行計画の表示"
	@echo "  make apply ENV=dev    - 変更の適用"
	@echo "  make destroy ENV=dev  - インフラの削除"
	@echo "  make clean            - .terraformディレクトリとキャッシュの削除"
	@echo "  make format           - コードのフォーマット"
	@echo "  make validate         - 構文検証"
	@echo ""
	@echo "  make dev-init         - dev環境の初期化"
	@echo "  make dev-plan         - dev環境の実行計画"
	@echo "  make dev-apply        - dev環境の適用"
	@echo "  make dev-destroy      - dev環境の削除"
	@echo ""
	@echo "破壊的コマンド:"
	@echo "  make force-destroy ENV=dev  - 強制的にインフラを削除"
	@echo "  make nuke                   - 全環境の完全削除 (危険: 確認必須)"

# 初期化系
init:
	$(TF_CMD) init

plan:
	$(TF_CMD) plan $(TF_VARS)

apply:
	$(TF_CMD) apply $(TF_VARS)

# 削除・破壊系
destroy:
	$(TF_CMD) destroy $(TF_VARS)

force-destroy:
	$(TF_CMD) destroy -auto-approve $(TF_VARS)

# 危険: 全環境の削除（確認必須）
nuke:
	@echo "警告: これは全環境のリソースを完全に削除します"
	@echo "続行するには「yes-i-know」と入力してください"
	@read -p "入力: " confirm && [ "$$confirm" = "yes-i-know" ] && \
	(cd environments/dev && terraform destroy -auto-approve) || echo "中止しました"

# メンテナンス系
clean:
	rm -rf $(TF_DIR)/.terraform $(TF_DIR)/.terraform.lock.hcl

format:
	$(TF_CMD) fmt -recursive

validate:
	$(TF_CMD) validate

# 環境別エイリアス - dev
dev-init:
	make init ENV=dev

dev-plan:
	make plan ENV=dev

dev-apply:
	make apply ENV=dev

dev-destroy:
	make destroy ENV=dev

# デフォルトコマンド
.PHONY: help init plan apply destroy force-destroy nuke clean format validate \
	dev-init dev-plan dev-apply dev-destroy

.DEFAULT_GOAL := help
