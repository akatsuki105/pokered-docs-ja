; **LoadWildData**  
; 現在のマップの野生ポケモンのエンカウントデータを ROM から WRAM にロード
; - - -  
; `wGrassRate`, `wGrassMons` に地上でのエンカウント率と出現するポケモンデータ  
; `wWaterRate`, `wWaterMons` に水上でのエンカウント率と出現するポケモンデータ  
; がロードされる  
LoadWildData:
	; hl = WildDataPointers の現在のマップのエントリ = 野生ポケモンテーブルのアドレス を指しているアドレス
	ld hl, WildDataPointers
	ld a, [wCurMap]
	ld c, a
	ld b, 0
	add hl, bc
	add hl, bc

	; hl = 野生ポケモンテーブル の先頭のアドレス
	ld a, [hli]
	ld h, [hl]
	ld l, a

	; [wGrassRate] に地上でのエンカウント率を格納し、 0、つまり地上に野生のポケモンがいないなら -> .NoGrassData
	ld a, [hli]
	ld [wGrassRate], a
	and a
	jr z, .NoGrassData
	
	push hl ; hl = 野生ポケモン1匹目のアドレス(全部で10匹)
	
	; wGrassMons に 野生ポケモンテーブルのデータをロード
	ld de, wGrassMons
	ld bc, $0014
	call CopyData
	pop hl
	ld bc, $0014
	add hl, bc ; hl = 水上でのエンカウント率

.NoGrassData
	; [wWaterRate] に水上でのエンカウント率を格納し、 0、つまり水上に野生のポケモンがいないなら -> return 
	ld a, [hli]
	ld [wWaterRate], a
	and a
	ret z        ; if no water data, we're done

	; wWaterMons に 水上の野生ポケモンテーブルのデータをロード
	ld de, wWaterMons  ; otherwise, load surfing data
	ld bc, $0014
	jp CopyData

INCLUDE "data/wild_mons.asm"
