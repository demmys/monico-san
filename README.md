マイルストーン
=====

### 実装方法
+ botはcronで5分おきに起動
+ ユーザからの設定情報は以下の様な表をソートした上でタブ区切り形式のファイルにして保存しておく(以下データベースと呼ぶ)

| screen_name | time | tweet_id | valid |
|:-:|:-:|:-:|:-:|
| demmys | 2015-01-19T07:00:00+0900 | hogefuga | 1 |
| piyopiyo | 2015-01-19T09:00:00+0900 | fugabar | 1 |
| ... | ... | ... | ... |

### 実行ステップ
1. メンションの一覧を取得
2. メンションの中から時間を指定する単語と「起こして」などが入っているものを取得、正しければデータベースにvalid=1で設定を追加する
3. メンションの中から「起きたよ」などが入っているものを取得、データベースにvalid=1でかつ現在時刻と設定時刻が近いそのユーザの設定があれば、validを0にする
4. データベースの中から現在時刻に設定時刻が近い(前後30分以内など)valid=1の設定を取得し、その設定のユーザーに起きることを促すツイートを送信する
5. データベースの中から現在時刻に対して設定時刻が過ぎている(1時間後など)valid=1の設定を取得し、その設定のユーザとそのユーザのフォロワー数名の@関連が付いた、設定ユーザを罵倒するようなツイートを投稿する