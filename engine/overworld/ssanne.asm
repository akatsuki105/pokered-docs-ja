; **AnimateBoulderDust**  
; かいりき の土埃のアニメーション処理  
; - - -  
; サントアンヌ号の出航の際の煙のアニメーション処理も行っている?  
AnimateBoulderDust:
	; かいりきの土埃 (WriteCutOrBoulderDustAnimationOAMBlock で使用)
	ld a, $1
	ld [wWhichAnimationOffsets], a ; select the boulder dust offsets

	; スプライト表示を無効化
	ld a, [wUpdateSpritesEnabled]
	push af
	ld a, $ff
	ld [wUpdateSpritesEnabled], a

	; OBP1パレットを設定
	ld a, %11100100
	ld [rOBP1], a

	call LoadSmokeTileFourTimes
	callba WriteCutOrBoulderDustAnimationOAMBlock

; .loopで 土煙のアニメーション を流す
	ld c, 8	; アニメーションは8ステップにわけて行う
.loop
; {
	push bc	; c を退避
	call GetMoveBoulderDustFunctionPointer

	; 実質　以下3行と同じ
	; ld c, 4
	; call (AdjustOAMBlockXPos or AdjustOAMBlockYPos)
	; jp .returnAddress
	ld bc, .returnAddress
	push bc
	ld c, 4
	jp hl

.returnAddress
	; パレットを修正
	ld a, [rOBP1]
	xor %01100100
	ld [rOBP1], a
	call Delay3

	pop bc	; c を復帰
	dec c
	jr nz, .loop
; }

	; [wUpdateSpritesEnabled] を復帰
	pop af	
	ld [wUpdateSpritesEnabled], a
	jp LoadPlayerSpriteGraphics	; return

; **GetMoveBoulderDustFunctionPointer**  
; プレイヤーの方向に応じて、de, hlにアドレスを格納  
; - - -  
; OUTPUT:  
; プレイヤーの方向が上 de = wOAMBuffer + $90(OAM Y), hl = AdjustOAMBlockYPos, [wCoordAdjustmentAmount] = +1  
; プレイヤーの方向が下 de = wOAMBuffer + $90(OAM Y), hl = AdjustOAMBlockYPos, [wCoordAdjustmentAmount] = -1  
; プレイヤーの方向が右 de = wOAMBuffer + $91(OAM X), hl = AdjustOAMBlockXPos, [wCoordAdjustmentAmount] = -1  
; プレイヤーの方向が左 de = wOAMBuffer + $91(OAM X), hl = AdjustOAMBlockXPos, [wCoordAdjustmentAmount] = +1  
GetMoveBoulderDustFunctionPointer:
	; hl = MoveBoulderDustFunctionPointerTable のエントリ(プレイヤーの向いている方向による)
	ld a, [wSpriteStateData1 + 9] 				; プレイヤーの方向
	ld hl, MoveBoulderDustFunctionPointerTable
	ld c, a
	ld b, $0
	add hl, bc

	; [wCoordAdjustmentAmount] = $FF(下右) or $01(上左)
	ld a, [hli]
	ld [wCoordAdjustmentAmount], a
	; e = $00(上下) or $01(右左)
	ld a, [hli]
	ld e, a

	; hl = AdjustOAMBlockXPos (or AdjustOAMBlockYPos)
	ld a, [hli]
	ld h, [hl]
	ld l, a
	push hl

	; de = wOAMBuffer + $90(上下) or wOAMBuffer + $91(右左)
	ld hl, wOAMBuffer + $90
	ld d, $0
	add hl, de
	ld e, l
	ld d, h

	pop hl	; hl = AdjustOAMBlockXPos (or AdjustOAMBlockYPos)
	ret

MoveBoulderDustFunctionPointerTable:
	; facing down
	db $FF,$00
	dw AdjustOAMBlockYPos

	; facing up
	db $01,$00
	dw AdjustOAMBlockYPos

	; facing left
	db $01,$01
	dw AdjustOAMBlockXPos

	; facing right
	db $FF,$01
	dw AdjustOAMBlockXPos

; VRAM (0x8800+0x07c0 ~) に かいりきの土埃のタイルを4枚ロードする
LoadSmokeTileFourTimes:
	ld hl, vChars1 + $7c0
	ld c, $4
.loop
; {
	push bc
	push hl
	call LoadSmokeTile
	pop hl
	ld bc, $10
	add hl, bc
	pop bc
	dec c
	jr nz, .loop
; }
	ret

; hl に かいりきの土埃のタイルをコピーする
LoadSmokeTile:
	ld de, SSAnneSmokePuffTile
	lb bc, BANK(SSAnneSmokePuffTile), (SSAnneSmokePuffTileEnd - SSAnneSmokePuffTile) / $10
	jp CopyVideoData

SSAnneSmokePuffTile:
	INCBIN "gfx/ss_anne_smoke_puff.2bpp"
SSAnneSmokePuffTileEnd:
