; **ReplaceTileBlock**  
; 1つのタイルブロックを [wNewTileBlockID] で指定したものに置き換えて、必要があればマップを再描画する  
; - - -  
; タイルブロック = 32*32pxのブロック  
; INPUT:  
; - b = Y
; - c = X
; - [wNewTileBlockID] = 新たなタイルブロックID
ReplaceTileBlock:
	call GetPredefRegisters
	ld hl, wOverworldMap

	; de = [wCurMapWidth] + $6
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

	; e = $3
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
	add hl, bc ; add X
	ld a, [wNewTileBlockID]
	ld [hl], a
	ld a, [wCurrentTileBlockMapViewPointer]
	ld c, a
	ld a, [wCurrentTileBlockMapViewPointer + 1]
	ld b, a
	call CompareHLWithBC
	ret c ; return if the replaced tile block is below the map view in memory
	push hl
	ld l, e
	ld h, $0
	ld e, $6
	ld d, h
	add hl, hl
	add hl, hl
	add hl, de
	add hl, bc
	pop bc
	call CompareHLWithBC
	ret c ; return if the replaced tile block is above the map view in memory

RedrawMapView:
	ld a, [wIsInBattle]
	inc a
	ret z
	ld a, [H_AUTOBGTRANSFERENABLED]
	push af
	ld a, [hTilesetType]
	push af
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a
	ld [hTilesetType], a ; no flower/water BG tile animations
	call LoadCurrentMapView
	call RunDefaultPaletteCommand
	ld hl, wMapViewVRAMPointer
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld de, -2 * 32
	add hl, de
	ld a, h
	and $3
	or $98
	ld a, l
	ld [wBuffer], a
	ld a, h
	ld [wBuffer + 1], a ; this copy of the address is not used
	ld a, 2
	ld [$ffbe], a
	ld c, 9 ; number of rows of 2x2 tiles (this covers the whole screen)
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

CompareHLWithBC:
	ld a, h
	sub b
	ret nz
	ld a, l
	sub c
	ret
