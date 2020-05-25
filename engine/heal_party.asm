; **HealParty**  
; HPとPPを回復する  
HealParty:
	ld hl, wPartySpecies
	ld de, wPartyMon1HP
.healmon
	; パーティ全部の回復が終わった -> .done
	ld a, [hli]
	cp $ff
	jr z, .done

	push hl ; hl = ??? (stack_depth = 0)
	push de ; de = 現在処理中のポケモンのポインタ(wPartyMon${N}HP) (stack_depth = 1)

	; [hl] =  [wPartyMon1Status] = 0
	ld hl, wPartyMon1Status - wPartyMon1HP
	add hl, de
	xor a
	ld [hl], a

	push de	; de = 現在処理中のポケモンのポインタ(wPartyMon${N}HP) (stack_depth = 2)
	ld b, NUM_MOVES ; A Pokémon has 4 moves
.pp
	; hl = wPartyMon${N}Moves
	ld hl, wPartyMon1Moves - wPartyMon1HP
	add hl, de

	; そのスロットに技が存在しない？ -> .nextmove
	ld a, [hl]
	and a
	jr z, .nextmove

	dec a ; 現在処理中の技のID

	; hl =  wPartyMon${N}PP
	ld hl, wPartyMon1PP - wPartyMon1HP
	add hl, de

	push hl
	push de
	push bc

	; hl = 技に対応するMovesのエントリ
	; bc = Movesの1エントリの大きさ(6)
	ld hl, Moves
	ld bc, MoveEnd - Moves ; MoveEnd - Moves = 1エントリの大きさ(6)
	call AddNTimes

	; a = 技のPPの初期値
	ld de, wcd6d
	ld a, BANK(Moves)
	call FarCopyData	; Movesエントリをwcd6dにコピー
	ld a, [wcd6d + 5] 	; Movesエントリ内でのPPのオフセットは5

	pop bc
	pop de
	pop hl

	inc de
	push bc

	; 技のPPを初期値にする(回復する)
	ld b, a 	; b = 技のPPの初期値
	ld a, [hl] 	; a = 現在の技のPP
	and $c0
	add b
	ld [hl], a

	pop bc

.nextmove
	; まだ回復していない技がある -> .pp
	dec b
	jr nz, .pp

	; 技がすべて回復したら次はHPを回復する

	; de = 現在処理中のポケモンのポインタ(wPartyMon${N}HP)
	pop de

	; hl = 現在処理中のポケモンの最大HPのポインタ
	ld hl, wPartyMon1MaxHP - wPartyMon1HP
	add hl, de

	; [de:de+1] = [hl:hl+1]
	; 現在のHP = 最大HP としてHPを回復させる
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hl]
	ld [de], a

	pop de ; de = 現在処理中のポケモンのポインタ(wPartyMon${N}HP) (stack_depth = 1)
	pop hl ; hl = ??? (stack_depth = 0)

	push hl
	
	; de = 次に回復するポケモンのポインタ(wPartyMon${N}HP)
	ld bc, wPartyMon2 - wPartyMon1
	ld h, d
	ld l, e
	add hl, bc
	ld d, h
	ld e, l

	pop hl

	; 次のポケモンへ
	jr .healmon

.done
	; [wWhichPokemon] = [wd11e] = 0
	xor a
	ld [wWhichPokemon], a
	ld [wd11e], a

	; b = [wPartyCount]
	ld a, [wPartyCount]
	ld b, a
.ppup
	; .ppではPPアップで増やしたPPの分は回復されないのでここで回復させる

	push bc
	call RestoreBonusPP
	pop bc

	; [wWhichPokemon]++
	ld hl, wWhichPokemon
	inc [hl]

	; 次のポケモンのPPアップ分を回復させる
	dec b
	jr nz, .ppup

	ret
