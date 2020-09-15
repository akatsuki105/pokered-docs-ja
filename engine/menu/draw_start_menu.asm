; **DrawStartMenu**  
; start menu を画面に描画する  
; - - -  
; 描画するだけで入力のハンドル処理は行わない  
DrawStartMenu:

; start menu のテキストボックスを描画
	CheckEvent EVENT_GOT_POKEDEX
	coord hl, 10, 0
	ld b, $0e	; 図鑑取得済み -> 8×14 のテキストボックス
	ld c, $08
	jr nz, .drawTextBoxBorder
	coord hl, 10, 0
	ld b, $0c	; 図鑑未取得 -> 8×12のテキストボックス
	ld c, $08
.drawTextBoxBorder
	call TextBoxBorder

	; A/B/↑/↓/Startボタンに反応する
	ld a, D_DOWN | D_UP | START | B_BUTTON | A_BUTTON
	ld [wMenuWatchedKeys], a

	; (11, 2) を1番上の項目のカーソルの位置とする
	ld a, $02
	ld [wTopMenuItemY], a
	ld a, $0b
	ld [wTopMenuItemX], a

	; 最後に選んだところにカーソルを当てる
	ld a, [wBattleAndStartSavedMenuItem] ; remembered menu selection from last time
	ld [wCurrentMenuItem], a
	ld [wLastMenuItem], a

	; wrappingは有効
	xor a
	ld [wMenuWatchMovingOutOfBounds], a

	; start menuはテキストを一気に表示
	ld hl, wd730
	set 6, [hl]

; 図鑑取得済みなら POKEDEXの項目をstart menuに描画
	coord hl, 12, 2
	CheckEvent EVENT_GOT_POKEDEX
	ld a, $06
	jr z, .storeMenuItemCount
	ld de, StartMenuPokedexText
	call PrintStartMenuItem	; "POKéDEX"
	ld a, $07
	
.storeMenuItemCount
	ld [wMaxMenuItem], a ; start menu の項目数

	; "POKéMON", "ITEM", "RED" をstart menuに描画
	ld de, StartMenuPokemonText
	call PrintStartMenuItem	; "POKéMON"
	ld de, StartMenuItemText
	call PrintStartMenuItem	; "ITEM"
	ld de, wPlayerName 
	call PrintStartMenuItem ; "RED"(player's name)

; "SAVE" or "RESET" を start menu に描画 (通信ルームにいるときは RESET)
	ld a, [wd72e]
	bit 6, a ; is the player using the link feature?
	ld de, StartMenuSaveText
	jr z, .printSaveOrResetText
	ld de, StartMenuResetText
.printSaveOrResetText
	call PrintStartMenuItem

	; "OPTION", "EXIT" をstart menuに描画
	ld de, StartMenuOptionText
	call PrintStartMenuItem
	ld de, StartMenuExitText
	call PlaceString

	; 終了
	ld hl, wd730
	res 6, [hl] ; turn pauses between printing letters back on
	ret

; "POKéDEX"
StartMenuPokedexText:
	db "POKéDEX@"

; "POKéMON"
StartMenuPokemonText:
	db "POKéMON@"

; "ITEM"
StartMenuItemText:
	db "ITEM@"

; "SAVE"
StartMenuSaveText:
	db "SAVE@"

; "RESET"
StartMenuResetText:
	db "RESET@"

; "EXIT"
StartMenuExitText:
	db "EXIT@"

; "OPTION"
StartMenuOptionText:
	db "OPTION@"

PrintStartMenuItem:
	push hl
	call PlaceString
	pop hl
	ld de, SCREEN_WIDTH * 2
	add hl, de
	ret
