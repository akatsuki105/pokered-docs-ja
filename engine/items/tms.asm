; **CanLearnTM**  
; ポケモンが技マシンの技を覚えられるかチェックする  
; - - -  
; INPUT:  
; [wcf91] = ポケモンID  
; [wMoveNum] = 対象の技のMoveID  
; 
; OUTPUT: cレジスタ = 1(覚えられる) or 0(覚えられない)
CanLearnTM:
	; 対象のPokemon Headerを取得
	ld a, [wcf91]
	ld [wd0b5], a
	call GetMonHeader

	ld hl, wMonHLearnset
	push hl

; c = 対象の技マシン番号
	ld a, [wMoveNum]
	ld b, a
	ld c, $0
	ld hl, TechnicalMachines
.findTMloop
	ld a, [hli]
	cp b
	jr z, .TMfoundLoop
	inc c
	jr .findTMloop

.TMfoundLoop
	pop hl
	ld b, FLAG_TEST
	predef_jump FlagActionPredef	; return

; converts TM/HM number in wd11e into move number
; HMs start at 51
TMToMove:
	ld a, [wd11e]
	dec a
	ld hl, TechnicalMachines
	ld b, $0
	ld c, a
	add hl, bc
	ld a, [hl]
	ld [wd11e], a
	ret

INCLUDE "data/tms.asm"
