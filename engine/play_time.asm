TrackPlayTime:
	call CountDownIgnoreInputBitReset
	ld a, [wd732]
	bit 0, a
	ret z
	ld a, [wPlayTimeMaxed]
	and a
	ret nz
	ld a, [wPlayTimeFrames]
	inc a
	ld [wPlayTimeFrames], a
	cp 60
	ret nz
	xor a
	ld [wPlayTimeFrames], a
	ld a, [wPlayTimeSeconds]
	inc a
	ld [wPlayTimeSeconds], a
	cp 60
	ret nz
	xor a
	ld [wPlayTimeSeconds], a
	ld a, [wPlayTimeMinutes]
	inc a
	ld [wPlayTimeMinutes], a
	cp 60
	ret nz
	xor a
	ld [wPlayTimeMinutes], a
	ld a, [wPlayTimeHours]
	inc a
	ld [wPlayTimeHours], a
	cp $ff
	ret nz
	ld a, $ff
	ld [wPlayTimeMaxed], a
	ret

CountDownIgnoreInputBitReset:

	; [wIgnoreInputCounter]をデクリメント
	ld a, [wIgnoreInputCounter]
	and a
	jr nz, .asm_18e40
	ld a, $ff
	jr .asm_18e41
.asm_18e40
	dec a
.asm_18e41
	ld [wIgnoreInputCounter], a
	and a
	ret nz

	; デクリメントの結果、[wIgnoreInputCounter]が0になった場合

	; wd730の1,2,5bitをクリア
	ld a, [wd730]
	res 1, a 		; wd730[1] = 0
	res 2, a		; wd730[2] = 0
	bit 5, a		; check wd730[5]
	res 5, a		; wd730[5] = 0
	ld [wd730], a
	ret z

	; wd730[5] = 1なら
	xor a
	ld [hJoyPressed], a
	ld [hJoyHeld], a
	ret
