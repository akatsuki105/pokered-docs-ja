# テキスト

## TextID

マップ内のテキストに割り当てられたID  

## テキストテーブル

TextIDとテキストを結びつけるテーブル 

```asm
; scripts/PalletTown.asm
PalletTown_TextPointers:
	dw PalletTownText1	; TextID 1
	dw PalletTownText2
	dw PalletTownText3
	dw PalletTownText4
	dw PalletTownText5
	dw PalletTownText6
	dw PalletTownText7
```

`wMapTextPtr` に 現在のマップのテキストテーブルのアドレスが入る

## DisplayTextID

TextIDかスプライトのオフセットを渡すとテキストを表示してくれる関数

TextIDが渡されたときは、テキストIDに対応するテキストをそのまま表示

スプライトオフセットが渡されたときはそのスプライトのもっているテキストIDに対応するテキストを表示する