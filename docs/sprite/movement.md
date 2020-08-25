# NPCの移動

NPCのマップ上での移動について

## UpdateSprites

## UpdateNPCSprite

NPCの移動処理は `engine/overworld/movement.asm` の `UpdateNPCSprite` で行われる

ここでは wSpriteStateData1 と wSpriteStateData2 を更新するを行う

こうすることで VBlank中に OAMに状態が反映されて移動処理が実現する  

UpdateNPCSpriteで重要になってくるのは `movement byte1,2` という2つの値である

#### movement byte 1

movement byte 1 は

#### movement byte 2

## Scripted NPC

NPCは基本ランダムウォークだが、たまに動きが一定つまりプログラム化されたNPCも存在する

そのようなNPCを`Scripted NPC`と便宜上呼ぶ

関連: `MoveSprite`