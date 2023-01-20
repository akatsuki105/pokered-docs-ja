; **CheckIfMoveIsKnown**  
; ポケモンが引数で指定した技をすでに覚えているか  
; - - -  
; INPUT:  
; [wWhichPokemon] = ポケモンのインデックス  
; [wMoveNum] = 技番号  
; 
; OUTPUT: carry = 1(すでに覚えている) or 0(覚えてない)
CheckIfMoveIsKnown:
	; hl = wPartyMon${N}Moves(覚えてる技のリスト)
	ld a, [wWhichPokemon]
	ld hl, wPartyMon1Moves
	ld bc, wPartyMon2 - wPartyMon1
	call AddNTimes

	ld a, [wMoveNum]
	ld b, a
	ld c, NUM_MOVES

; wPartyMon${N}Moves に [wMoveNum] と一致するものがあれば、覚えているということになる
.loop
; {
	ld a, [hli]
	cp b
	jr z, .alreadyKnown ; found a match
	dec c
	jr nz, .loop
; }

	and a
	ret

.alreadyKnown
	ld hl, AlreadyKnowsText
	call PrintText
	scf
	ret

AlreadyKnowsText:
	TX_FAR _AlreadyKnowsText
	db "@"
