# Terraform AWS Fargate Private Subnet 構成

このプロジェクトは、AWSのFargateサービスをプライベートサブネットにデプロイする構成をTerraformで記述しています。

## アーキテクチャ

この設計は、以下のコンポーネントで構成されています：

- **VPC**: パブリックとプライベートのサブネットを持つVPC
- **NAT Gateway**: プライベートサブネットからのアウトバウンド通信用
- **ECR**: コンテナイメージを保存するリポジトリ
- **ALB**: パブリックサブネットにあり、HTTPトラフィックを受け付けるロードバランサー
- **ECS/Fargate**: プライベートサブネットで実行されるコンテナサービス

![アーキテクチャ図](architecture.png)

## 前提条件

- Terraform v1.0.0以上
- AWS CLIがインストールされ、適切に設定されていること
- Dockerがインストールされていること（コンテナイメージのビルド用）

## 使用方法

このプロジェクトでは、Makefileを使用してTerraformコマンドを簡単に実行できます。

### Makefileの使用方法

プロジェクトルートディレクトリで以下のコマンドを実行できます：

```bash
# ヘルプを表示
make help

# 初期化
make init

# 実行計画の確認
make plan

# インフラのデプロイ
make apply

# インフラの削除（確認あり）
make destroy
```

### 環境の指定

デフォルトではdev環境が使用されますが、ENV変数で環境を指定できます：

```bash
make plan ENV=dev
make apply ENV=dev
```

### 環境別エイリアス

dev環境用のショートカットコマンド：

```bash
make dev-init    # dev環境の初期化
make dev-plan    # dev環境の実行計画確認
make dev-apply   # dev環境へのデプロイ
make dev-destroy # dev環境の削除
```

### 管理用コマンド

```bash
make clean     # .terraformディレクトリとキャッシュの削除
make format    # Terraformコードのフォーマット
make validate  # 構文検証
```

### 危険なコマンド（要注意）

```bash
make force-destroy  # 確認なしでインフラを強制削除
make nuke          # 全環境の完全削除（特別な確認が必要）
```

### 従来のTerraformコマンド

直接Terraformコマンドを使用することも可能です：

1. 環境ディレクトリに移動します：

```bash
cd environments/dev
```

2. Terraformの初期化を行います：

```bash
terraform init
```

3. リソースをプロビジョニングします：

```bash
terraform apply
```

4. 完了すると、以下の出力が表示されます：
   - VPC ID
   - ECRリポジトリURL
   - ALBのDNS名
   - ECSクラスター名
   - ECSサービス名

## コンテナイメージのデプロイ

1. ECRリポジトリにログインします：

```bash
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.ap-northeast-1.amazonaws.com
```

2. イメージをビルドします：

```bash
docker build -t <ECR_REPOSITORY_URL>:latest .
```

3. イメージをプッシュします：

```bash
docker push <ECR_REPOSITORY_URL>:latest
```

## モジュール構成

- **vpc**: VPC、サブネット、NAT Gatewayなどのネットワークリソース
- **ecr**: コンテナイメージ用のECRリポジトリ
- **alb**: アプリケーションロードバランサーと関連リソース
- **ecs**: ECSクラスター、タスク定義、サービス
- **iam**: ECSタスク実行ロールとタスクロール

## クリーンアップ

リソースを削除するには：

```bash
terraform destroy
```

## 注意事項

- このインフラは開発環境用に最適化されています。本番環境では追加の設定やセキュリティ対策が必要です。
- Fargate設定（CPU、メモリなど）は必要に応じて調整してください。