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

## 関連

- [DisplayListMenuID](./../home.asm)
- [list_constants.asm](./../constants/list_constants.asm)
