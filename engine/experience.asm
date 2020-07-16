; **CalcLevelFromExperience**  
; 現在の経験値に基づいたポケモンのレベルを計算する  
CalcLevelFromExperience:
	ld a, [wLoadedMonSpecies]
	ld [wd0b5], a
	call GetMonHeader
	ld d, $1 ; init level to 1
.loop
	inc d ; increment level
	call CalcExperience
	push hl
	ld hl, wLoadedMonExp + 2 ; current exp
; compare exp needed for level d with current exp
	ld a, [hExperience + 2]
	ld c, a
	ld a, [hld]
	sub c
	ld a, [hExperience + 1]
	ld c, a
	ld a, [hld]
	sbc c
	ld a, [hExperience]
	ld c, a
	ld a, [hl]
	sbc c
	pop hl
	jr nc, .loop ; if exp needed for level d is not greater than exp, try the next level
	dec d ; since the exp was too high on the last loop iteration, go back to the previous value and return
	ret

; **CalcExperience**  
; Dレジスタで指定したレベルになるのに必要な経験値の合計を計算する  
; 
; OUTPUT: [hExperience] = 経験値量
CalcExperience:
	ld a, [wMonHGrowthRate] ; Pokemon Headerの経験値パターン
	add a
	add a
	ld c, a
	ld b, 0	; bc = 3 * [wMonHGrowthRate]
	ld hl, GrowthRateTable
	add hl, bc
	call CalcDSquared
	ld a, d
	ld [H_MULTIPLIER], a
	call Multiply
	ld a, [hl]
	and $f0
	swap a
	ld [H_MULTIPLIER], a
	call Multiply
	ld a, [hli]
	and $f
	ld [H_DIVISOR], a
	ld b, $4
	call Divide
	ld a, [H_QUOTIENT + 1]
	push af
	ld a, [H_QUOTIENT + 2]
	push af
	ld a, [H_QUOTIENT + 3]
	push af
	call CalcDSquared
	ld a, [hl]
	and $7f
	ld [H_MULTIPLIER], a
	call Multiply
	ld a, [H_PRODUCT + 1]
	push af
	ld a, [H_PRODUCT + 2]
	push af
	ld a, [H_PRODUCT + 3]
	push af
	ld a, [hli]
	push af
	xor a
	ld [H_MULTIPLICAND], a
	ld [H_MULTIPLICAND + 1], a
	ld a, d
	ld [H_MULTIPLICAND + 2], a
	ld a, [hli]
	ld [H_MULTIPLIER], a
	call Multiply
	ld b, [hl]
	ld a, [H_PRODUCT + 3]
	sub b
	ld [H_PRODUCT + 3], a
	ld b, $0
	ld a, [H_PRODUCT + 2]
	sbc b
	ld [H_PRODUCT + 2], a
	ld a, [H_PRODUCT + 1]
	sbc b
	ld [H_PRODUCT + 1], a
; The difference of the linear term and the constant term consists of 3 bytes
; starting at H_PRODUCT + 1. Below, hExperience (an alias of that address) will
; be used instead for the further work of adding or subtracting the squared
; term and adding the cubed term.
	pop af
	and $80
	jr nz, .subtractSquaredTerm ; check sign
	pop bc
	ld a, [hExperience + 2]
	add b
	ld [hExperience + 2], a
	pop bc
	ld a, [hExperience + 1]
	adc b
	ld [hExperience + 1], a
	pop bc
	ld a, [hExperience]
	adc b
	ld [hExperience], a
	jr .addCubedTerm
.subtractSquaredTerm
	pop bc
	ld a, [hExperience + 2]
	sub b
	ld [hExperience + 2], a
	pop bc
	ld a, [hExperience + 1]
	sbc b
	ld [hExperience + 1], a
	pop bc
	ld a, [hExperience]
	sbc b
	ld [hExperience], a
.addCubedTerm
	pop bc
	ld a, [hExperience + 2]
	add b
	ld [hExperience + 2], a
	pop bc
	ld a, [hExperience + 1]
	adc b
	ld [hExperience + 1], a
	pop bc
	ld a, [hExperience]
	adc b
	ld [hExperience], a
	ret

; [FF95-FF98] = (Dレジスタ)*(Dレジスタ) (ビッグエンディアン)
CalcDSquared:
	xor a
	ld [H_MULTIPLICAND], a
	ld [H_MULTIPLICAND + 1], a
	ld a, d
	ld [H_MULTIPLICAND + 2], a
	ld [H_MULTIPLIER], a
	jp Multiply

; **GrowthRateTable**  
; ポケモンの経験値タイプを定義したテーブル  
; - - -  
; 各エントリ(4バイト)は次のフォーマットで表される
; 
; ```
; ; %AAAABBBB %SCCCCCCC %DDDDDDDD %EEEEEEEE
; (A*Lv^3)/B + (-S)*C*Lv^2 + D*Lv - E
; ```
GrowthRateTable:
	db $11,$00,$00,$00 ; 1000000:      	n^3
	db $34,$0A,$00,$1E ; (unused?)    	3/4 n^3 + 10 n^2         - 30
	db $34,$14,$00,$46 ; (unused?)    	3/4 n^3 + 20 n^2         - 70
	db $65,$8F,$64,$8C ; 1050000: 		6/5 n^3 - 15 n^2 + 100 n - 140
	db $45,$00,$00,$00 ; 800000:        4/5 n^3
	db $54,$00,$00,$00 ; 1250000:       5/4 n^3
