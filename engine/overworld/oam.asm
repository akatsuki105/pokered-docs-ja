; Determine OAM data for currently visible
; sprites and write it to wOAMBuffer.
PrepareOAMData:
	ld a, [wUpdateSpritesEnabled]	; a = [wUpdateSpritesEnabled] - 1

	; [wUpdateSpritesEnabled] - 1 == 0 つまり スプライトが有効 -> .updateEnabled
	dec a
	jr z, .updateEnabled
	; [wUpdateSpritesEnabled] - 1 != 0xff つまり [wUpdateSpritesEnabled] == 0xff -> return
	cp -1
	ret nz

	; [wUpdateSpritesEnabled] == 0 のとき
	ld [wUpdateSpritesEnabled], a ; [wUpdateSpritesEnabled] = 0xff
	jp HideSprites ; OAM を全部非表示にして return

.updateEnabled
	xor a
	ld [hOAMBufferOffset], a		; [hOAMBufferOffset] = 0

.spriteLoop
	ld [hSpriteOffset2], a

	; a = [0xc1X0], de = 0xc1X0
	ld d, wSpriteStateData1 / $100	; d = 0xc1
	ld a, [hSpriteOffset2]			; e = 0xX0
	ld e, a
	ld a, [de] 						; a = [0xc1X0] = picture ID

	; picture ID == 0 -> .nextSprite
	and a
	jp z, .nextSprite

	; a = [0xc1X2]
	; de = 0xc1X2(facing/anim)
	; [wd5cd] = [0xc1X2]
	inc e
	inc e
	ld a, [de]
	ld [wd5cd], a

	; [0xc1X2] != 0xff つまり スプライトを表示するとき -> .visible
	cp $ff
	jr nz, .visible

	; スプライトを表示しない時
	call GetSpriteScreenXY
	jr .nextSprite

.visible
	; この時点で a = [0xc1X2]
	cp $a0 ; is the sprite unchanging like an item ball or boulder?
	jr c, .usefacing

; unchanging
; 対象のスプライトが、アイテムや 『かいりき』の岩のように 『顔』 を持たない場合
	and $f
	add $10 ; アイテム(モンボアイコン)や岩は方向を持たないので 方向を表す後半のテーブル(c1X2の下位ニブルのこと)はスキップする
	jr .next

.usefacing
; 対象のスプライトが、人など 『顔』　を持っている場合
	and $f	; and 0b0000XXXX

; この時点で  
; a = スプライトの方向 0x00 or 0x04 or 0x08 or 0x0c  
; de = 0xc1X2
.next
	ld l, a

; [hSpritePriority] = [c2x7] (0x80(スプライトが草むらの上) or 0x00(それ以外))
	push de
	inc d
	ld a, e
	add $5
	ld e, a		; de = c2x7
	ld a, [de] 	; a = sprite priority
	and $80		; 0b_1000_0000
	ld [hSpritePriority], a ; temp store sprite priority
	pop de

; read the entry from the table
	ld h, 0
	ld bc, SpriteFacingAndAnimationTable
	add hl, hl
	add hl, hl
	add hl, bc
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld b, a
	ld a, [hli]
	ld h, [hl]
	ld l, a

	call GetSpriteScreenXY

	ld a, [hOAMBufferOffset]
	ld e, a
	ld d, wOAMBuffer / $100

.tileLoop
	ld a, [hSpriteScreenY]   ; temp for sprite Y position
	add $10                  ; Y=16 is top of screen (Y=0 is invisible)
	add [hl]                 ; add Y offset from table
	ld [de], a               ; write new sprite OAM Y position
	inc hl
	ld a, [hSpriteScreenX]   ; temp for sprite X position
	add $8                   ; X=8 is left of screen (X=0 is invisible)
	add [hl]                 ; add X offset from table
	inc e
	ld [de], a               ; write new sprite OAM X position
	inc e
	ld a, [bc]               ; read pattern number offset (accommodates orientation (offset 0,4 or 8) and animation (offset 0 or $80))
	inc bc
	push bc
	ld b, a

	ld a, [wd5cd]            ; temp copy of c1x2
	swap a                   ; high nybble determines sprite used (0 is always player sprite, next are some npcs)
	and $f

	; Sprites $a and $b have one face (and therefore 4 tiles instead of 12).
	; As a result, sprite $b's tile offset is less than normal.
	cp $b
	jr nz, .notFourTileSprite
	ld a, $a * 12 + 4
	jr .next2

.notFourTileSprite
	; a *= 12
	sla a
	sla a
	ld c, a
	sla a
	add c

.next2
	add b ; add the tile offset from the table (based on frame and facing direction)
	pop bc
	ld [de], a ; tile id
	inc hl
	inc e
	ld a, [hl]
	bit 1, a ; is the tile allowed to set the sprite priority bit?
	jr z, .skipPriority
	ld a, [hSpritePriority]
	or [hl]
.skipPriority
	inc hl
	ld [de], a
	inc e
	bit 0, a ; OAMFLAG_ENDOFDATA
	jr z, .tileLoop

	ld a, e
	ld [hOAMBufferOffset], a

.nextSprite
	ld a, [hSpriteOffset2]
	add $10
	cp $100 % $100
	jp nz, .spriteLoop

	; Clear unused OAM.
	ld a, [hOAMBufferOffset]
	ld l, a
	ld h, wOAMBuffer / $100
	ld de, $4
	ld b, $a0
	ld a, [wd736]
	bit 6, a ; jumping down ledge or fishing animation?
	ld a, $a0
	jr z, .clear

; Don't clear the last 4 entries because they are used for the shadow in the
; jumping down ledge animation and the rod in the fishing animation.
	ld a, $90

.clear
	cp l
	ret z
	ld [hl], b
	add hl, de
	jr .clear

; **GetSpriteScreenXY**  
; OAMの (16*16px) のグリッド単位での XY座標 を計算する
; - - -  
; wSpriteStateData1 参照
; 
; INPUT:  
; de = 0xc1X2
; 
; OUTPUT:  
; [0xc1Xa], [0xc1Xb] = 計算された Y, X座標
GetSpriteScreenXY:

	; [hSpriteScreenY] = [0xc1X4]
	inc e
	inc e
	ld a, [de] ; c1x4
	ld [hSpriteScreenY], a

	; [hSpriteScreenX] = [0xc1X6]
	inc e
	inc e
	ld a, [de] ; c1x6
	ld [hSpriteScreenX], a

	; de = 0xc1Xa
	ld a, 4
	add e
	ld e, a

	; [0xc1Xa] = OAMの (16*16px) のグリッド単位での Y座標
	ld a, [hSpriteScreenY]
	add 4
	and $f0	; and 0b11110000 つまり a /= 16
	ld [de], a ; c1xa (y)

	; [0xc1Xb] = OAMの (16*16px) のグリッド単位での X座標
	inc e
	ld a, [hSpriteScreenX]
	and $f0
	ld [de], a  ; c1xb (x)

	ret
