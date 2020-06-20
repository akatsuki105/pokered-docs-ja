# Uncompress

解凍(Uncompress)を行うコードは `home/pic.asm` に格納されている

## workflow

Uncompress処理は `UncompressSpriteData` から始まり以下のように続いていく

<img src="./uncompress_flowchart.svg">

<dl>
  <dt>UncompressSpriteData</dt>
  <dd>aレジスタで指定した対象のグラフィックがあるバンクにスイッチして `_UncompressSpriteData` を呼び出す</dd>

  <dt>_UncompressSpriteData</dt>
  <dd>スプライトをロードするのに必要なデータを初期化し、 グラフィックのメタデータを取得した後で `UncompressSpriteDataLoop` を呼び出す</dd>
  <dd>グラフィックのメタデータというのは、グラフィックの大きさや `wSpriteLoadFlags` のことである。</dd>

  <dt>UncompressSpriteDataLoop</dt>
  <dd>Uncompress処理は実質的にここから始まる。</dd>
  <dd>詳しくは後述。</dd>

  <dt>.WriteSpriteBitsToBuffer & MoveToNextBufferPosition</dt>
  <dd>入力から読み取ったデータを Unpack処理で使うoutput bufferに格納する。</dd>
  <dd>詳しくは後述。</dd>

  <dt>.readRLEncodedZeros</dt>
  <dd>ランレングス圧縮されたデータを解凍する。</dd>
  <dd>詳しくは後述。</dd>

  <dt>UnpackSprite</dt>
  <dd>output bufferに入っているデータを Unpackして output bufferに戻す。</dd>
  <dd>詳しくは後述。</dd>
</dl>

## 変数

Uncompress処理 で使用される変数について

<dl>
  <dt>wSpriteInputPtr</dt>
  <dd>ここから解凍対象の圧縮されたスプライトのグラフィックデータを読み込む</dd>

  <dt>wSpriteOutputPtr</dt>
  <dd>ここに解凍したスプライトのグラフィックデータを書き込む</dd>

  <dt>wSpriteLoadFlags</dt>
  <dd>解凍処理の制御フラグ</dd>
</dl>

## UncompressSpriteDataLoop

Uncompress処理は実質的にここから始まる。

### workflow

<img src="./UncompressSpriteDataLoop_flowchart.svg">

基本的な処理は、入力から2bit読み取ってoutput bufferに書き込んでいくという処理

output buffer は `UncompressSpriteDataLoop`の最初に `wSpriteLoadFlags`のbit0によって `sSpriteBuffer1` と `sSpriteBuffer2` のどちらを使うか決まる 

`.readNextInput` では対象のスプライトデータを 2bitずつ output bufferにコピーしていくループに入る

2bitずつ outpub bufferにコピーをする処理は、 `.WriteSpriteBitsToBuffer` と `MoveToNextBufferPosition`で行う

`.WriteSpriteBitsToBuffer`でoutput bufferに2bit書き込みを行い、`MoveToNextBufferPosition`で書き込んだ分ポインタを進める。

`MoveToNextBufferPosition`で進めたoutput bufferのポインタが終端に来た時、つまり対象のスプライトデータの全てをoutput bufferにコピーし終えたとき、一度目ではもう一つのチャンク(output buffer)に切り替えて `UncompressSpriteDataLoop` を呼び出し、後続のグラフィックデータを同じサイズ分詰める処理を行う

これは、1つのチャンク(output buffer)に入っているデータが 2bppフォーマットの半分(1bppフォーマット)であるためである  

二度目では2bpp分のデータがoutput bufferにそろったので `UnpackSprite` を呼び出してUnpack処理に移行する

データによってはランレングス圧縮されていることもあり、その場合は入力のbitからわかるのでそのときには `.readRLEncodedZeros` でランレングス圧縮されたスプライトデータを解凍して output buffer にコピーする 

### .readRLEncodedZeros

スプライトデータによってはランレングス圧縮されているものもある

`UncompressSpriteDataLoop` で

- `.startDecompression` で読み取った bit が 0 つまりスプライトのデータ本体の最初のbitが 0 のとき
- `.readNextInput` で読み取った 2bitが両方とも 0 のとき

このときに `.readRLEncodedZeros` に移り、以降のデータをランレングス圧縮されたものとみなして解凍し解凍したデータを output bufferに格納して `.readNextInput` のループに戻る

## UnpackSprite

スプライトデータを全て output bufferにコピーし終えた後は、この関数で Unpack処理を行っていく

`UnpackSprite` では `wSpriteUnpackMode`に格納された値によってUnpackの内容を変える

<dl>
  <dt>Mode0</dt>
  <dd>`wSpriteUnpackMode`が 0 のときは Mode0</dd>
  <dd>Mode0のUnpackでは 各output buffer に対して `SpriteDifferentialDecode` を行う</dd>
  <dd>`SpriteDifferentialDecode`ではoutput bufferを、バイト(2ニブル)ごとに differential decodingしていく</dd>

  <dt>Mode1</dt>
  <dd>`wSpriteLoadFlags`の値を見て、2つのoutput bufferを source bufferとdestination bufferに分ける</dd>
  <dd>source buffer に対して `SpriteDifferentialDecode` を行い、そのあと2つのoutput bufferの XORを取る</dd>
  <dd>その結果を destination bufferに格納する</dd>

  <dt>Mode2</dt>
  <dd>Mode1同様に `wSpriteLoadFlags`の値を見て、2つのoutput bufferを source bufferとdestination bufferに分ける</dd>
  <dd>Mode1 と違ってoutput buffer両方に対して `SpriteDifferentialDecode`を行いそのあと2つのoutput bufferの XORを取る</dd>
  <dd>その結果を destination bufferに格納する</dd>
</dl>

### differential encoding について

[Differential encoding](./differential_encoding.md)参照
