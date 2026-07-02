# math

LaTeXのプロジェクト群を統合管理し，GitHub Actionsでビルド，Cloudflare Pagesでデプロイを行うためのルートリポジトリです．

## 構成

プロジェクトはサブモジュールとして追加することも，通常のディレクトリとして配置することも可能です．各プロジェクトディレクトリの直下にコンパイルの対象となるtexファイルを配置します．

```text
.
├── .github/
│   ├── scripts/              # ワークフローで使用するスクリプト群
│   └── workflows/
│       └── build-deploy.yml  # ビルドおよびデプロイ用ワークフロー
├── .gitignore                # PDFファイルの除外設定
├── .gitmodules
├── public/                   # デプロイ専用ブランチ上の公開用ディレクトリ
├── _my_style/                # 共通スタイルファイル（サブモジュール）
├── project-a/                # プロジェクト（サブモジュール）
│   ├── fig/                  # project-aでつかう図
│   │   ├── fig1.tex
│   │   ├── fig1.pdf          # standalone
│   │   └── fig2.tex
│   ├── main.tex              # コンパイル対象のtexファイル
│   └── main.pdf              
└── project-b/                # プロジェクト（サブモジュールでないこともある）
    ├── project-ba/
    │   └── main.tex
    └── project-bb/
        └── main.tex
```

## 運用手順

### プロジェクトおよびスタイルの追加

新しいプロジェクトや共通スタイルファイルのリポジトリをサブモジュールとして追加する場合は，以下のコマンドを実行します．

```bash
git submodule add リポジトリのURL ディレクトリ名

```

サブモジュールを使用せず，直接ディレクトリを作成してtexファイルを配置することも可能です．

### サブモジュール取得のための認証設定

プライベートリポジトリをサブモジュールとして追加している場合，GitHub Actions環境でコードを取得するための認証設定が必要です．サブモジュール側のリポジトリにDeploy Keyを登録し，ルートリポジトリ側のSecretsに対応する秘密鍵を定義します．

### 共通スタイルファイルの参照

ルートディレクトリに配置した共通スタイルファイル（_my_style）を各プロジェクトのコンパイル時に参照するため，環境変数TEXINPUTSを指定します．

```bash
TEXINPUTS=../_my_style//:$TEXINPUTS latexmk -lualatex main.tex

```

## ビルドとデプロイの仕様

### 実行トリガー

メインブランチへのプッシュ，手動実行（workflow_dispatch），およびサブモジュール更新時の外部トリガー（repository_dispatch）を契機として実行します．

### 並行処理制御

複数の実行プロセスが同時にデプロイ用ブランチへプッシュして競合することを防ぐため，concurrency設定を用いてワークフローを直列化します．

### ビルド環境の準備

LaTeXのコンパイル環境として，TeX Live fullがインストールされたDockerコンテナを使用します．


### ビルド手順
ビルド対象は階層構造を持つ各プロジェクトディレクトリです．コンパイルは以下の手順で実行されます．

1. 各プロジェクト内にfigディレクトリが存在する場合，figディレクトリ内のtexファイルを先にコンパイルし，図として使用するstandaloneのPDFを生成します．

2. その後，対象プロジェクトの葉ディレクトリにある唯一のtexファイル（main.tex）をコンパイルし，最終的なPDF（main.pdf）を生成します．

3. figディレクトリ内で生成された図のPDFは，main.texのコンパイルにのみ使用されるためデプロイの対象外とします．

4. すべてのコンパイルが完了した後，生成されたPDFファイルへアクセスするための目次ページ（index.html）をルートディレクトリに作成します．同時に，各プロジェクトのディレクトリ内にもPDFをブラウザ上で表示するためのindex.htmlを自動生成します．

### 成果物管理とデプロイ専用ブランチ
デプロイ専用ブランチは配信に必要十分なファイルのみを保持します．デプロイの対象となるファイル群（各プロジェクトのmain.pdfおよび生成されたindex.html）は，デプロイ専用ブランチ上のpublic/ディレクトリ配下へ集約します．texソースコードやコンパイル用の中間ファイルはすべて除外します．作業用のメインブランチ等では，.gitignoreの指定によりPDFファイルはGitの管理対象外となります．

既存のデプロイ専用ブランチに過去の不要ファイルが残っている場合でも，GitHub Actionsはデプロイごとにブランチ内容を作り直し，public/とWorkers設定ファイルのみをpushします．

### デプロイ環境
Cloudflare Workersを利用して成果物を配信します．GitHub Actionsはデプロイ専用ブランチのルートにwrangler.jsoncを生成し，Workersのassets.directoryを./public/に固定します．さらにpublic/.assetsignoreを生成し，.wrangler/やwrangler.toml，wrangler.jsonが静的アセットとしてアップロードされないようにします．これにより，deploy branch rootや.wrangler/tmpなどの作業用ファイルが公開されることを防ぎます．GitHub Actionsによるデプロイ専用ブランチへの自動プッシュをトリガーとして配信プロセスが実行されます．

### デプロイ専用ブランチの保護
将来的にデプロイ専用ブランチへbranch protection ruleを設定する場合，GitHub Actionsからのpushを許可するための設計が必要です．次のいずれかを選択します．

1. GitHub ActionsのGITHUB_TOKENによる直接pushを続ける．この場合，Repository settingsのActions permissionsでRead and write permissionsを有効にし，deploy branchの保護ルールはActionsの通常pushを妨げない設定にします．PR必須やpush制限を強くかける場合はこの方式では失敗する可能性があります．
2. GitHub Appなど，branch protectionまたはrulesetのbypassを許可できる専用資格情報でpushする．この場合，最小権限の資格情報をSecretsに登録し，push時の認証に使用します．deploy keyやPATを使う場合は，対象ルールを実際にbypassできるか事前確認が必要です．
3. deploy branchへ直接pushせず，GitHub Actionsがpull requestを作成し，required status checks通過後にmergeする運用に変更する．保護を最も強くできますが，自動デプロイにはauto-merge等の追加設定が必要です．

保護ルールを有効にする前に，少なくとも次を確認します．

- デプロイWorkflowに必要な`contents: write`権限があること．
- deploy branchへのpush主体（GITHUB_TOKEN，deploy key，GitHub App，PAT等）が保護ルールを通過またはbypassできること．
- required status checksを設定する場合，deploy branch更新時にも該当チェックが完了すること．
- force push禁止を有効にする場合，現在のスクリプトの通常push運用で問題ないこと．
- deploy branch rootのwrangler.jsoncでCloudflare Workersのassets.directoryが./public/に固定されていること．
- public/.assetsignoreで.wrangler/やwrangler.toml，wrangler.jsonが除外されていること．
