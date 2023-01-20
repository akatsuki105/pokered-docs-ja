; 16bitの乱数を生成する
Random_::
	; [hRandomAdd] += DIVレジスタ
	ld a, [rDIV]
	ld b, a
	ld a, [hRandomAdd]
	adc b
	ld [hRandomAdd], a

	; [hRandomSub] -= DIVレジスタ
	ld a, [rDIV]
	ld b, a
	ld a, [hRandomSub]
	sbc b
	ld [hRandomSub], a
	ret
