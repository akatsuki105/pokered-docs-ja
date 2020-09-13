; 配列やテーブルに関する定数

; list menu ID's
PCPOKEMONLISTMENU  EQU $00 ; PC pokemon withdraw/deposit lists
MOVESLISTMENU      EQU $01 ; XXX where is this used?
PRICEDITEMLISTMENU EQU $02 ; Pokemart buy menu / Pokemart buy/sell choose quantity menu
ITEMLISTMENU       EQU $03 ; かばんの中身
SPECIALLISTMENU    EQU $04 ; list of special "items" e.g. floor list in elevators / list of badges

; GetName でどのカテゴリの名前を取得するかを決める変数。 wNameListType に格納される
MONSTER_NAME  EQU 1
MOVE_NAME     EQU 2
; ???_NAME    EQU 3
ITEM_NAME     EQU 4
PLAYEROT_NAME EQU 5
ENEMYOT_NAME  EQU 6
TRAINER_NAME  EQU 7

INIT_ENEMYOT_LIST    EQU 1
INIT_BAG_ITEM_LIST   EQU 2
INIT_OTHER_ITEM_LIST EQU 3
INIT_PLAYEROT_LIST   EQU 4
INIT_MON_LIST        EQU 5
