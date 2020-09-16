; **DisplayStartMenu**  
; start menu に入る処理  
; - - -  
; start menuの描画、ユーザー入力に対するハンドリング、各menu項目に対するハンドラへのジャンプなど start menuに関することを行う
DisplayStartMenu::
	ld a, BANK(StartMenu_Pokedex)
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	ld a, [wWalkBikeSurfState]
	ld [wWalkBikeSurfStateCopy], a	; [wWalkBikeSurfStateCopy] = [wWalkBikeSurfState]
	ld a, SFX_START_MENU
	call PlaySound
	; fallthrough

; **RedisplayStartMenu**  
; start menu を再描画する処理  
; - - -  
; 図鑑やかばんなどの start menuから飛んだ先の処理が終了した時に、この関数を呼ぶことでstart menuに戻ってくる  
RedisplayStartMenu::
	callba DrawStartMenu
	callba PrintSafariZoneSteps
	call UpdateSprites
	; この時点で start menuが表示されている 

.loop
	; start menu でユーザーのキー入力を待つ
	call HandleMenuInput
	ld b, a

.checkIfUpPressed
	; ↑が押されなかった -> .checkIfDownPressed
	bit 6, a
	jr z, .checkIfDownPressed
	; ↑が押された場合は 下の warpping 以外は何もしない (HandleMenuInputまかせでOK)
	; 一番上の項目で↑を押した場合一番下にカーソルを配置してあげる (wrap)
	ld a, [wCurrentMenuItem] ; menu selection
	and a
	jr nz, .loop
	ld a, [wLastMenuItem]
	and a
	jr nz, .loop
	; a = 6(図鑑あり) or 5(図鑑なし)
	CheckEvent EVENT_GOT_POKEDEX
	ld a, 6
	jr nz, .wrapMenuItemId
	dec a
.wrapMenuItemId
	ld [wCurrentMenuItem], a
	call EraseMenuCursor
	jr .loop

.checkIfDownPressed
	; ↓が押されなかった -> .buttonPressed
	bit 7, a
	jr z, .buttonPressed
	; ↓が押された場合は 下の warpping 以外は何もしない (HandleMenuInputまかせでOK)
	; 一番下の項目で↓を押した場合一番上にカーソルを配置してあげる (wrap)
	CheckEvent EVENT_GOT_POKEDEX
	ld a, [wCurrentMenuItem]
	ld c, 7
	jr nz, .checkIfPastBottom
	dec c
.checkIfPastBottom
	cp c
	jr nz, .loop
	xor a
	ld [wCurrentMenuItem], a
	call EraseMenuCursor
	jr .loop

.buttonPressed 
	; A/B/Startボタンが押された時
	call PlaceUnfilledArrowMenuCursor
	ld a, [wCurrentMenuItem]
	ld [wBattleAndStartSavedMenuItem], a ; どのmenuを選択したかを保存
	
	ld a, b	; a = キー入力 [↓, ↑, ←, →, Start, Select, B, A]

	; B/Startが押された -> CloseStartMenu
	and %00001010
	jp nz, CloseStartMenu

	; Aボタンが押された時は対応する menu のハンドラにjump
	call SaveScreenTilesToBuffer2 ; 背景のタイルデータを退避
	CheckEvent EVENT_GOT_POKEDEX
	ld a, [wCurrentMenuItem]
	jr nz, .displayMenuItem
	inc a	; ポケモン図鑑がないことによるmenuずれを調整
.displayMenuItem
	SWITCH2 0, StartMenu_Pokedex
	SWITCH2 1, StartMenu_Pokemon
	SWITCH2 2, StartMenu_Item
	SWITCH2 3, StartMenu_TrainerInfo
	SWITCH2 4, StartMenu_SaveReset
	SWITCH2 5, StartMenu_Option
	; SWITCH2 6, CloseStartMenu

; **CloseStartMenu**  
; start menuを閉じる処理  
CloseStartMenu::
	; ???
	call Joypad
	ld a, [hJoyPressed]
	bit 0, a ; was A button newly pressed?
	jr nz, CloseStartMenu

	call LoadTextBoxTilePatterns
	jp CloseTextDisplay	; return 
