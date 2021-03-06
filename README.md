# 使い方&インストールガイド

## インストールガイド

#### APIキーの用意
本アプリケーションはYoutubeとTwitterのAPIを使用しています。
登録後、.envファイル(開発環境)かHEROKUのconfig設定(本番環境)で下記の環境変数を設定してください。
- TWITTER_CONSUMER_KEY
- TWITTER_CONSUMER_SECRET
- TWITTER_ACCESS_TOKEN
- TWITTER_ACCESS_TOKEN_SECRET
- TWITTER_BEARER_TOKEN
- YOUTUBE_TOKEN

### 開発環境編
AWS提供のCloud9を用いる
```Terminal
# ソースコードをCLONE
$ git clone https://github.com/n20010/graduationtask.git

# バージョンを指定してRailsをインストールする
$ gem install rails -v 6.0.3

# bundlerのバージョンを指定してインストールする
$ gem install bundler -v 2.2.17

# Cloud9環境のディスク容量アップと、クラウドIDEへのYarnインストール
$ source <(curl -sL https://cdn.learnenough.com/resize)
$ source <(curl -sL https://cdn.learnenough.com/yarn_install)
$ yarn install --check-files

# 必要なRubyGemsをインストール
$ cd graduationtask
$ bundle install --without production

## node関係でトラブルが発生した場合
$ rm -rf node_modules/
$ rm -rf yarn.lock
$ yarn install

# サーバー起動
$ rails s
```

### 本番環境編
HEROKUへのデプロイ
>HEROKUのアカウントが必要
>https://jp.heroku.com/free

```Terminal
# 本番用以外のgemをインストールする
$ bundle _2.2.17_ config set --local without 'production'
$ bundle _2.2.17_ install

# HEROKUのインストール
$ source <(curl -sL https://cdn.learnenough.com/heroku_install)

$ heroku login --interactive
$ heroku create
$ git push heroku master
```

## 使い方ガイド
基本の使い方
1. Twitterの検索キーワードまたはYouTubeの配信URLを貼り付ける
2. GENERATEをクリック
3. SCREENページを開く
4. SCREENページをOBSのブラウザソースで取り込む

オプション
- FONT SIZE => 生成するコメントのフォントサイズを設定する
- OPACITY => 生成するコメントの透明度を設定する
- NICOINCO MODE => ニコニコ動画のようにコメントを出力する
- YOUTUBE MODE => YouTubeの配信のようにコメントを出力する
```
オプションを変更したら左下の「Update Settings」をクリックして反映
```