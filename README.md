# SuperColliderToTouchDesignerOSC

本リポジトリは、SuperCollider から TouchDesigner へ OSC 通信を行うためのユーティリティです。  
ライブコーディング中の音響解析結果を、リアルタイムに外部ビジュアルソフトへ送信する用途を想定しています。


---


## 概要

SuperCollider 上で生成・解析した音声データ（音量・スペクトル重心・オンセットなど）を  
OSC メッセージとして送信し、TouchDesigner 側でビジュアル表現に利用するための構成です。

音源生成・解析は SuperCollider（scsynth）側で行い、  
解析結果を一定間隔で OSC 通信により外部へ送信します。


---


## 主な機能

- SuperCollider による音源の解析
- 解析結果を OSC メッセージとして送信
- TouchDesigner など外部ソフトウェアとのリアルタイム連携
- ライブコーディングを前提とした柔軟な制御構成


---


## 技術構成

使用言語 / 環境：
- SuperCollider

通信方式：
- OSC（Open Sound Control）

連携先：
- TouchDesigner


---


## 使い方 / 起動方法（概要）

1. SuperColliderを起動します
2. `Ctrl + B` でサーバーを起動します
3. `SuperColliderToTouchDesignerOSC.scd` をそれぞれ実行し、サーバーに登録します
4. 別ファイルで作成した音源を再生します
5. `~viz[\start].([ [~any, \any, 0] ]);` に任意のNodeProxyを指定し実行します
6. TouchDesignerにて`OSC in CHOP`を使用し、`var td = NetAddr("127.0.0.1", 8000);` に合わせて受信します
7. `~viz[\detach].(\any);`または`~viz[\stop].();`でOSC通信を終了します
