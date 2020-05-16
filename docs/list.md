# list

ポケモン赤で用いられる配列のフォーマットの一つ

```asm
ListName:
    db 2        ; listのエントリ数
    db ...      ; listのエントリ1
    db ...      ; listのエントリ2
    db -1       ; 終端記号

;　engine/battle/core.asm 
OldManItemList:
	db 1 ; # items
	db POKE_BALL, 50
	db -1
```

## list menu

list menuというlistの内容を表示しプレイヤーに選択させるためのメニュー

スタートメニューのかばんやショップの売り物のリストなどを表示するメニューのことである

#### list menuで表示されるlistの一覧

`constants/list_constants.asm` 参照

 label  |  desc
---- | ----
 PCPOKEMONLISTMENU  |  PCのポケモン引き出し預け時のポケモン選択リスト
 MOVESLISTMENU  |  技選択リスト
 PRICEDITEMLISTMENU  |  ショップで買いたいもの(売り物一覧) / Pokemart buy/sell choose quantity menu
 ITEMLISTMENU  |  スタートメニューのかばん / ショップで売りたいもの(中身はかばんと同じ)
 SPECIALLISTMENU  |  エレベータの階層一覧 / バッジのリスト(ハナダのバッジおじさん) などの特別な選択リスト

#### list menuの例

![bag](../docs/image/menu/item_list.jpg) &nbsp; ![sell](../docs/image/menu/sell_list.png)

#### その他

メニューに一度に表示できるアイテムは4つまで

画面の定位置に表示される


## 関連

- [DisplayListMenuID](./../home.asm)
- [list_constants.asm](./../constants/list_constants.asm)
