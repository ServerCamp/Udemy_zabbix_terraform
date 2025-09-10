# Udemy_zabbix_terraform

## 概要
このプロジェクトは、Zabbix の Udemy 講座にて手順を簡略化するために、Terraform を使用して AWS リソースを構築するサンプルです。  

以下のリソースを作成します：
- VPC
- サブネット
- インターネットゲートウェイ
- ルートテーブルとその関連付け
- EC2 インスタンス (Web, Zabbix)
- セキュリティグループ
- Elastic IP (EIP)
- SSH キーの生成

---

## 構成図
※ここに構成図を挿入してください（例: PNG / PlantUML / draw.ioなど）

---

## フォルダ構成
```
.
├── .gitignore               # Gitで無視するファイルの設定
├── ami.tf                   # AMIを自動取得するData Source
├── ec2.tf                   # EC2インスタンス、SG、EIPなど
├── provider.tf              # プロバイダーの設定
├── terraform.tfvars.example # 変数のサンプルファイル
├── variables.tf             # 変数の定義
├── versions.tf              # Terraform/Providerのバージョン固定
└── vpc.tf                   # VPCとネットワーク関連リソースの定義
```

---

## 必要条件
- Terraform **1.13.x**以上
- AWS アカウント認証が設定済み (`aws configure`)
- AWS CLI が使用可能であること

---

## 使用方法

### 1. リポジトリをクローン
```bash
git clone https://github.com/your-repo/terraform-aws-education.git
cd terraform-aws-education
```

### 2. 変数ファイルを作成
サンプルファイルをコピーして編集してください。
```bash
cp terraform.tfvars.example terraform.tfvars
```
編集箇所
```bash
name    = "example"
domain  = "example.com"
```

### 3. 初期化
```bash
terraform init
```

### 4. 設定の確認
```bash
terraform plan
```


### 5. リソースの作成
```bash
terraform apply -auto-approve
```

### 6. リソースの削除
```bash
terraform destroy -auto-approve
```

## 主なファイルの説明

ami.tf
公開している最新の AMI を自動で取得します。

ec2.tf
EC2 インスタンス、Elastic IP、セキュリティグループを定義。
http プロバイダーを使って 自分のグローバルIPのみ に SSH/HTTP/HTTPS を許可しています。
→ Zabbix UI (80/443) も自分のIPからのみアクセス可能です。

vpc.tf
VPC、サブネット、IGW、ルートテーブルを定義しています。

versions.tf
Terraform と Provider のバージョンを固定しています。

**注意事項**

セキュリティのため、Zabbix UI / Web サーバ (80, 443) は自分のIPからのみアクセス可能です。
他の場所からアクセスしたい場合は ec2.tf のセキュリティグループ設定を修正してください。

AWS 上での利用には課金が発生します。作成したリソースは講座受講後削除するように気を付けてください。

