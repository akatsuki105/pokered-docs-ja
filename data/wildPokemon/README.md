# wildPokemon

マップで出てくる野生のポケモンのデータを記述している場所

## 解説

[ディグダのあな](./diglettscave.asm)を例にコメントを付けた

```asm
; diglettscave.asm

CaveMons:           ; マップ出現データのシンボル
	db $14          ; ポケモンのエンカウント率
	db 18,DIGLETT   ; Lv18のディグダ
	db 19,DIGLETT   ; Lv19のディグダ
	db 17,DIGLETT   ; Lv17のディグダ
	db 20,DIGLETT   ; Lv20のディグダ
	db 16,DIGLETT   ; Lv16のディグダ
	db 15,DIGLETT   ; Lv15のディグダ
	db 21,DIGLETT   ; Lv21のディグダ
	db 22,DIGLETT   ; Lv22のディグダ
	db 29,DUGTRIO   ; Lv29のダグトリオ
	db 31,DUGTRIO   ; Lv31のダグトリオ
	db $00
```

`CaveMons`はマップ出現データのシンボルで`WildDataPointers`で出現データを設定するときに利用される  

初代は洞窟マップがそもそも少ないからか、このレポジトリではCaveMons(洞窟のモンスター)というシンボルがディグダの穴を指す

次の`db $14`というのはポケモンのエンカウント率を表しており、この数値が高いほどエンカウントの確率が高くなる

そのあとの行では`db LEVEL POKEMON`という形で出現するポケモンを設定している  
かならず20バイト分(10種類分)定義する必要がある

最後の`db $00`でマップ出現データの終わりを定義している

## tips

このデータをいじれば出現する野生のポケモンを好きに設定できる
