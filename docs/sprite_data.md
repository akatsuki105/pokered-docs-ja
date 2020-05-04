# スプライトデータ

スプライトの保持しているデータについての詳細なドキュメント

## 概要

現在のマップ上に存在するスプライトのデータは[wram.asm](../wram.asm)の`wSpriteDataStart`で保持されている

16スプライト分の大きさのデータ領域が2種類存在している

どちらのデータ領域も1つのスプライトごとに16バイトの大きさを持っている

(つまり16 * 16 * 2バイトの領域が全体で確保されている)

## wSpriteStateData1(1つ目のデータ領域)

1つ目のデータ領域は以下のような構造を取っている

 アドレス  | ラベル |  内容
---- | ---- | ----
 $C1x0  | picture ID  |  用途不明　<br/>定数でマップ初期化時に読み込まれる
 $C1x1  | movement status  |  スプライトの状態<br/>0: 未初期化, 1: 準備完了, 2: クールタイム中, 3: 移動中<br/>またプレイヤーのほうを見ているときは7bit目が立つ
 $C1x2  | sprite image index  |  スプライトの更新時に変化 <br/>\$ff -> スプライト非表示 <br/>スプライトの方向や歩きモーションの進行具合、スプライトのオフセット(何番目のデータ領域)にあるかによって値が変わってくる
 $C1x3  | Y screen position delta  |  スプライトのY座標変化 <br/>-1/0/1のどれか スプライトの更新時にC1x4に加算される
 $C1x4  | Y screen position  |  スプライトのY座標 <br/>ピクセル単位 常にグリッド(16*16)の4ピクセル上にあるため、スプライトはタイルの中央に表示される 立体的に見せるため
 $C1x5  | X screen position delta  |  スプライトのX座標変化 <br/>-1/0/1のどれか スプライトの更新時にC1x6に加算される
 $C1x6  | X screen position  |  スプライトのX座標 <br/>ピクセル単位 移動中でないならグリッド(16*16)にぴったりおさまる
 $C1x7  | intra-animation-frame counter  |  0から4までのアニメーションフレームカウンタ<br/>4になるとc1x8がインクリメントされる 歩きモーションなどのアニメーションのフレームカウントに利用
 $C1x8  | animation frame counter  |  0から3までのカウンタ <br/>歩きモーションなどのアニメーションの状態を表すのに利用 つまり歩きモーションには16フレームかかる 
 $C1x9  | facing direction  |  スプライトの方向 <br/>0: 下, 4: 上, 8: 左, $c: 右
 $C1xa  | undefined  |  ???
 $C1xb  | undefined  |  ???
 $C1xc  | undefined  |  ???
 $C1xd  | undefined  |  ???
 $C1xe  | undefined  |  ???
 $C1xf  | undefined  |  ???

#### sprite image index(\$C1x2)

sprite image indexは次の式で算出される [参考: .calcImageIndex](./../engine/overworld/movement.asm)

```
[$C1x2] = [$C1x8] + [$C1x9] = (animation frame counter) + (facing direction)
```

#### animation frame counter(\$C1x7,\$C1x8)

アニメーションフレームカウンタが\$C1x7と\$C1x8の2つの領域に分かれているのは、アニメーション自体には16フレームかかるが、取りうるアニメーションの画像は4パターンしかないので、アニメーションフレームを階層構造を持たせてカウントするためだと考えられる

つまり\$C1x8を見ればどのアニメーション画像を使えばいいかがわかり、\$C1x7と\$C1x8の両方を合わせることでアニメーション16フレームのうち何フレーム目かがわかる

## wSpriteStateData2(2つ目のデータ領域)

2つ目のデータ領域は以下のような構造を取っている

 アドレス  | ラベル |  内容
---- | ---- | ----
 $C2x0  | walk animation counter  |  歩きモーションのアニメーションカウンタ <br/>$10から移動した分だけ減っていく
 $C2x1  | ???  |  用途不明
 $C2x2  | Y displacement  |  8で初期化 スプライトが初期座標から離れすぎないために設定されていると考えられるがバグがある
 $C2x3  | X displacement  |  8で初期化 スプライトが初期座標から離れすぎないために設定されていると考えられるがバグがある
 $C2x4  | Y position  |  Y 座標 <br/>16\*16のマスのどこにいるかを表している <br/>一番上のマスにいるときは4となるようになっている <bg/>例: 一番上のマスから1マス下にいるときは5になる
 $C2x5  | X position  |  X 座標 <br/>16\*16のマスのどこにいるかを表している <br/>一番左のマスにいるときは4となるようになっている
 $C2x6  | movement byte 1  |  スプライトの動きを決めるデータその1 [movement byte](./movement_byte.md)参照
 $C2x7  | ???  |  草むらにスプライトがいるとき$80になってそれ以外では$0になっている<br/>おそらくスプライトの上に草むらを描画するのに利用
 $C2x8  | delay until next movement  |  次の動きまでのクールタイム <br/>どんどん減って行って, 0になるとC1x1が1にセットされる
 $C2x9  | undefined  |  ???
 $C2xa  | undefined  |  ???
 $C2xb  | undefined  |  ???
 $C2xc  | undefined  |  ???
 $C2xd  | undefined  |  ???
 $C2xe  | sprite image base offset  |  スプライトの画像データ(タイルデータ)のVRAM内でのオフセット <br/>プレイヤーは常に1となる <br/>\$C1x2の計算に利用される
 $C2xf  | undefined  |  ???
