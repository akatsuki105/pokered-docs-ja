; **DrawPartyMenu_**  
; 手持ち画面を描画する  
; - - -  
; [wPartyMenuTypeOrMessageID] = menuType(x < $F0のとき) or messageID(x >= $F0のとき)  
DrawPartyMenu_:
	; SDキャラをVRAMに転送する  
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a
	call ClearScreen
	call UpdateSprites
	callba LoadMonPartySpriteGfxWithLCDDisabled ; load pokemon icon graphics

; **RedrawPartyMenu_**  
; 手持ち画面を描画する  
; - - -  
; [wPartyMenuTypeOrMessageID] = menuType(x < $F0のとき) or messageID(x >= $F0のとき)  
RedrawPartyMenu_:
	; SWAP_MONS_PARTY_MENU のときはすでに手持ち画面は描画されているので -> .printMessage
	ld a, [wPartyMenuTypeOrMessageID]
	cp SWAP_MONS_PARTY_MENU
	jp z, .printMessage

; ここから手持ち画面を描画していく  
	call ErasePartyMenuCursors
	callba InitPartyMenuBlkPacket

	; ループ変数の初期化
	coord hl, 3, 0	; (3, 0) 一匹めのポケモンの名前の位置
	ld de, wPartySpecies
	xor a
	ld c, a
	ld [hPartyMonIndex], a
	ld [wWhichPartyMenuHPBar], a

.loop
	; 手持ち全部処理した -> .afterDrawingMonEntries
	ld a, [de]
	cp $FF
	jp z, .afterDrawingMonEntries

	push bc
	push de
	push hl	; push 処理中のポケモンの名前の位置

	; ポケモンの名前を描画
	ld a, c
	push hl
	ld hl, wPartyMonNicks
	call GetPartyMonName
	pop hl
	call PlaceString

	; SDキャラをOAMに格納する
	callba WriteMonPartySpriteOAMByPartyIndex
	
	; [hPartyMonIndex]をインクリメント
	ld a, [hPartyMonIndex]
	ld [wWhichPokemon], a	; LoadMonDataで使う
	inc a
	ld [hPartyMonIndex], a
	call LoadMonData
	
	; hl = ポケモンの名前の位置
	pop hl
	push hl
	
	ld a, [wMenuItemToSwap]
	and a ; is the player swapping pokemon positions?
	jr z, .skipUnfilledRightArrow

; if the player is swapping pokemon positions
	dec a
	ld b, a
	ld a, [wWhichPokemon]
	cp b ; is the player swapping the current pokemon in the list?
	jr nz, .skipUnfilledRightArrow
; the player is swapping the current pokemon in the list
	dec hl
	dec hl
	dec hl
	ld a, "▷" ; unfilled right arrow menu cursor
	ld [hli], a ; place the cursor
	inc hl
	inc hl
	
.skipUnfilledRightArrow
	ld a, [wPartyMenuTypeOrMessageID] ; menu type
	cp TMHM_PARTY_MENU
	jr z, .teachMoveMenu
	cp EVO_STONE_PARTY_MENU
	jr z, .evolutionStoneMenu
	push hl
	ld bc, 14 ; 14 columns to the right
	add hl, bc
	ld de, wLoadedMonStatus
	call PrintStatusCondition
	pop hl
	push hl
	ld bc, SCREEN_WIDTH + 1 ; down 1 row and right 1 column
	ld a, [hFlags_0xFFF6]
	set 0, a
	ld [hFlags_0xFFF6], a
	add hl, bc
	predef DrawHP2 ; draw HP bar and prints current / max HP
	ld a, [hFlags_0xFFF6]
	res 0, a
	ld [hFlags_0xFFF6], a
	call SetPartyMenuHPBarColor ; color the HP bar (on SGB)
	pop hl
	jr .printLevel
.teachMoveMenu
	push hl
	predef CanLearnTM ; check if the pokemon can learn the move
	pop hl
	ld de, .ableToLearnMoveText
	ld a, c
	and a
	jr nz, .placeMoveLearnabilityString
	ld de, .notAbleToLearnMoveText
.placeMoveLearnabilityString
	ld bc, 20 + 9 ; down 1 row and right 9 columns
	push hl
	add hl, bc
	call PlaceString
	pop hl
.printLevel
	ld bc, 10 ; move 10 columns to the right
	add hl, bc
	call PrintLevel
	pop hl
	pop de
	inc de
	ld bc, 2 * 20
	add hl, bc
	pop bc
	inc c
	jp .loop
.ableToLearnMoveText
	db "ABLE@"
.notAbleToLearnMoveText
	db "NOT ABLE@"
.evolutionStoneMenu
	push hl
	ld hl, EvosMovesPointerTable
	ld b, 0
	ld a, [wLoadedMonSpecies]
	dec a
	add a
	rl b
	ld c, a
	add hl, bc
	ld de, wEvosMoves
	ld a, BANK(EvosMovesPointerTable)
	ld bc, 2
	call FarCopyData
	ld hl, wEvosMoves
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld de, wEvosMoves
	ld a, BANK(EvosMovesPointerTable)
	ld bc, wEvosMoves.end - wEvosMoves
	call FarCopyData
	ld hl, wEvosMoves
	ld de, .notAbleToEvolveText
; loop through the pokemon's evolution entries
.checkEvolutionsLoop
	ld a, [hli]
	and a ; reached terminator?
	jr z, .placeEvolutionStoneString ; if so, place the "NOT ABLE" string
	inc hl
	inc hl
	cp EV_ITEM
	jr nz, .checkEvolutionsLoop
; if it's a stone evolution entry
	dec hl
	dec hl
	ld b, [hl]
	ld a, [wEvoStoneItemID] ; the stone the player used
	inc hl
	inc hl
	inc hl
	cp b ; does the player's stone match this evolution entry's stone?
	jr nz, .checkEvolutionsLoop
; if it does match
	ld de, .ableToEvolveText
.placeEvolutionStoneString
	ld bc, 20 + 9 ; down 1 row and right 9 columns
	pop hl
	push hl
	add hl, bc
	call PlaceString
	pop hl
	jr .printLevel
.ableToEvolveText
	db "ABLE@"
.notAbleToEvolveText
	db "NOT ABLE@"
.afterDrawingMonEntries
	ld b, SET_PAL_PARTY_MENU
	call RunPaletteCommand

.printMessage
	; テキスト表示は一気にするようにする
	ld hl, wd730
	ld a, [hl]
	push af
	push hl
	set 6, [hl]

	; [wPartyMenuTypeOrMessageID] が messageID -> .printItemUseMessage
	ld a, [wPartyMenuTypeOrMessageID]
	cp $F0
	jr nc, .printItemUseMessage

; menu typeのとき
	; PartyMenuMessagePointers の該当エントリのテキストを描画
	add a
	ld hl, PartyMenuMessagePointers
	ld b, 0
	ld c, a
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call PrintText

.done
	; 終了
	pop hl
	pop af
	ld [hl], a
	ld a, 1
	ld [H_AUTOBGTRANSFERENABLED], a
	call Delay3
	jp GBPalNormal	; return

.printItemUseMessage
; messageIDのとき
	; PartyMenuItemUseMessagePointers の該当エントリのテキストを描画
	and $0F
	ld hl, PartyMenuItemUseMessagePointers
	add a
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	push hl
	ld a, [wUsedItemOnWhichPokemon]
	ld hl, wPartyMonNicks
	call GetPartyMonName
	pop hl
	call PrintText
	jr .done

; **PartyMenuItemUseMessagePointers**  
; dw AntidoteText
; dw BurnHealText
; dw IceHealText
; dw AwakeningText
; dw ParlyzHealText
; dw PotionText
; dw FullHealText
; dw ReviveText
; dw RareCandyText
PartyMenuItemUseMessagePointers:
	dw AntidoteText
	dw BurnHealText
	dw IceHealText
	dw AwakeningText
	dw ParlyzHealText
	dw PotionText
	dw FullHealText
	dw ReviveText
	dw RareCandyText

; **PartyMenuMessagePointers**  
; dw PartyMenuNormalText
; dw PartyMenuItemUseText
; dw PartyMenuBattleText
; dw PartyMenuUseTMText
; dw PartyMenuSwapMonText
; dw PartyMenuItemUseText
PartyMenuMessagePointers:
	dw PartyMenuNormalText
	dw PartyMenuItemUseText
	dw PartyMenuBattleText
	dw PartyMenuUseTMText
	dw PartyMenuSwapMonText
	dw PartyMenuItemUseText

; "Choose a #MON."
PartyMenuNormalText:
	TX_FAR _PartyMenuNormalText
	db "@"

; "Use item on which #MON?"
PartyMenuItemUseText:
	TX_FAR _PartyMenuItemUseText
	db "@"

; "Bring out which #MON?"
PartyMenuBattleText:
	TX_FAR _PartyMenuBattleText
	db "@"

; "Use TM on which #MON?"
PartyMenuUseTMText:
	TX_FAR _PartyMenuUseTMText
	db "@"

; "Move #MON where?"
PartyMenuSwapMonText:
	TX_FAR _PartyMenuSwapMonText
	db "@"

; "${wcd6d} recovered by ${HP}!"
PotionText:
	TX_FAR _PotionText
	db "@"

; "${wcd6d} was cured of poison!"
AntidoteText:
	TX_FAR _AntidoteText
	db "@"

; "${wcd6d}'s rid of paralysis!"
ParlyzHealText:
	TX_FAR _ParlyzHealText
	db "@"

; "${wcd6d}'s burn was healed!"
BurnHealText:
	TX_FAR _BurnHealText
	db "@"

; "${wcd6d} was defrosted!"
IceHealText:
	TX_FAR _IceHealText
	db "@"

; "${wcd6d} woke up!"
AwakeningText:
	TX_FAR _AwakeningText
	db "@"

; "${wcd6d}'s health returned!"
FullHealText:
	TX_FAR _FullHealText
	db "@"

; "${wcd6d} is revitalized!"
ReviveText:
	TX_FAR _ReviveText
	db "@"

; "${wcd6d} grew to level ${Lv}!"
RareCandyText:
	TX_FAR _RareCandyText
	TX_SFX_ITEM_1 ; probably supposed to play SFX_LEVEL_UP but the wrong music bank is loaded
	TX_BLINK
	db "@"

SetPartyMenuHPBarColor:
	ld hl, wPartyMenuHPBarColors
	ld a, [wWhichPartyMenuHPBar]
	ld c, a
	ld b, 0
	add hl, bc
	call GetHealthBarColor
	ld b, UPDATE_PARTY_MENU_BLK_PACKET
	call RunPaletteCommand
	ld hl, wWhichPartyMenuHPBar
	inc [hl]
	ret
