; **IsPlayerOnDungeonWarp**  
; プレイヤーがdungeon warpするマスにいるかどうか  
; - - - 
; INPUT:  
; - hl = dungeon mapのcoordsのリスト  
; 
; OUTPUT:  
; - [wWhichDungeonWarp] = 現在利用しているdungeon warpのcoords
IsPlayerOnDungeonWarp:
	; [wWhichDungeonWarp] = 0
	xor a
	ld [wWhichDungeonWarp], a

	; dungeon warpフラグが立っていないなら返る
	ld a, [wd72d]
	bit 4, a
	ret nz
	
	; [wWhichDungeonWarp] = 現在利用しているdungeon mapのcoords
	call ArePlayerCoordsInArray
	ret nc
	ld a, [wCoordIndex]
	ld [wWhichDungeonWarp], a
	
	; dungeon warp中であることを示すフラグを立てる
	ld hl, wd72d
	set 4, [hl]
	ld hl, wd732
	set 4, [hl]
	ret

; hidden objectが存在するかチェック  
; OUTPUT: 
; - [$ffee] = hidden objectが見つかったなら$00, 見つからなかったら$ff
CheckForHiddenObject:
	; ループの前に初期化
	ld hl, $ffeb
	xor a
	ld [hli], a ; [$ffeb] = 0
	ld [hli], a ; [$ffec] = 0
	ld [hli], a	; [$ffed] = 0
	ld [hl], a	; [$ffee] = 0
	ld de, $0	; de = 0
	ld hl, HiddenObjectMaps

.hiddenMapLoop
	; b = HiddenObjectMapsのエントリ
	ld a, [hli]
	ld b, a
	
	; HiddenObjectMapsの最後まで来たがどれも該当しない
	cp $ff
	jr z, .noMatch
	
	; HiddenObjectMapsのエントリに現在のマップがある
	ld a, [wCurMap]
	cp b
	jr z, .foundMatchingMap

	; de += 2して次のエントリ
	inc de
	inc de
	jr .hiddenMapLoop

.foundMatchingMap
	; hl = 現在のマップのhidden object一覧へのポインタ
	ld hl, HiddenObjectPointers
	add hl, de

	; format: y-coord, x-coord, text id/item id, object routine
	; h:l = Ycoord/Xcoord
	ld a, [hli]
	ld h, [hl]
	ld l, a
	push hl
	ld hl, wHiddenObjectFunctionArgument
	xor a
	ld [hli], a
	ld [hli], a
	ld [hl], a
	pop hl
.hiddenObjectLoop
	ld a, [hli]
	cp $ff
	jr z, .noMatch
	ld [wHiddenObjectY], a
	ld b, a
	ld a, [hli]
	ld [wHiddenObjectX], a
	ld c, a
	call CheckIfCoordsInFrontOfPlayerMatch
	ld a, [hCoordsInFrontOfPlayerMatch]
	and a
	jr z, .foundMatchingObject
	inc hl
	inc hl
	inc hl
	inc hl
	push hl
	ld hl, wHiddenObjectIndex
	inc [hl]
	pop hl
	jr .hiddenObjectLoop
.foundMatchingObject
	ld a, [hli]
	ld [wHiddenObjectFunctionArgument], a
	ld a, [hli]
	ld [wHiddenObjectFunctionRomBank], a
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ret
.noMatch
	ld a, $ff
	ld [$ffee], a
	ret

; checks if the coordinates in front of the player's sprite match Y in b and X in c
; [hCoordsInFrontOfPlayerMatch] = $00 if they match, $ff if they don't match
CheckIfCoordsInFrontOfPlayerMatch:
	ld a, [wSpriteStateData1 + 9] ; player's sprite facing direction
	cp SPRITE_FACING_UP
	jr z, .facingUp
	cp SPRITE_FACING_LEFT
	jr z, .facingLeft
	cp SPRITE_FACING_RIGHT
	jr z, .facingRight
; facing down
	ld a, [wYCoord]
	inc a
	jr .upDownCommon
.facingUp
	ld a, [wYCoord]
	dec a
.upDownCommon
	cp b
	jr nz, .didNotMatch
	ld a, [wXCoord]
	cp c
	jr nz, .didNotMatch
	jr .matched
.facingLeft
	ld a, [wXCoord]
	dec a
	jr .leftRightCommon
.facingRight
	ld a, [wXCoord]
	inc a
.leftRightCommon
	cp c
	jr nz, .didNotMatch
	ld a, [wYCoord]
	cp b
	jr nz, .didNotMatch
.matched
	xor a
	jr .done
.didNotMatch
	ld a, $ff
.done
	ld [hCoordsInFrontOfPlayerMatch], a
	ret

INCLUDE "data/hidden_objects.asm"
