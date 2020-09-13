# menu

ポケモン赤でのmenuは、

- マップ上でスタートボタンを押すと現れるウィンドウ
- はい、いいえの2択ウィンドウ
- その他の様々な選択肢を表示するウィンドウ

といったようにプレイヤーに選択を要求するウィンドウのことを表している

## 例  

<img src="../docs/image/menu/menu.jpg" width="320px" height="288px" alt="start"> &nbsp; <img src="../docs/image/menu/fossil.png" width="320px" height="288px" alt="fossil">

<img src="https://imgur.com/rJQSNz1.png" width="320px" height="288px" alt="yesno"> &nbsp; <img src="https://imgur.com/wRa62p9.png" width="320px" height="288px" alt="heal">

## ID

menu のどの項目を選択しているかを識別するために項目に割り振られた値

上から順に 0, 1, 2, 3, ...と割り振られていく(一番上のアイテムというのは現在画面で見えている一番上のアイテムのことを指すことに注意)

## wrapping

選択menuで一番下の選択肢にあるときに下を押したときに一番上に戻る、または一番上のmenuにあるときに上を押したときに一番下にいく状態のこと

## list menu

[list menu](./list_menu.md) 参照
