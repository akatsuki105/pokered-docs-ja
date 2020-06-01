# テキストID

文字通りテキストデータを識別するためのID

0は常にスタートメニューを指し、各マップごとに1から順番にテキストに割り当てられている

どのようにテキストIDをテキストに割り当てるのかは`scripts/`で各マップごとに定義される

## 例

[CeruleanCity.asm](../scripts/CeruleanCity.asm)を例にすると

```asm
CeruleanCity_TextPointers:
	dw CeruleanCityText1    ; CeruleanCityText1にテキストID 1を割り当てる
	dw CeruleanCityText2    ; CeruleanCityText2にテキストID 2を割り当てる
	dw CeruleanCityText3    ; ...
	dw CeruleanCityText4
	dw CeruleanCityText5
	dw CeruleanCityText6
	dw CeruleanCityText7
	dw CeruleanCityText8
	dw CeruleanCityText9
	dw CeruleanCityText10
	dw CeruleanCityText11
	dw CeruleanCityText12
	dw CeruleanCityText13
	dw MartSignText
	dw PokeCenterSignText
	dw CeruleanCityText16
	dw CeruleanCityText17
```

のようになる

マップのテキストIDはこのように`MAP_NAME_TextPointers`で定義されている

## どのように使われるか

`home.asm` の `DisplayTextID` で表示したいテキストを識別するIDとして利用される

[テキスト](./text.md)も参照

