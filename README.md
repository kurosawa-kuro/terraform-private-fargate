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