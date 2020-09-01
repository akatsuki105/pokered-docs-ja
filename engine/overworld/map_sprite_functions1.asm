; **_UpdateSprites**  
_UpdateSprites:
	; a = $C20e
	ld h, $c1
	inc h		; h = $C2
	ld a, $e

; 各スプライトの更新処理
; $c2XeのXの値でどのスプライトを処理しているかわかる(0 <= X < 16)
.spriteLoop
; {
	; hl = $c2Xe = (wSpriteStateData2 + $Xe)
	ld l, a
	sub $e
	ld c, a
	; [H_CURRENTSPRITEOFFSET] = X0
	ld [H_CURRENTSPRITEOFFSET], a

	; $c2Xeが 0 ならこのスロットにスプライトはない -> .skipSprite
	ld a, [hl]
	and a
	jr z, .skipSprite

	; スプライトの更新処理
	push hl
	push de
	push bc
	call .updateCurrentSprite
	pop bc
	pop de
	pop hl

; スプライトの更新をスキップ
.skipSprite
	ld a, l
	add $10             ; 次のスプライトスロットを指すようにする

	; すべてのスプライトの更新処理が終わった -> return
	cp $e               
	jr nz, .spriteLoop	; すべてのスプライトの更新処理が終わればオーバーフローして$0eに戻っている
; }
	ret

; スプライトの更新処理
.updateCurrentSprite
	; 主人公は常にc2Xeが1
	cp $1
	jp nz, UpdateNonPlayerSprite
	jp UpdatePlayerSprite

; **UpdateNonPlayerSprite**
;  
; NPCスプライトの移動処理を行う関数  
; a: $c2Xe の値
UpdateNonPlayerSprite:
	; UpdateSpriteImageで利用するためにスプライト番号を$ff93に保存
	dec a
	swap a
	ld [hSpriteVRAMOffset], a  ; $10 * sprite#  = VRAMオフセット

	; 更新対象のスプライトが"Scripted NPC"かで更新処理を分岐
	ld a, [wNPCMovementScriptSpriteOffset]
	ld b, a
	ld a, [H_CURRENTSPRITEOFFSET]			 
	cp b
	jr nz, .unequal
	jp DoScriptedNPCMovement				; Scripted NPCのとき
.unequal
	jp UpdateNPCSprite

; **DetectCollisionBetweenSprites**  
; 現在処理中のスプライトが他のスプライトと衝突することになるかどうか他のスプライトを1つ1つ見ていくことで確認する  
; - - -  
; この関数内でのiとjについて
; 現在処理中のスプライトのオフセット(H_CURRENTSPRITEOFFSET)はiでラベル付けされる(e.g. $c1i0)  
; 1つ1つ確認しているスプライトのオフセットはj(e.g. $c1j0)  
;
; スプライトのY座標([$c1k4])はスプライトが grid にすっぽりおさまるように配置されているときには$fc, $0c, $1c, $2c, ... $7cのどれかの値になることに注意  
; Y座標から4を引くのは、比較を容易にするために、$10の倍数に合わせて調整するため  
DetectCollisionBetweenSprites:
	nop

	; hl = $c1i0
	ld h, wSpriteStateData1 / $100
	ld a, [H_CURRENTSPRITEOFFSET]
	add wSpriteStateData1 % $100
	ld l, a

	; 処理対象ののスプライトが有効でない -> return
	ld a, [hl] ; a = [$c1i0] (picture) (0 if slot is unused)
	and a
	ret z

	; hl = スプライトのY座標変化($c1i3)
	ld a, l
	add 3
	ld l, a

	ld a, [hli] ; a = [$c1i3] (delta Y) (-1, 0, or 1)
	call SetSpriteCollisionValues

	; a = スプライトのY座標
	ld a, [hli] ; a = [$C1i4] (Y screen coordinate)
	add 4 ; グリッドに合わせる

	; a に Y方向の移動を加味する (+7(下に移動) or -7(上に移動))
	add b
	and $f0
	or c

	ld [$ff90], a ; [$ff90] = 移動を加味したスプライトのY座標

	; 次はX方向
	ld a, [hli] ; a = [$c1i5] (delta X) (-1, 0, or 1)
	call SetSpriteCollisionValues
	ld a, [hl] ; a = [$C1i6] (X screen coordinate)

	; a に X方向の移動を加味する (+7(右に移動) or -7(左に移動))
	add b
	and $f0
	or c

	ld [$ff91], a ; [$ff91] = 移動を加味したスプライトのX座標

	; hl = $C1id
	ld a, l
	add 7
	ld l, a

	xor a
	ld [hld], a ; [$c1id] = 0
	ld [hld], a ; [$c1ic] = 0 (どの方向に移動した時にスプライトの衝突が起きたか)

	; [$c1id] = 移動を加味したスプライトのX座標 ([$ff91])
	ld a, [$ff91]
	ld [hld], a
	; [$c1ia] = 移動を加味したスプライトのY座標 ([$ff90])
	ld a, [$ff90]
	ld [hl], a

	xor a ; ループカウンタを0で初期化

; スプライトスロット(c1XX)の他のスプライトを1つ1つみていき、処理対象のスプライトと衝突が起きるスプライトがあるかチェックする
.loop
	ld [$ff8f], a ; store loop counter
	
	; みているスプライトが処理対象のスプライト -> 次のスプライトへ
	swap a
	ld e, a
	ld a, [H_CURRENTSPRITEOFFSET]
	cp e
	jp z, .next

	; みているスプライトが使われてないスプライト -> 次のスプライトへ
	ld d, h
	ld a, [de] ; a = [$c1j0] (picture) (0 if slot is unused)
	and a
	jp z, .next

	; みているスプライトが現在非表示のスプライト -> 次のスプライトへ
	inc e
	inc e
	ld a, [de] ; a = [$c1j2] ($ff means the sprite is offscreen)
	inc a
	jp z, .next

	ld a, [H_CURRENTSPRITEOFFSET]
	add 10
	ld l, a

	; delta Y -> pixel単位の座標変化
	inc e		; de = $c1j3
	ld a, [de]	; a = delta Y
	call SetSpriteCollisionValues

	; a = みているスプライトのY座標
	inc e
	ld a, [de] ; a = [$C1j4] (Y screen coordinate)
	add 4

	; みているスプライトのY座標にY方向の移動を加味する (+7(下に移動) or -7(上に移動))
	add b
	and $f0
	or c	; a = 移動を加味したみているスプライトのY座標

	sub [hl] ; a = みているスプライトのY座標 - 処理対象のスプライトのY座標($c1ia)

; $[ff90] = みているスプライトと処理対象のスプライトのY方向の距離
; carry = 1() or 0()
	jr nc, .noCarry1
	cpl
	inc a
.noCarry1
	ld [$ff90], a ; みているスプライトと処理対象のスプライトのY方向の距離(px単位)

; 上の引き算の処理で生じたcarryから みているスプライトと処理対象のスプライトのどちらのY座標が大きいかわかる  
; この情報は、衝突が起きる方向を格納する [$c1ic] の値を求めるために利用される  
; 
; 次の5行の処理は cレジスタ を 左に2シフトし、下位2bit を 10 or 01 にする  
; 処理対象のスプライトのほうがY座標が大きい、つまり下にいる -> 10
; みているスプラプトの方がY座標が大きいか同じ、つまり同じ場所か下にいる -> 01
	push af
	rl c
	pop af
	ccf
	rl c

	; b = 7(処理対象のスプライトの delta Y が 0) or 9(処理対象のスプライトの delta Y が 1 or -1)
	ld b, 7
	ld a, [hl] ; a = [$c1ia] (adjusted Y coordinate)
	and $f
	jr z, .next1
	ld b, 9

.next1
	ld a, [$ff90] ; a = distance between adjusted Y coordinates
	sub b
	ld [$ff92], a ; store distance adjusted using sprite i's direction
	ld a, b
	ld [$ff90], a ; store 7 or 9 depending on sprite i's delta Y
	jr c, .checkXDistance

; If sprite j's delta Y is 0, then b = 7, else b = 9.
	ld b, 7
	dec e
	ld a, [de] ; a = [$c1j3] (delta Y)
	inc e
	and a
	jr z, .next2
	ld b, 9

.next2
	ld a, [$ff92] ; a = distance adjusted using sprite i's direction
	sub b ; adjust distance using sprite j's direction
	jr z, .checkXDistance
	jr nc, .next ; go to next sprite if distance is still positive after both adjustments

.checkXDistance
	inc e
	inc l
	ld a, [de] ; a = [$c1j5] (delta X)

	push bc

	call SetSpriteCollisionValues
	inc e
	ld a, [de] ; a = [$c1j6] (X screen coordinate)

; The effect of the following 3 lines is to
; add 7 to a if moving east or
; subtract 7 from a if moving west.
	add b
	and $f0
	or c

	pop bc

	sub [hl] ; subtract the adjusted X coordinate of sprite i ([$c1ib]) from that of sprite j

; calculate the absolute value of the difference to get the distance
	jr nc, .noCarry2
	cpl
	inc a
.noCarry2
	ld [$ff91], a ; store the distance between the two sprites' adjusted X values

; Use the carry flag set by the above subtraction to determine which sprite's
; X coordinate is larger. This information is used later to set [$c1ic],
; which stores which direction the collision occurred in.
; The following 5 lines set the lowest 2 bits of c.
; If sprite i's X is larger, set lowest 2 bits of c to 10.
; If sprite j's X is larger or both are equal, set lowest 2 bits of c to 01.
	push af
	rl c
	pop af
	ccf
	rl c

; If sprite i's delta X is 0, then b = 7, else b = 9.
	ld b, 7
	ld a, [hl] ; a = [$c1ib] (adjusted X coordinate)
	and $f
	jr z, .next3
	ld b, 9

.next3
	ld a, [$ff91] ; a = distance between adjusted X coordinates
	sub b
	ld [$ff92], a ; store distance adjusted using sprite i's direction
	ld a, b
	ld [$ff91], a ; store 7 or 9 depending on sprite i's delta X
	jr c, .collision

; If sprite j's delta X is 0, then b = 7, else b = 9.
	ld b, 7
	dec e
	ld a, [de] ; a = [$c1j5] (delta X)
	inc e
	and a
	jr z, .next4
	ld b, 9

.next4
	ld a, [$ff92] ; a = distance adjusted using sprite i's direction
	sub b ; adjust distance using sprite j's direction
	jr z, .collision
	jr nc, .next ; go to next sprite if distance is still positive after both adjustments

.collision
	ld a, [$ff91] ; a = 7 or 9 depending on sprite i's delta X
	ld b, a
	ld a, [$ff90] ; a = 7 or 9 depending on sprite i's delta Y
	inc l

; If delta X isn't 0 and delta Y is 0, then b = %0011, else b = %1100.
; (note that normally if delta X isn't 0, then delta Y must be 0 and vice versa)
	cp b
	jr c, .next5
	ld b, %1100
	jr .next6
.next5
	ld b, %0011

.next6
	ld a, c ; c has 2 bits set (one of bits 0-1 is set for the X axis and one of bits 2-3 for the Y axis)
	and b ; we select either the bit in bits 0-1 or bits 2-3 based on the calculation immediately above
	or [hl] ; or with existing collision direction bits in [$c1ic]
	ld [hl], a ; store new value
	ld a, c ; useless code because a is overwritten before being used again

; set bit in [$c1ie] or [$c1if] to indicate which sprite the collision occurred with
	inc l
	inc l
	ld a, [$ff8f] ; a = loop counter
	ld de, SpriteCollisionBitTable
	add a
	add e
	ld e, a
	jr nc, .noCarry3
	inc d
.noCarry3
	ld a, [de]
	or [hl]
	ld [hli], a
	inc de
	ld a, [de]
	or [hl]
	ld [hl], a

.next
	ld a, [$ff8f] ; a = loop counter
	inc a
	cp $10
	jp nz, .loop
	ret

; **SetSpriteCollisionValues**  
; aレジスタの XかY の座標変化量(delta)を見て bとc に値を格納
; 
; INPUT: a = XかY の座標変化量(delta)
; 
; OUTPUT:  
; b = delta  
; c = 0 if (delta == 0)  
; c = 7 if (delta == 1)  
; c = 9 if (delta == -1)  
SetSpriteCollisionValues:
	; delta が0
	and a
	ld b, 0
	ld c, 0
	jr z, .done ; aが0なら.done
	; delta が-1
	ld c, 9
	cp -1
	jr z, .ok
	; delta が1
	ld c, 7
	ld a, 0
.ok
	ld b, a
.done
	ret

SpriteCollisionBitTable:
	db %00000000,%00000001
	db %00000000,%00000010
	db %00000000,%00000100
	db %00000000,%00001000
	db %00000000,%00010000
	db %00000000,%00100000
	db %00000000,%01000000
	db %00000000,%10000000
	db %00000001,%00000000
	db %00000010,%00000000
	db %00000100,%00000000
	db %00001000,%00000000
	db %00010000,%00000000
	db %00100000,%00000000
	db %01000000,%00000000
	db %10000000,%00000000
