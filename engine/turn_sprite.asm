; **UpdateSpriteFacingOffsetAndDelayMovement**  
; スプライトのイメージデータに現在の方向を反映し、クールタイムに入らせる
; - - -  
; INPUT: [H_CURRENTSPRITEOFFSET] = 処理対象のスプライトオフセット
UpdateSpriteFacingOffsetAndDelayMovement:
	; [$c2X8] = $7f (最長のクールタイム)
	ld h, $c2
	ld a, [H_CURRENTSPRITEOFFSET]
	add $8
	ld l, a
	ld a, $7f ; maximum movement delay
	ld [hl], a ; c2x8 (movement delay)

	; hl = スプライトの方向($c1X9)
	dec h
	ld a, [H_CURRENTSPRITEOFFSET]
	add $9
	ld l, a

	; b = スプライトの方向
	ld a, [hld] ; c1x9
	ld b, a

	; animation frameをリセット
	xor a
	ld [hld], a ; c1x8 (walk animation frame)
	ld [hl], a  ; c1x7 (intra walk animation frame)

	; hl = $c1x2 = スプライトのイメージ番号
	ld a, [H_CURRENTSPRITEOFFSET]
	add $2
	ld l, a

	; $c1x2(sprite image index)に方向を反映
	; [c1x2] = [c1x2] | [c1x9] (スプライトの方向)
	ld a, [hl] ; c1x2
	or b
	ld [hld], a

	; スプライトをクールタイム中に
	ld a, $2 ; delayed movement status
	ld [hl], a ; c1x1 (movement status)
	ret
