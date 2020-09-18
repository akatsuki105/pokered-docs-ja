## テキストデータに関連するマクロ

`macros/text_macros.asm` で定義されている

```asm
text   EQUS "db $00,"
next   EQUS "db $4e,"
line   EQUS "db $4f,"
para   EQUS "db $51,"
cont   EQUS "db $55,"
done   EQUS "db $57"
prompt EQUS "db $58"
```

このように `db $XX` のように表されているので[特殊文字](charcode.md#%E7%89%B9%E6%AE%8A%E6%96%87%E5%AD%97)の一種と思えばいい

## text

ここからテキストの描画を開始

## next

テキスト配置場所を次の行にする特殊文字  

テキスト入力場所が次の行にシフトする  

## line

テキスト入力場所を (1, 16) に配置する特殊文字  

(1, 16)はテキストボックスの2行目なので、テキストボックス内での改行に利用される

## para

<img src="https://imgur.com/xEYPTfK.gif" width="320px" height="288px" />

次のパラグラフ(セリフの区切り)を開始する特殊文字

上の gif では `Hi! Remember me? I'm PROF.OAK's AIDE!` はスクロールしながら次のセリフを表示していってるが、`If you caught` はテキストボックスがクリアされてから描画されている

このテキストボックスをまっさらにして新しくテキストを描画するのが para の役割

## cont

次の行にテキストボックスをスクロールさせる特殊文字

## done

この特殊文字が描画されている時にプレイヤーがA/Bボタンを押した時にテキストボックスを終了させる

## prompt

done と同じだが、 "▼" が点滅していることが違う

主に、テキストボックスを閉じた後に別のイベントが起きる場合に使う
