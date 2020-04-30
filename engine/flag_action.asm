FlagActionPredef:
	call GetPredefRegisters

; hlのビットフィールドのビットcにおいてアクションbを実行する
; 
; アクションb
; - 0: cビットをクリア
; - 1: cビットをセット
; - 2: cビットをリード
; 
; cレジスタに結果を入れて返す
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
