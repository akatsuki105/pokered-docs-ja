# PCボックス

PCボックスにはポケモンを20匹まで収納できる

## WRAM

PCボックスのポケモンのデータは、 WRAMの `wBoxDataStart` で管理されている

`wBoxDataStart` は大きく分けて

- wNumInBox PCボックスの[Pokemon ID](./pokemon_id.md)
- wBoxMons PCボックスの [`Pokemon Data`](./pokemon_data.md)
- wBoxMonOT PCボックスのポケモンの元々の親名
- wBoxMonNicks PCボックスのポケモンのニックネーム

にわけられる

### wNumInBox

```asm  
wNumInBox::     ds 1        ; 現在のボックスの数
wBoxSpecies::   ds 20 + 1   ; ポケモンIDのエントリ + 終端記号 [ID, ID, ...]
```

`wNumInBox` と `wBoxSpecies` で 最大長さ20のポケモンIDの[list](../list.md)を形成している

### wBoxMons

```asm
wBoxMons::
wBoxMon1:: box_struct wBoxMon1
wBoxMon2:: ds box_struct_length * (20 + -1)
```

PCボックスのポケモンの[`Pokemon Data`](./pokemon_data.md)を格納した要素数20のテーブル

### wBoxMonOT & wBoxMonNicks

```asm
NAME_LENGTH EQU 11
wBoxMonOT::    ds NAME_LENGTH * 20  ; [name, name, ...]
wBoxMonNicks:: ds NAME_LENGTH * 20  ; [name, name, ...]
```

wBoxMonOT にはポケモンの元々の親名を文字列として格納する

wBoxMonNicks には手持ちのポケモンのニックネームを文字列として格納する。  
ニックネームを付けない場合は、種族名が入る。

11 は終端記号を含むプレイヤー・ポケモンの名前の最大文字数(英語版なので日本語版より多い)