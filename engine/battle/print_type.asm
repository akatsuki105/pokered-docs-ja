; **PrintMonType**  
; ポケモンのタイプを描画  
; - - -  
; [wd0b5] = 対象のポケモンID  
; hl = 描画先  
PrintMonType:
	call GetPredefRegisters
	push hl
	call GetMonHeader
	pop hl
	push hl
	ld a, [wMonHType1]
	call PrintType
	ld a, [wMonHType1]
	ld b, a
	ld a, [wMonHType2]
	cp b
	pop hl
	jr z, EraseType2Text
	ld bc, SCREEN_WIDTH * 2
	add hl, bc

; **PrintType**  
; ポケモンのタイプを描画  
; - - -  
; a = タイプ  
; hl = 描画先  
PrintType:
	push hl
	jr PrintType_

; erase "TYPE2/" if the mon only has 1 type
EraseType2Text:
	ld a, " "
	ld bc, $13
	add hl, bc
	ld bc, $6
	jp FillMemory

PrintMoveType:
	call GetPredefRegisters
	push hl
	ld a, [wPlayerMoveType]
; fall through

PrintType_:
	add a
	ld hl, TypeNames
	ld e, a
	ld d, $0
	add hl, de
	ld a, [hli]
	ld e, a
	ld d, [hl]
	pop hl
	jp PlaceString

INCLUDE "text/type_names.asm"
