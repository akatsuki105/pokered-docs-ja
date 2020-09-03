# スプライトの更新処理

スプライトのマップ上での移動など、スプライトに関するデータの更新処理

## UpdateSprites

これで $C1XX($C2XX)に格納された の16個のスプライトを1つ1つ更新していく

主人公のスプライトなら `UpdatePlayerSprite`  
NPCのスプライトなら `UpdateNonPlayerSprite`

を内部で呼び出している

## UpdateNonPlayerSprite

ここでは、更新対象のNPCが Scripted NPC かそうでないかで処理が分岐する

Scripted NPC については [Scripted NPC](./update.md#scripted-npc)参照

Scripted NPC なら `DoScriptedNPCMovement`  
普通のNPC なら `UpdateNPCSprite`

を内部で呼び出している

## UpdateNPCSprite

NPCの移動処理は `engine/overworld/movement.asm` の `UpdateNPCSprite` で行われる

ここでは wSpriteStateData1 と wSpriteStateData2 を更新する

こうすることで VBlank中に OAMに状態が反映されて移動処理が実現する  

UpdateNPCSpriteで重要になってくるのは `movement byte1,2` という2つの値である

#### movement byte 1

movement byte 1 は

- \$ff:動かないNPC(STAY)
- \$fe:移動を行うNPC(WALK) 

を表している

実際にこの値を使って、`UpdateNPCSprite` の処理(`.next`)で分岐処理が行われている。

この値は、 Map Headerの objects で予め決められており変化することはない

#### movement byte 2

movement byte 2は 優先スプライト方向を表している。  

この値が 

```asm
DOWN  EQU $D0
UP    EQU $D1
LEFT  EQU $D2
RIGHT EQU $D3
```

の特定のどれかのとき、 スプライトは `UpdateNPCSprite` の処理(`.determineDirection`)で必ずずっとその方向を向かされる(or その方向に移動する) 

この値は Map Header の objects で予め決められており変化することはない

#### TryWalking

`UpdateNPCSprite` でどのように移動するか決定したなら `TryWalking` で実際に更新処理を行う。

このとき、OAM や wOAMBuffer のXY値が変わるわけではなく、wSpriteStateData1 と wSpriteStateData2 の座標に関する値などを更新していることに注意

## PrepareOAMData

wSpriteStateData1 と wSpriteStateData2 に格納されているスプライトのデータは、 vBlank時に呼ばれる `PrepareOAMData` 関数で `wOAMBuffer` に OAM のフォーマットに変換されて格納される。

`wOAMBuffer` については [ドキュメント](./oam.md#woambuffer)参照

## Scripted NPC

トレーナーがこちらを見つけて歩いてくるときの移動はこちらへ一直線とプログラム化されているものである

このようなプログラム化された移動をする状態のNPCを `Scripted NPC` と便宜上呼ぶ

## NPC movement script

[こちら](./movement_script.md)を参照