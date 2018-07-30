# CI/CD環境構築ハンズオン

## ハンズオンで構築する構成

![構成図](https://cacoo.com/diagrams/Bik1Om7JvTVGzpfj-5F49C.png)

今回は上記の図のような構成を構築します。

GitHubにコードがプッシュされるとCodePipelineでの処理が開始されます。CodeBuildではテスト、Dockerイメージの作成および作成したイメージのECRへのプッシュを行います。CodeBuildでの処理が成功したらECSに新しいバージョンのイメージがデプロイされます。

## 1. サンプルアプリケーションのフォークおよびクローン

まずは、今回利用するサンプルアプリケーションのリポジトリをフォークし、自分のアカウントにリポジトリを作成します。

[サンプルアプリケーション](https://github.com/katainaka0503/ci-cd-hands-on)

<img src="https://cdn-ssl-devio-img.classmethod.jp/wp-content/uploads/2018/08/fork-640x210.png" alt="" width="640" height="210" class="alignnone size-medium wp-image-348765" />

上のリンクからGitHubの当該リポジトリのページに移動し、右上の `Fork` というボタンからフォークを実行します。

<img src="https://cdn-ssl-devio-img.classmethod.jp/wp-content/uploads/2018/08/f514b4e78f8a717b73707cc3b38dcff4-640x353.png" alt="" width="640" height="353" class="alignnone size-medium wp-image-348767" />

自分のGitHubアカウント上に作成されたフォークしたリポジトリから、ローカルのPCにクローンします。
作業用のディレクトリで以下のコマンドを実行します。
```shell
$ git clone git@github.com:<ご自分のgithubのアカウント名>/ci-cd-hands-on.git
```

クローンされたリポジトリのディレクトリに移動し、中身を確認します。
```shell
$ cd ci-cd-handson
$ ls
Dockerfile	Rakefile	config		log		template
Gemfile		app		config.ru	package.json	tmp
Gemfile.lock	bin		db		public		vendor
README.md	buildspec.yml	lib		spec
```

## 2. ハンズオン用環境構築用のCloudFormationの実行

[![Launch Stack](https://dmhnzl5mp9mj6.cloudfront.net/application-management_awsblog/images/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=ap-northeast-1#/stacks/new?stackName=hands-on-environment&templateURL=https://s3-ap-northeast-1.amazonaws.com/ci-cd-hands-on-template/hands-on-environment.template.yaml)

上のリンクより、ハンズオン用の環境を構築するためのCloudFormationを実行します。

この、CloudFormationによって、主に以下のようなものが作成されます

- VPC
- サブネット
- ALB
- ECSのサービス
- ECSのタスク定義
- ECRのリポジトリ
- ECS用のロール
- CodeBuild用のロール

作成したスタックが `CREATE_COMPLETE` の状態になるまで待ちます。

### 動作確認

作成したスタックの`ALBDNSName`という出力が今回のサンプルアプリケーションのアクセス先のURLが出力されていますので、そちらを使用してアクセスし、サンプルアプリケーションの動作を確認します。


今回のアプリケーションはFizzBuzzを指定された数まで表示するアプリケーションです。

## 3. 手動デプロイしてみる

ecs-deployのようなデプロイに便利なツールもありますが、CodeBuildで行う処理との対比をわかりやすくするため、ここではそういったものは使わずにデプロイを実行します。

まずはデプロイされたことがわかりやすくするため、画面を修正します。
```shell
$ vim app/views/layouts/application.html.erb 
$ git commit -am "manual deploy"$ 
```

つぎに以下のコマンドを実行し、手動でデプロイを実行します。

まず、手元でDockerイメージを構築し、ECRにプッシュします。
```
$ $(aws ecr get-login --no-include-email --region $AWS_DEFAULT_REGION)

$ IMAGE_REPOSITORY_NAME=<環境構築用スタックのImageRepositoryNameという出力の値>
$ IMAGE_TAG=`git rev-parse HEAD`
$ docker build -t $IMAGE_REPOSITORY_NAME:$IMAGE_TAG .
$ docker push $IMAGE_REPOSITORY_NAME:$IMAGE_TAG

$ echo $IMAGE_REPOSITORY_NAME:$IMAGE_TAG
```

ECSの設定の修正で使用するため、イメージをプッシュしたリポジトリとタグの値を覚えておきます。

ここまでの操作の中でも、プッシュする対象とは異なるブランチで作業を行っていた場合や、リモートブランチとの同期を忘れるなどした場合には意図したものとは異なるソースコードをデプロイしてしまうリスクがあります。

つぎに、コンソールの操作に移り、実際にECSへのデプロイを行っていきます。

マネジメントコンソールからECSの画面に移動します。

<img src="https://cdn-ssl-devio-img.classmethod.jp/wp-content/uploads/2018/08/ecs-640x483.png" alt="" width="640" height="483" class="alignnone size-medium wp-image-349183" />

まず、タスク定義の新しいリビジョンを作成します。

環境構築用スタックによって作成されたタスクの新しいリビジョンの作成画面を表示します。
コンテナ名fizzbuzzの設定画面に移動し、イメージの指定を先程プッシュしたイメージのものに書き換え新しいリビジョンを作成します。

<img src="https://cdn-ssl-devio-img.classmethod.jp/wp-content/uploads/2018/08/a3eea352fa04680f29ce2e75163b5ca5-640x344.png" alt="" width="640" height="344" class="alignnone size-medium wp-image-349193" />

次に、環境構築用スタックによって作成されたサービスの編集画面に移動し、新しいタスク定義のリビジョンを指定するように編集をおこない、サービスの更新を実行します。

<img src="https://cdn-ssl-devio-img.classmethod.jp/wp-content/uploads/2018/08/ef41ba4015f8a2f42ad5382c33fc1352-640x367.png" alt="" width="640" height="367" class="alignnone size-medium wp-image-349198" />

しばらくすると新しいタスク定義に基づくタスクが実行され、コードの修正が反映されます。


## 4. CodePipelineによるパイプラインの構築

手動でのデプロイが大変だと感じてもらったところで、CodePipeline/CodeBuildを使用したパイプラインを作成していきます。

- マネジメントコンソールのトップ画面より「CodePipeline」をクリックします。

<img src="https://cdn-ssl-devio-img.classmethod.jp/wp-content/uploads/2017/05/devops-hands-on-15-640x195.png" alt="devops-hands-on-15" width="640" height="195" class="alignnone size-medium wp-image-259029" />

- まだパイプラインを作成していない場合は以下のような画面が表示されるので「今すぐ始める」をクリックします。

<img src="https://cdn-ssl-devio-img.classmethod.jp/wp-content/uploads/2017/05/devops-hands-on-16-640x269.png" alt="devops-hands-on-16" width="640" height="269" class="alignnone size-medium wp-image-259031" />

- パイプラインのセットアップが開始するのでパイプライン名をわかりやすい名前(hands-on-pipelineなど)で入力して「次のステップ」をクリックします。

<img src="https://cdn-ssl-devio-img.classmethod.jp/wp-content/uploads/2017/05/devops-hands-on-17-640x204.png" alt="devops-hands-on-17" width="640" height="204" class="alignnone size-medium wp-image-259032" />

- ソースプロバイダのセットアップが始まるので以下の表のように入力後、「次のステップ」をクリックします。

| 入力項目         | 値                           |
| ---------------- | ---------------------------- |
| ソースプロバイダ | GitHub                       |
| リポジトリ       | フォークしておいたリポジトリ |
| ブランチ         | master                       |

- ビルドプロバイダのセットアップが始まるので以下の表のように入力後、「ビルドプロジェクトの保存」をクリックしてから「次のステップ」をクリック

| 入力項目                 | 値                                                      |
| ------------------------ | ------------------------------------------------------- |
| ビルドプロバイダ         | AWS CodeBuild                                           |
| プロジェクトの設定       | 新しいビルドプロジェクトを作成                          |
| プロジェクト名           | わかりやすい名前(hands-on-projectなど)                  |
| 環境イメージ             | AWS CodeBuild マネージド型イメージの使用                |
| OS                       | Ubuntu                                                  |
| ランタイム               | Ruby                                                 |
| バージョン               | aws/codebuild/ruby:2.3.1                              |
| ビルド仕様               | ソースコードのルートディレクトリの buildspec.yml を使用 |
| CodeBuild サービスロール | 環境構築用のスタックの出力                  |
| VPC                      | No VPC                                          |
| 特権付与(アドバンスト内)       | ✔                                              |
| 環境変数(アドバンスト内)     | 名前：`IMAGE_REPOSITORY_NAME`, <br> 値:環境構築用のCloudFormation`ImageRepositoryName` という出力の値 |                   

- デプロイプロバイダのセットアップが始まるのでプロバイダに「Amazon ECS」を入力後、「AWS CodeDeploy に新たにアプリケーションを作成します。」のリンクをクリック

| 入力項目                 | 値                                                      |
| ------------------------ | ------------------------------------------------------- |
| デプロイプロバイダ         | Amazon ECS                                          |
| クラスター名       | <ハンズオン環境用 CloudFormationスタック名>-ECS-Cluster                          |
| サービス名           |  <ハンズオン環境用 CloudFormationスタック名>-ECS-Service                |
| イメージのファイル名             | imagedefinitions.json              |

- CodePipelineにアタッチするIAM Roleの画面に変わるので、「ロールの作成」をクリック後、遷移する画面で「許可」をクリック

<img src="https://cdn-ssl-devio-img.classmethod.jp/wp-content/uploads/2017/05/devops-hands-on-21-640x363.png" alt="devops-hands-on-21" width="640" height="363" class="alignnone size-medium wp-image-259055" />

- IAM Roleの作成が完了したら「次のステップ」をクリック

<img src="https://cdn-ssl-devio-img.classmethod.jp/wp-content/uploads/2017/05/devops-hands-on-22-640x223.png" alt="devops-hands-on-22" width="640" height="223" class="alignnone size-medium wp-image-259056" />

- 最後に確認画面が表示されるので、内容を確認後、「パイプラインの作成」をクリック

すると、パイプラインが自動で開始されます。

<img src="https://cdn-ssl-devio-img.classmethod.jp/wp-content/uploads/2018/08/ddf0495992f096549e7a7aa62043c03b-640x885.png" alt="" width="640" height="885" class="alignnone size-medium wp-image-348910" />

`Staging`ステージまで緑色になり、デプロイが完了したところで一度正常にページにアクセスできることを確認します。

<img src="https://cdn-ssl-devio-img.classmethod.jp/wp-content/uploads/2018/08/1769187c2286f846c233341f03da13e9-640x207.png" alt="" width="640" height="207" class="alignnone size-medium wp-image-349210" />

## 手元でバグ混入 Push

バグが混入した際に、テストでデプロイが途中で止まることを確認するため、フォークしたリポジトリのコードを修正します。

エディタでFizzBuzzのロジックが記述されているファイル、`app/models/fizzbuzz.rb`を開きます。

意図的にバグを混入させるため、

```
if i % 15 == 0
```

と書かれた行を

```
if i % 10 == 0
```

のように修正します。

修正が終わったらコミットし、GitHub上にプッシュします。
```shell
$ git commit -am bug
$ git push origin master
```

GitHubにプッシュすると、CodePipelineでの処理が開始されます。
しかし、CodeBuildでテストが失敗し、ECSへのデプロイは実行されません。

ß<img src="https://cdn-ssl-devio-img.classmethod.jp/wp-content/uploads/2018/08/6785bac4c64b2e508b1134aa19bed74d-640x908.png" alt="" width="640" height="908" class="alignnone size-medium wp-image-349032" />

テストが自動で実行される環境が構築されていたため、バグの混入したバージョンがデプロイされるのを防ぐことができました！

## 再度正しいコードに戻す

先程の修正をもとに戻すため、`app/models/fizzbuzz.rb`　を開きます。

```
if i % 10 == 0
```

と書かれた行を

```
if i % 15 == 0
```

のように修正します。

```shell
$ git commit -am fixbug
$ git push origin master
```

同様に自動でCodePipeline上での処理が開始されます。

<img src="https://cdn-ssl-devio-img.classmethod.jp/wp-content/uploads/2018/08/e6dddcd46828eb204b0eef8048c50e4f-640x957.png" alt="" width="640" height="957" class="alignnone size-medium wp-image-349044" />

今度はテストが成功するため、デプロイが行われました。

## まとめ

CodePipelineを使用することでデプロイやテストが自動で実行されるようになりました。

煩雑な手作業が自動化されることで人為的ミスを削減し、デプロイにかかる時間を短縮できます。

## 補足. 環境の削除
  
ハンズオンで作成した環境を削除したい場合は以下の手順を参考にしてください。

- CodePipelineの削除
- CodeBuildの削除
- IAM Roleの削除　CodePipeline用
- CodePipelineのアーティファクト保存用S3バケット削除
  - ※ 他のパイプラインでも利用している場合があるので注意
- ECRリポジトリ内のイメージをすべて削除
- CloudFormationスタックの削除