# 連行イベント

NPCによってプレイヤーが特定の場所へ歩いて連行されるイベント

ポケモン赤では以下の3種類

- マサラタウンで、オーキド博士に研究所に連行されるイベント
- ニビシティでのジムまでの強制連行イベント
- ニビシティでの美術館までの強制連行イベント

どれも [NPC movement script](./sprite/movement_script.md) を使って実現している

## マサラタウンで、オーキド博士に研究所に連行されるイベント

<img src="https://imgur.com/G9DHlDk.gif" width="320px" height="300px">

`scripts/PalletTown.asm` で `engine/overworld/npc_movement.asm` に格納された `NPC movement script` を呼び出している

連行イベント開始時に主人公が、草むらの右側にいるか左側にいるかで処理のフローが変わる

## ニビシティでのジムまでの強制連行イベント

<img src="./image/follow/pewter_gym_guy.gif?raw=true" width="320px">

`engine/overworld/npc_movement.asm` と `engine/overworld/pewter_guys.asm` で処理が定義されている

`engine/overworld/pewter_guys.asm` の `PewterGuys`関数 では、プレイヤーに強制連行の simulated joypad 入力を与えている

## ニビシティでの美術館までの強制連行イベント

<img src="./image/follow/pewter_musium_guy.gif" width="320px">

ニビシティでのジムまでの強制連行イベントと同様

## 関連

- [NPC movement script](./sprite/movement_script.md)