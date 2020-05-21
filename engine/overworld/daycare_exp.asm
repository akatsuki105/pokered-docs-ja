; **IncrementDayCareMonExp**  
; - - -  
; 育て屋のポケモンの経験値をインクリメントする処理
IncrementDayCareMonExp:
	; 育て屋にポケモンがいないなら何もしない
	ld a, [wDayCareInUse]
	and a
	ret z

	; 3バイト目をインクリメント
	ld hl, wDayCareMonExp + 2
	inc [hl]
	ret nz

	; 3バイト目がオーバーフローしたら2バイト目をインクリメント
	dec hl
	inc [hl]
	ret nz

	; 2バイト目がオーバーフローしたら1バイト目をインクリメント
	dec hl
	inc [hl]

	; [hl] < $50
	ld a, [hl]
	cp $50
	ret c

	; [hl] >= $50 なら [hl]を$50に保つ
	ld a, $50
	ld [hl], a
	ret
