# Uncompress

解凍(Uncompress)を行うコードは `home/pic.asm` に格納されている

## 変数

picの uncompress で使用される変数についての

<dl>
  <dt>wSpriteInputPtr</dt>
  <dd>ここから解凍対象の圧縮されたスプライトのグラフィックデータを読み込む</dd>

  <dt>wSpriteOutputPtr</dt>
  <dd>ここに解凍したスプライトのグラフィックデータを書き込む</dd>
</dl>

## スプライトのUnpack

スプライトのグラフィックデータの Unpack は `WriteSpriteBitsToBuffer`, `MoveToNextBufferPosition`, `SpriteDifferentialDecode` で行われる

<dl>
  <dt>WriteSpriteBitsToBuffer</dt>
  <dd>wSpriteInputPtr から読み取った 2bitのデータを wSpriteOutputPtr の指す場所に書き込む</dd>

  <dt>MoveToNextBufferPosition</dt>
  <dd>WriteSpriteBitsToBuffer で書き込んだ分 wSpriteOutputPtrを進める</dd>

  <dt>SpriteDifferentialDecode</dt>
  <dd>TODO</dd>
</dl>