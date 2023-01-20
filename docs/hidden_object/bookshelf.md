# 本棚

本棚、タウンマップ、陳列棚は HiddenObjects、ではあるが `data/hidden_objects.asm` ではなく `hidden_object_functions3.asm`の `BookshelfTileIDs`で内容が記述されている

おそらくゲーム内で頻出する HiddenObjects は後述のように タイルセットとタイル番号 で指定したほうが記述量が削減できるのであろうと思われる

## BookshelfTileIDs

```asm
BookshelfTileIDs:
	db PLATEAU,      $30			; タイルセットID, タイル番号
	db_tx_pre IndigoPlateauStatues	; TextID

	db HOUSE,        $3D
	db_tx_pre TownMapText

    db HOUSE,        $1E
	db_tx_pre BookOrSculptureText

    ...
```