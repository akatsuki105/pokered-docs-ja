# sprite

## ポケモン赤でのスプライト

ポケモン赤でのスプライトは、プレイヤーやNPC、特定の物体などが該当する

スプライトの一例  
<img src="./image/sprite.png" width="40%" />

## スプライトの保持しているデータ

[スプライトデータ](./sprite_data.md)参照

## Scripted NPC

NPCは基本ランダムウォークだが、たまに動きが一定つまりプログラム化されたNPCも存在する

そのようなNPCを`Scripted NPC`と便宜上呼ぶ

## スプライトのオフセット

このレポジトリではスプライトのオフセットというのは、マップ上のスプライトのインデックス番号のことであり、**$c1Xn, $c2XnのXの値**のことを指す。

## スプライトの移動

TODO

## Emotion Bubble

!マークなどの感情を表す吹き出しのこと

`engine/overworld/emotion_bubbles.asm`で詳細に定義されている

