# sprite

## ポケモン赤でのスプライト

ポケモン赤でのスプライトは、プレイヤーやNPC、特定の物体などが該当する

スプライトの一例  
<img src="../image/sprite.png" width="40%" />

## OAM  

[OAM](./oam.md)参照

## 最大人数

OAM は 8\*8pxサイズのタイルであるのに対して、ポケモン赤でのスプライトは 16\*16pxとスプライト一つにつき 4つの OAMを使う

OAM は 40スロットなので ポケモン赤で画面上に存在できるスプライトの最大数は 10個である  

## スプライトの保持しているデータ

[スプライトデータ](./sprite_data.md)参照

## Scripted NPC

NPCは基本ランダムウォークだが、たまに動きが一定つまりプログラム化されたNPCも存在する

そのようなNPCを`Scripted NPC`と便宜上呼ぶ

## スプライトのオフセット

このレポジトリではスプライトのオフセットというのは、マップ上のスプライトのインデックス番号のことであり、**$c1Xn, $c2XnのXの値**のことを指す。

## スプライトの更新

スプライトの更新処理は `UpdateSprites` で行われる  

スプライトの更新処理は 主にWRAM上の領域 `wSpriteStateData1` と `wSpriteStateData2` の値を更新することで行われる

## スプライトの反映

ゲーム上では スプライトのデータは [スプライトデータ](./sprite_data.md) で述べている WRAM上の領域 `wSpriteStateData1` と `wSpriteStateData2` で管理されている  

これをゲームボーイの画面上にスプライトとして反映させるためには VRAM の OAM領域に OAM のフォーマット([OAM](./oam.md)参照)で格納してあげる必要がある  

これは VBlank 中に `PrepareOAMData` で行われている  

## Sprite ID

スプライトのタイルデータの取得や `Map Object`の objectsマクロ などでスプライトを識別するためのID 

`constants/sprite_constants.asm` で定義されている。

## Emotion Bubble

!マークなどの感情を表す吹き出しのこと

`engine/overworld/emotion_bubbles.asm`で詳細に定義されている

## VRAM 上のタイルデータ

マップにいるときスプライトの2bppタイルデータは次のように配置される

### 通常時  

VRAMのタイルデータ領域1 (0x8000-0x8800 グリッドの1番目)にスプライトの立ち姿のタイルデータが敷き詰められる

また 0x8780 からは1面スプライト(モンスターボールや化石など) を配置する領域が2個分存在する (0x8780-0x87c0, 0x87c0-8800)

VRAMのタイルデータ領域2 (0x8800-0x9000 グリッドの2番目)にスプライトの歩き姿のタイルデータが敷き詰められる

<img src="https://imgur.com/UHG2UDG.png" width="40%" />

### 会話中  

タイルデータ領域1は、通常時と同じ

タイルデータ領域2には、テキストデータのための文字タイルが格納される

<img src="https://imgur.com/Een2IqV.png" width="40%" />

