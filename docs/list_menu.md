# list menu

![bag](../docs/image/menu/item_list.jpg) &nbsp; ![sell](../docs/image/menu/sell_list.png)

list menuという [list](./list.md) の内容を表示しプレイヤーに選択させるための [menu](./menu.md)

スタートメニューのかばんやショップの売り物のリストなどを表示する menu のことである

## List Menu ID

list menuで表示されるlistのカテゴリはあらかじめ決まっており、それらを指定するのがList Menu ID

#### PCPOKEMONLISTMENU

<img src="../docs/image/menu/pokemon_list_menu.png" width="320px" height="288px" />

PCのポケモン引き出し預け時のポケモン選択リスト

#### MOVESLISTMENU

<img src="../docs/image/menu/move_list_menu.png" width="320px" height="288px" />

技選択リスト

#### PRICEDITEMLISTMENU

<img src="../docs/image/menu/buy_list.png" width="320px" height="288px" />

<img src="../docs/image/menu/vending_machine.png" width="320px" height="288px" />

ショップで買いたいもの(売り物一覧)

#### ITEMLISTMENU

<img src="../docs/image/menu/item_list.jpg" width="320px" height="288px" />

<img src="../docs/image/menu/sell_list.png" width="320px" height="288px" />

スタートメニューのかばん / ショップで売りたいもの(中身はかばんと同じ)

#### SPECIALLISTMENU

<img src="../docs/image/menu/elevator.png" width="320px" height="288px" />

エレベータの階層一覧 / バッジのリスト(ハナダのバッジおじさん) などの特別な選択リスト

## memo

メニューに一度に表示できるアイテムは4つまで

カーソルが3項目めから4項目めにいくときにスクロールが生じる(よってカーソルは4項目目にいくことはない)

画面の定位置に表示される