# 育て屋

初代の育て屋は、ポケモンを1匹しか預けられないことに注意

## WRAM

育て屋のポケモンのデータは、 WRAMの `wDayCareInUse` から始まる領域で管理されている

大きく分けて

- wDayCareInUse 育て屋にポケモンを預けているか
- wDayCareMonName 預けているポケモンのニックネーム
- wDayCareMonOT 預けているポケモンの元々の親名
- wDayCareMon 預けているポケモンの [`Pokemon Data`](./pokemon_data.md)

にわけられる
