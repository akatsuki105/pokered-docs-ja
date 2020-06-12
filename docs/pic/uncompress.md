# Uncompress

解凍(Uncompress)を行うコードは `home/pic.asm` に格納されている

## workflow

Uncompress処理は `UncompressSpriteData` から始まり以下のように続いていく

<img src="./uncompress_flowchart.svg">

<dl>
  <dt>UncompressSpriteData</dt>
  <dd>aレジスタで指定した対象のグラフィックがあるバンクにスイッチして _UncompressSpriteData を呼び出す</dd>

  <dt>_UncompressSpriteData</dt>
  <dd>スプライトをロードするのに必要なデータを初期化し、 UncompressSpriteDataLoop を呼び出す</dd>

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

## UncompressSpriteDataLoop

### 変数

picの uncompress で使用される変数について

<dl>
  <dt>wSpriteInputPtr</dt>
  <dd>ここから解凍対象の圧縮されたスプライトのグラフィックデータを読み込む</dd>

  <dt>wSpriteOutputPtr</dt>
  <dd>ここに解凍したスプライトのグラフィックデータを書き込む</dd>
</dl>

### workflow

スプライトのグラフィックデータの Unpack は `WriteSpriteBitsToBuffer`, `MoveToNextBufferPosition`, `SpriteDifferentialDecode` で行われる

<dl>
  <dt>WriteSpriteBitsToBuffer</dt>
  <dd>wSpriteInputPtr から読み取った 2bitのデータを wSpriteOutputPtr の指す場所に書き込む</dd>

  <dt>MoveToNextBufferPosition</dt>
  <dd>WriteSpriteBitsToBuffer で書き込んだ分 wSpriteOutputPtrを進める</dd>

</dl>

## UnpackSprite

