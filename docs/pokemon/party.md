# 手持ち

手持ちのポケモンのデータは、 WRAMの `wPartyDataStart` で管理されている

`wPartyDataStart` は大きく分けて

- wPartyCount 手持ちの[Pokemon ID](./pokemon_id.md)
- wPartyMons 手持ちの [`Pokemon Data`](./pokemon_data.md)
- wPartyMonOT 手持ちのポケモンの元々の親名
- wPartyMonNicks 手持ちのポケモンのニックネーム

にわけられる

## wPartyCount

```asm  
wPartyCount::   ds 1    ; d163 現在の手持ちの数
wPartySpecies:: ds 6    ; d164 各エントリにはポケモンID(1バイト)が格納される
wPartyEnd::     ds 1    ; d16a
```

`wPartyCount` と `wPartySpecies` と `wPartyEnd` で ポケモンIDの[list](../list.md)を形成している


## wPartyMons

```asm
wPartyMons::
wPartyMon1:: party_struct wPartyMon1 ; d16b
wPartyMon2:: party_struct wPartyMon2 ; d197
wPartyMon3:: party_struct wPartyMon3 ; d1c3
wPartyMon4:: party_struct wPartyMon4 ; d1ef
wPartyMon5:: party_struct wPartyMon5 ; d21b
wPartyMon6:: party_struct wPartyMon6 ; d247
```

手持ちのポケモンの[`Pokemon Data`](./pokemon_data.md)を格納した要素数6のテーブル

## wPartyMonOT & wPartyMonNicks

```asm
NAME_LENGTH EQU 11
wPartyMonOT:: ds NAME_LENGTH * 6
wPartyMonNicks:: ds NAME_LENGTH * 6
```

wPartyMonOT にはポケモンの元々の親名を文字列として格納する

wPartyMonNicks には手持ちのポケモンのニックネームを文字列として格納する。  
ニックネームを付けない場合は、種族名が入る。

11 は終端記号を含むプレイヤー・ポケモンの名前の最大文字数(英語版なので日本語版より多い)
