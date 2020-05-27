_RemovePokemon:
	; 手持ちから逃がす -> hl = wPartyCount
	; PCBoxから逃がす -> hl = wNumInBox
	ld hl, wPartyCount
	ld a, [wRemoveMonFromBox]
	and a
	jr z, .asm_7b74
	ld hl, wNumInBox
.asm_7b74
	; hl(wPartyCount or wNumInBox)を1減らす
	ld a, [hl]
	dec a
	ld [hli], a

	; hl = 削除対象のlistのエントリ
	ld a, [wWhichPokemon]
	ld c, a
	ld b, $0
	add hl, bc

	; de = 削除対象のlistのエントリ+1(.asm_7b81の準備)
	ld e, l
	ld d, h
	inc de

	; 削除したポケモンのスロットが空くのでスロットしたのポケモンを上に1つずつずらす
.asm_7b81
	; 上にずらす
	ld a, [de]
	inc de
	ld [hli], a
	
	; 次の下のスロットへ
	inc a
	jr nz, .asm_7b81

	; 手持ちなら d = $5, hl = wPartyMonOT にして .asm_7b97へ
	; PCBoxなら d = $13, hl = wBoxMonOT にして .asm_7b97へ
	ld hl, wPartyMonOT
	ld d, $5
	ld a, [wRemoveMonFromBox]
	and a
	jr z, .asm_7b97
	ld hl, wBoxMonOT
	ld d, $13

.asm_7b97
	; hl = NAME_LENGTH*[wWhichPokemon] = 削除対象のポケモンの名前文字列のポインタ
	ld a, [wWhichPokemon]
	call SkipFixedLengthTextEntries

	; 最後のポケモンを選択していないなら -> .asm_7ba6
	ld a, [wWhichPokemon]
	cp d
	jr nz, .asm_7ba6

	; 最後のポケモンを選択しているならhlを$ffでクリアして終了(名前エントリをずらす必要がないので)
	ld [hl], $ff
	ret

.asm_7ba6
	; de = 削除対象のポケモンの名前文字列のポインタ
	ld d, h
	ld e, l
	; hl = 削除対象の次のポケモンの名前文字列のポインタ
	ld bc, NAME_LENGTH
	add hl, bc
	
	; bc = wPartyMonNicks(手持ち) or wBoxMonNicks(PCBox)
	ld bc, wPartyMonNicks
	ld a, [wRemoveMonFromBox]
	and a
	jr z, .asm_7bb8
	ld bc, wBoxMonNicks

.asm_7bb8
	call CopyDataUntil

	; (hl, bc) = (wPartyMons, wPartyMon2 - wPartyMon1) or (wBoxMons, wBoxMon2 - wBoxMon1) = (Pokemon Dataの配列, 配列の各エントリのサイズ)
	ld hl, wPartyMons
	ld bc, wPartyMon2 - wPartyMon1
	ld a, [wRemoveMonFromBox]
	and a
	jr z, .asm_7bcd
	ld hl, wBoxMons
	ld bc, wBoxMon2 - wBoxMon1

.asm_7bcd
	; de = 処理対象のPokemon Data
	ld a, [wWhichPokemon]
	call AddNTimes
	ld d, h
	ld e, l

	ld a, [wRemoveMonFromBox]
	and a
	jr z, .asm_7be4

	ld bc, wBoxMon2 - wBoxMon1
	add hl, bc
	ld bc, wBoxMonOT
	jr .asm_7beb
.asm_7be4
	ld bc, wPartyMon2 - wPartyMon1
	add hl, bc
	ld bc, wPartyMonOT
.asm_7beb
	call CopyDataUntil
	ld hl, wPartyMonNicks
	ld a, [wRemoveMonFromBox]
	and a
	jr z, .asm_7bfa
	ld hl, wBoxMonNicks
.asm_7bfa
	ld bc, NAME_LENGTH
	ld a, [wWhichPokemon]
	call AddNTimes
	ld d, h
	ld e, l
	ld bc, NAME_LENGTH
	add hl, bc
	ld bc, wPokedexOwned
	ld a, [wRemoveMonFromBox]
	and a
	jr z, .asm_7c15
	ld bc, wBoxMonNicksEnd
.asm_7c15
	jp CopyDataUntil
