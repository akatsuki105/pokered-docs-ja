; **IsPlayerJustOutsideMap**  
; プレイヤーがマップの外側の1タイルにいるかどうかをZフラグにいれて返す  
; - - -  
; 建物から外にでるときに使う？  
; 
; OUTPUT:  
; z = 0(外側にいる) or 1(いない)  
IsPlayerJustOutsideMap:
	; a = [wCurMapHeight] (32*32単位のマップの高さ)
	; b = [wYCoord] (16*16単位のY座標)
	ld a, [wYCoord]
	ld b, a
	ld a, [wCurMapHeight]
	
	; マップの外側にいるか判定
	call .compareCoordWithMapDimension
	ret z

	; a = [wCurMapWidth] (32*32単位のマップの長さ)
	; b = [wXCoord] (16*16単位のX座標)
	ld a, [wXCoord]
	ld b, a
	ld a, [wCurMapWidth]

	; マップの外側にいるか判定
.compareCoordWithMapDimension
	; 現在の座標がマップの幅(縦 or 横)に等しい -> マップの1マス外側(黒い範囲)にいる
	add a ; a *= 2 (単位を合わせる)
	cp b
	ret z
	inc b ; zフラグをクリア
	ret
