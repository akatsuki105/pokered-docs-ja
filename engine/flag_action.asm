; **FlagActionPredef**  
; hlのビットフィールドのビットcにおいてアクションbを実行する  
; - - -  
; INPUT:  
; c = アクション b の対象が hl の何ビット目か  
; b = bitに対してとるアクション(0 -> クリア, 1 -> セット, 2 -> リード)  
; 
; OUTPUT: cレジスタ = アクションの結果(リードなら読み取ったbit)  
FlagActionPredef:
	call GetPredefRegisters

; **FlagAction**  
; hlのビットフィールドのビットcにおいてアクションbを実行する  
; - - -  
; INPUT:  
; c = アクション b の対象が hl の何ビット目か  
; b = bitに対してとるアクション(0 -> クリア, 1 -> セット, 2 -> リード)  
; 
; OUTPUT: cレジスタ = アクションの結果(リードなら読み取ったbit)  
FlagAction:
	; レジスタを退避
	push hl
	push de
	push bc

	; bit
	ld a, c
	ld d, a
	and 7
	ld e, a

	; byte
	ld a, d
	srl a
	srl a
	srl a
	add l
	ld l, a
	jr nc, .ok
	inc h
.ok

	; d = 1 << e (bitmask)
	inc e
	ld d, 1
.shift
	dec e
	jr z, .shifted
	sla d
	jr .shift
.shifted

	ld a, b
	and a
	jr z, .reset
	cp 2
	jr z, .read

.set
	ld b, [hl]
	ld a, d
	or b
	ld [hl], a
	jr .done

.reset
	ld b, [hl]
	ld a, d
	xor $ff
	and b
	ld [hl], a
	jr .done

.read
	ld b, [hl]
	ld a, d
	and b
.done
	; レジスタを復帰
	pop bc
	pop de
	pop hl
	; 結果を格納
	ld c, a
	ret
