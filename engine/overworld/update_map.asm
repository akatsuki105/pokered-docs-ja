; **ReplaceTileBlock**  
; 1つのタイルブロックを [wNewTileBlockID] で指定したものに置き換えて、必要があればマップを再描画する  
; - - -  
; タイルブロック = 32*32pxのブロック  
; INPUT:  
; - b = Y(画面上ではなくマップ全体のY座標)
; - c = X
; - [wNewTileBlockID] = 新たなブロックID
ReplaceTileBlock:
	call GetPredefRegisters
	ld hl, wOverworldMap

	; de = [wCurMapWidth] + $6 = 画面の横幅(タイルブロック単位)
	ld a, [wCurMapWidth]
	add $6
	ld e, a
	ld d, $0

	; hl = wOverworldMap + 3de + 3
	add hl, de
	add hl, de
	add hl, de
	ld e, $3
	add hl, de

	; e = 画面の横幅(タイルブロック単位)
	ld e, a

	; Y == 0 -> .addX
	ld a, b
	and a
	jr z, .addX

	; hl += width * Y
.addWidthYTimesLoop
	add hl, de
	dec b
	jr nz, .addWidthYTimesLoop

.addX
	add hl, bc ; hl += X (この時点でYは0なので)

	; [hl] = [wNewTileBlockID]
	ld a, [wNewTileBlockID]
	ld [hl], a

	; bc = [wCurrentTileBlockMapViewPointer]
	ld a, [wCurrentTileBlockMapViewPointer]
	ld c, a
	ld a, [wCurrentTileBlockMapViewPointer + 1]
	ld b, a

	; hl(対象のXY座標のポインタ) - bc(画面左上のポインタ) < 0 つまり 対象が画面外 なら終了
	call CompareHLWithBC
	ret c ; hl < bc -> return

	push hl ; hl = 対象のXY座標のポインタ

	; hl = 画面の横幅(タイルブロック単位)
	ld l, e
	ld h, $0
	; de = $06
	ld e, $6
	ld d, h
	
	; hl = 画面の横幅(タイルブロック単位)*3 + 6 + [wCurrentTileBlockMapViewPointer]
	add hl, hl
	add hl, hl
	add hl, de
	add hl, bc

	; hl(対象のXY座標のポインタ) - bc(画面右下?のポインタ) < 0 つまり 対象が画面外 なら終了?
	; そうでないなら RedrawMapView に突入
	pop bc	; bc = 対象のXY座標のポインタ
	call CompareHLWithBC
	ret c 	; bc > hl -> return

RedrawMapView:
	; wIsInBattle == -1 -> return
	ld a, [wIsInBattle]
	inc a
	ret z

	; [H_AUTOBGTRANSFERENABLED] と [hTilesetType] を退避
	ld a, [H_AUTOBGTRANSFERENABLED]
	push af
	ld a, [hTilesetType]
	push af

	; [H_AUTOBGTRANSFERENABLED] = 0
	; [hTilesetType] = 0 (アニメーションを無効化)
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a
	ld [hTilesetType], a

	call LoadCurrentMapView
	call RunDefaultPaletteCommand

	; hl = [wMapViewVRAMPointer]
	ld hl, wMapViewVRAMPointer
	inline "hl = [hl]"
	
	; hl = 
	ld de, -2 * 32
	add hl, de

	; h = $98XX
	ld a, h
	and $3	; %0000 0011
	or $98	; %1001 1000

	; [wBuffer:wBuffer + 1] = hl 特に意味はない模様
	ld a, l
	ld [wBuffer], a
	ld a, h
	ld [wBuffer + 1], a

	; [$ffbe] = 2
	ld a, 2
	ld [$ffbe], a

	ld c, 9 ; 1行 = 2*2タイル = 16*16pxとしたとき 9行分ループする
.redrawRowLoop
	push bc
	push hl
	push hl
	ld hl, wTileMap - 2 * SCREEN_WIDTH
	ld de, SCREEN_WIDTH
	ld a, [$ffbe]
.calcWRAMAddrLoop
	add hl, de
	dec a
	jr nz, .calcWRAMAddrLoop
	call CopyToRedrawRowOrColumnSrcTiles
	pop hl
	ld de, $20
	ld a, [$ffbe]
	ld c, a
.calcVRAMAddrLoop
	add hl, de
	ld a, h
	and $3
	or $98
	dec c
	jr nz, .calcVRAMAddrLoop
	ld [hRedrawRowOrColumnDest + 1], a
	ld a, l
	ld [hRedrawRowOrColumnDest], a
	ld a, REDRAW_ROW
	ld [hRedrawRowOrColumnMode], a
	call DelayFrame
	ld hl, $ffbe
	inc [hl]
	inc [hl]
	pop hl
	pop bc
	dec c
	jr nz, .redrawRowLoop
	pop af
	ld [hTilesetType], a
	pop af
	ld [H_AUTOBGTRANSFERENABLED], a
	ret

; hl-bc  
; hlもbcも不変  
CompareHLWithBC:
	ld a, h
	sub b
	ret nz
	ld a, l
	sub c
	ret
