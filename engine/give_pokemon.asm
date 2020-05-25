; **_GivePokemon**  
; プレイヤーにレベルcのポケモンbを与える  
; - - -  
; 
; OUTPUT:  
; - carry = 0(失敗) or 1(成功)
; - [wAddedToParty] = ポケモンがBoxではなく手持ちに入ったかどうか
_GivePokemon:
	call EnableAutoTextBoxDrawing
	
	; [wAddedToParty] = 0
	xor a
	ld [wAddedToParty], a

	; 手持ちに空きスロットがある -> .addToParty
	ld a, [wPartyCount]
	cp PARTY_LENGTH
	jr c, .addToParty
	
	; PCBoxも満杯 -> .boxFull
	ld a, [wNumInBox]
	cp MONS_PER_BOX
	jr nc, .boxFull

	; PCBoxに空きがあるのでPCBoxにポケモンを加える
	
	; [wEnemyBattleStatus3] = 0
	xor a
	ld [wEnemyBattleStatus3], a

	; [wEnemyMonSpecies2] = [wcf91]
	ld a, [wcf91]
	ld [wEnemyMonSpecies2], a

	; TODO
	callab LoadEnemyMonData

	call SetPokedexOwnedFlag
	callab SendNewMonToBox
	ld hl, wcf4b
	ld a, [wCurrentBoxNum]
	and $7f
	cp 9
	jr c, .singleDigitBoxNum
	sub 9
	ld [hl], "1"
	inc hl
	add "0"
	jr .next
.singleDigitBoxNum
	add "1"
.next
	ld [hli], a
	ld [hl], "@"
	ld hl, SetToBoxText
	call PrintText
	scf
	ret
.boxFull
	ld hl, BoxIsFullText
	call PrintText
	and a ; キャリーをクリア
	ret
.addToParty
	call SetPokedexOwnedFlag
	call AddPartyMon
	ld a, 1
	ld [wDoNotWaitForButtonPressAfterDisplayingText], a
	ld [wAddedToParty], a
	scf
	ret

SetPokedexOwnedFlag:
	ld a, [wcf91]
	push af
	ld [wd11e], a
	predef IndexToPokedex
	ld a, [wd11e]
	dec a
	ld c, a
	ld hl, wPokedexOwned
	ld b, FLAG_SET
	predef FlagActionPredef
	pop af
	ld [wd11e], a
	call GetMonName
	ld hl, GotMonText
	jp PrintText

; "<PLAYER> got <POKEMON>!"
GotMonText:
	TX_FAR _GotMonText
	TX_SFX_ITEM_1
	db "@"

; "There's no more room for #MON! <POKEMON> was sent to #MON BOX N on PC!"
SetToBoxText:
	TX_FAR _SetToBoxText
	db "@"

; "There's no more room for #MON! The #MON BOX is full and can't accept any more! Change the BOX at a #MON CENTER!"
BoxIsFullText:
	TX_FAR _BoxIsFullText
	db "@"
