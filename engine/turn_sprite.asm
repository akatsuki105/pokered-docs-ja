UpdateSpriteFacingOffsetAndDelayMovement:
	; hl = $c2X8
	ld h, $c2
	ld a, [H_CURRENTSPRITEOFFSET]
	add $8
	ld l, a
	; [$c2X8] = $7f (最長のクールタイム)
	ld a, $7f ; maximum movement delay
	ld [hl], a ; c2x8 (movement delay)

	; hl = $c1x9
	dec h
	ld a, [H_CURRENTSPRITEOFFSET]
	add $9
	ld l, a

	; b = 今スプライトが向いている方向
	ld a, [hld] ; c1x9 (facing direction)
	ld b, a

	; animation frameをリセット
	xor a
	ld [hld], a ; c1x8 (walk animation frame)
	ld [hl], a  ; c1x7 (intra walk animation frame)

	; hl = $c1x2
	ld a, [H_CURRENTSPRITEOFFSET]
	add $2
	ld l, a

	; TODO: スプライトの方向を$c1X9の方向に設定?
	ld a, [hl] ; c1x2 (facing and animation table offset)
	or b ; or in the facing direction
	ld [hld], a

	; スプライトをクールタイム中に
	ld a, $2 ; delayed movement status
	ld [hl], a ; c1x1 (movement status)
	ret
