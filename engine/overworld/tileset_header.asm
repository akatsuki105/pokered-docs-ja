; **LoadTilesetHeader**  
; タイルセットを新しいタイルセットにする  
; - - -  
; メモリ上のtileset header値を更新する  
; マップをワープするときに呼び出される  
; INPUT: hl = ???  
LoadTilesetHeader:
	call GetPredefRegisters
	push hl ; stack_depth = 0

	; de = [wCurMapTileset] * 12 = タイルセットオフセット * 12
	ld d, 0
	ld a, [wCurMapTileset]
	add a
	add a
	ld b, a
	add a
	add b ; a = tilesetのオフセット * 12 = Tilesetsのエントリサイズ + 1
	jr nc, .noCarry
	inc d
.noCarry
	ld e, a

	; hl = Tilesets のエントリ のポインタ
	ld hl, Tilesets
	add hl, de

	; wTilesetBank以下 に Tilesetsエントリ(tilesetのバンク番号 + tileset header) をコピーする
	ld de, wTilesetBank
	ld c, $b ; 11 = tileset headerのサイズ
.copyTilesetHeaderLoop
	ld a, [hli]
	ld [de], a
	inc de		; [de++] = [hl++]
	dec c
	jr nz, .copyTilesetHeaderLoop

	; [hTilesetType] = tileset headerから取得したtilesetType
	ld a, [hl]
	ld [hTilesetType], a

	; [$ffd8] = [hMovingBGTilesCounter1] = 0
	xor a
	ld [$ffd8], a

	pop hl ; stack_depth = 0
	
	ld a, [wCurMapTileset]

	; タイルセットがダンジョンとして使われるタイルセットであるか判定
	push hl ; stack_depth = 0
	push de ; stack_depth = 1
	ld hl, DungeonTilesets
	ld de, $1
	call IsInArray
	pop de	; stack_depth = 1
	pop hl	; stack_depth = 0

	; ダンジョンとして使われるタイルセット -> .asm_c797
	jr c, .asm_c797

	; ダンジョンとして使われることがないタイルセット

	; タイルセットが前のマップと同じタイルセット -> .done
	ld a, [wCurMapTileset]
	ld b, a
	ld a, [hPreviousTileset]
	cp b
	jr z, .done

.asm_c797
	; [wDestinationWarpID] == $ff -> .done
	ld a, [wDestinationWarpID]
	cp $ff
	jr z, .done
	
	; このとき
	; a = warp先のwarp-to ID, hl = ???
	call LoadDestinationWarpPosition

	; warpによってwXCoord, wYCoordが変更されるのでwXBlockCoord, wYBlockCoordにも反映
	ld a, [wYCoord]
	and $1
	ld [wYBlockCoord], a
	ld a, [wXCoord]
	and $1
	ld [wXBlockCoord], a
.done
	ret

INCLUDE "data/dungeon_tilesets.asm"

INCLUDE "data/tileset_headers.asm"
