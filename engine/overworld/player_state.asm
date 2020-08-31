; **IsPlayerStandingOnWarp**  
; 主人公が warp マスの上にいるかチェックする  
; - - -  
; only used for setting bit 2 of wd736 upon entering a new map  
; 
; OUTPUT: wd736 の bit2 = 1(いる) or 0(いない)  
IsPlayerStandingOnWarp:
	ld a, [wNumberOfWarps]

	; warp が存在しないなら return 
	and a
	ret z

	ld c, a	; c = warp数
	ld hl, wWarpEntries

; マップ内の warp に主人公の coord と一致するものがあるかみていく
.loop
; {
	ld a, [wYCoord]
	cp [hl]
	jr nz, .nextWarp1
	inc hl
	ld a, [wXCoord]
	cp [hl]
	jr nz, .nextWarp2
	inc hl
	ld a, [hli]
	ld [wDestinationWarpID], a
	ld a, [hl]
	ld [hWarpDestinationMap], a
	ld hl, wd736
	set 2, [hl]
	ret

.nextWarp1
	inc hl
.nextWarp2
	inc hl
	inc hl
	inc hl

	; warp を全部みたが主人公のcoordと一致するものはなかった
	dec c
	jr nz, .loop
; }

	ret

; **CheckForceBikeOrSurf**  
; 主人公がいるマップ上のマスが 自転車 か 波乗り を強制されるマスかチェックし、そうならフラグを立てて ForceBikeOrSurf にジャンプ  
CheckForceBikeOrSurf:
	ld hl, wd732
	bit 5, [hl]
	ret nz

; ここから ForcedBikeOrSurfMaps の中に現在の主人公のcoordと一致するものがあるかチェック 
	ld hl, ForcedBikeOrSurfMaps
	ld a, [wYCoord]
	ld b, a
	ld a, [wXCoord]
	ld c, a
	ld a, [wCurMap]
	ld d, a
.loop
	ld a, [hli] ; a = MapID

	; 該当するものなし -> return
	cp $ff
	ret z

	; 一致しない場合は次のエントリへ
	cp d
	jr nz, .incorrectMap
	ld a, [hli]
	cp b
	jr nz, .incorrectY
	ld a, [hli]
	cp c
	jr nz, .loop

	; ここに来た時点で 現在のエントリが プレイヤーの 現在のマップのcoord と一致 

	; 現在のマップが SEAFOAM_ISLANDS_B3F -> .forceSurfing
	ld a, [wCurMap]
	cp SEAFOAM_ISLANDS_B3F
	ld a, $2
	ld [wSeafoamIslandsB3FCurScript], a ; [wSeafoamIslandsB3FCurScript] = SEAFOAM_ISLANDS_B3F
	jr z, .forceSurfing

	; 現在のマップが SEAFOAM_ISLANDS_B4F -> .forceSurfing
	ld a, [wCurMap]
	cp SEAFOAM_ISLANDS_B4F
	ld a, $2
	ld [wSeafoamIslandsB4FCurScript], a ; [wSeafoamIslandsB4FCurScript] = SEAFOAM_ISLANDS_B4F
	jr z, .forceSurfing

	; SEAFOAM_ISLANDS_B3F でも SEAFOAM_ISLANDS_B4F ないなら ROUTE_16 か ROUTE_18 なので自転車

; .forceBike
	;　フラグを立てて -> ForceBikeOrSurf
	; wd732[5] = 1  
	ld hl, wd732
	set 5, [hl]
	ld a, $1
	; [wWalkBikeSurfState], [wWalkBikeSurfStateCopy] = 1  
	ld [wWalkBikeSurfState], a
	ld [wWalkBikeSurfStateCopy], a
	jp ForceBikeOrSurf

; 次のループへ
.incorrectMap
	inc hl
.incorrectY
	inc hl
	jr .loop

.forceSurfing
	; フラグを立てて -> ForceBikeOrSurf
	; [wWalkBikeSurfState], [wWalkBikeSurfStateCopy] = 2
	ld a, $2
	ld [wWalkBikeSurfState], a
	ld [wWalkBikeSurfStateCopy], a
	jp ForceBikeOrSurf

INCLUDE "data/force_bike_surf.asm"

; **IsPlayerFacingEdgeOfMap**  
; プレイヤーがマップの端っこにいるか調べる  
; - - -  
; 端っこ = マップを長方形とみなしたときの境界部分  
; 
; OUTPUT: carry = 1(端っこにいる) or 0(いない)  
IsPlayerFacingEdgeOfMap:
	push hl
	push de
	push bc
	
	; hl = .functionPointerTable の 主人公の向いている方向 に対応するエントリ
	ld a, [wSpriteStateData1 + 9] ; 主人公の向いている方向
	srl a
	ld c, a
	ld b, $0
	ld hl, .functionPointerTable
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a

	; b = Ycoord, c = Xcoord
	ld a, [wYCoord]
	ld b, a
	ld a, [wXCoord]
	ld c, a

	; call .facing${direction}
	; マップの端っこにいるか調べる
	ld de, .asm_c41e
	push de
	jp hl

.asm_c41e
	pop bc
	pop de
	pop hl
	ret

.functionPointerTable
	dw .facingDown
	dw .facingUp
	dw .facingLeft
	dw .facingRight

; マップの一番下にいるか
.facingDown
	ld a, [wCurMapHeight]
	add a	; 32*32 -> 16*16
	dec a
	cp b
	jr z, .setCarry	; マップの縦長-1 に等しいなら主人公はマップの一番下にいる
	jr .resetCarry

; マップの一番上にいるか
.facingUp
	ld a, b
	and a
	jr z, .setCarry
	jr .resetCarry

; マップの一番左にいるか
.facingLeft
	ld a, c
	and a
	jr z, .setCarry
	jr .resetCarry

; マップの一番右にいるか
.facingRight
	ld a, [wCurMapWidth]
	add a
	dec a
	cp c
	jr z, .setCarry
	jr .resetCarry

.resetCarry
	and a
	ret
.setCarry
	scf
	ret

; **IsWarpTileInFrontOfPlayer**  
; 主人公の目の前のタイルのタイル番号が warp として使われるタイルのタイル番号かどうか調べる  
; - - -  
; warp として使われるタイルのタイル番号はあらかじめ決められておりそれに該当するか調べる  
; 
; OUTPUT:  
; carry = 1(warpタイルだった) or 0(ではない)  
IsWarpTileInFrontOfPlayer:
	push hl
	push de
	push bc
	call _GetTileAndCoordsInFrontOfPlayer ; [wTileInFrontOfPlayer] = 目の前のタイル番号

	; 現在のマップがサントアンヌ号の船主 -> .ssAnne
	ld a, [wCurMap]
	cp SS_ANNE_BOW
	jr z, .ssAnne5

	; hl = .warpTileListPointers の 主人公の方向 に応じたエントリ (.facing${direction}WarpTiles)
	ld a, [wSpriteStateData1 + 9] ; 主人公の方向
	srl a
	ld c, a
	ld b, 0
	ld hl, .warpTileListPointers
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a

	; 目の前のタイルが warp タイルのリストに該当するかチェック
	ld a, [wTileInFrontOfPlayer]
	ld de, $1
	call IsInArray ; 該当するなら carry = 1

.done
	pop bc
	pop de
	pop hl
	ret

; 主人公の向いている方向に応じた warp タイルの種類のリスト
.warpTileListPointers:
	dw .facingDownWarpTiles
	dw .facingUpWarpTiles
	dw .facingLeftWarpTiles
	dw .facingRightWarpTiles
.facingDownWarpTiles
	db $01,$12,$17,$3D,$04,$18,$33,$FF
.facingUpWarpTiles
	db $01,$5C,$FF
.facingLeftWarpTiles
	db $1A,$4B,$FF
.facingRightWarpTiles
	db $0F,$4E,$FF

; サントアンヌ号の船主だけは、 warp タイルが特殊($15)
.ssAnne5
	ld a, [wTileInFrontOfPlayer]
	cp $15
	jr nz, .notSSAnne5Warp
	scf
	jr .done
.notSSAnne5Warp
	and a	; carry = 0
	jr .done

; **IsPlayerStandingOnDoorTileOrWarpTile**  
; プレイヤーが、ドアタイルかwarpタイルの上に立っているかを調べる  
; - - -  
; OUTPUT: carry = 1(いる) or 0(いない)  
; 
; warpタイルの上にいるときは wd736のbit2をクリアしている  
IsPlayerStandingOnDoorTileOrWarpTile:
	push hl
	push de
	push bc

	; プレイヤーがドアタイルにいる -> .done
	callba IsPlayerStandingOnDoorTile
	jr c, .done

	; hl = 現在のタイルセットの warp タイルのリスト (WarpTileIDPointers の現在のマップのタイルセットに応じたエントリ)
	ld a, [wCurMapTileset]
	add a
	ld c, a
	ld b, $0
	ld hl, WarpTileIDPointers
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a

	; プレイヤーが warpマス の上に立っているか
	ld de, $1
	aCoord 8, 9
	call IsInArray

	; 立っているなら wd736のbit2をクリアする
	jr nc, .done
	ld hl, wd736
	res 2, [hl]

.done
	pop bc
	pop de
	pop hl
	ret

INCLUDE "data/warp_tile_ids.asm"

; **PrintSafariZoneSteps**  
; 主人公がサファリゾーン内にいる場合に、左上に残り歩数と残りボール数を描画する  
; - - -  
; ![example](https://imgur.com/DL91wpQ.png)
PrintSafariZoneSteps:
	; [wCurMap] < SAFARI_ZONE_EAST なら終了
	; サファリゾーンのマップIDは全て SAFARI_ZONE_EAST 以上なので [wCurMap] < SAFARI_ZONE_EAST の時点でサファリゾーンにいないとわかる
	ld a, [wCurMap]
	cp SAFARI_ZONE_EAST
	ret c

	; [wCurMap] >= CERULEAN_CAVE_2F でも終了
	; サファリゾーンのマップIDは全て CERULEAN_CAVE_2F 未満 なので [wCurMap] >= CERULEAN_CAVE_2F の時点でサファリゾーンにいないとわかる
	cp CERULEAN_CAVE_2F
	ret nc

	; ここに来た時点で主人公の現在のマップはサファリゾーンのどこか

	; ここから残り歩数と残りボール数を描画していく
	; ref: https://imgur.com/DL91wpQ.png

	; 残り歩数と残りボール数を描画するためのテキストボックス
	coord hl, 0, 0
	ld b, 3
	ld c, 7
	call TextBoxBorder

	; 残り歩数/500 を描画
	coord hl, 1, 1
	ld de, wSafariSteps
	lb bc, 2, 3
	call PrintNumber
	coord hl, 4, 1
	ld de, SafariSteps
	call PlaceString

	; BALL × N を描画
	coord hl, 1, 3
	ld de, SafariBallText
	call PlaceString
	ld a, [wNumSafariBalls]
	cp 10
	jr nc, .asm_c56d
	coord hl, 5, 3
	ld a, " "
	ld [hl], a
.asm_c56d
	coord hl, 6, 3
	ld de, wNumSafariBalls
	lb bc, 1, 2
	jp PrintNumber	; return

SafariSteps:
	db "/500@"

SafariBallText:
	db "BALL×× @"

; **GetTileAndCoordsInFrontOfPlayer**  
; プレイヤーの目の前の座標とタイル番号を得る  
; - - -  
; OUTPUT:  
; d = 目の前の Ycoord(16*16単位)  
; e = 目の前の Xcoord(16*16単位)  
; [wTileInFrontOfPlayer] = プレイヤーの目の前のタイルのタイル番号  
GetTileAndCoordsInFrontOfPlayer:
	call GetPredefRegisters

; **_GetTileAndCoordsInFrontOfPlayer**  
; GetTileAndCoordsInFrontOfPlayer と同じ処理  
_GetTileAndCoordsInFrontOfPlayer:
	ld a, [wYCoord]
	ld d, a
	ld a, [wXCoord]
	ld e, a
	ld a, [wSpriteStateData1 + 9] ; player's sprite facing direction
	and a ; cp SPRITE_FACING_DOWN
	jr nz, .notFacingDown
; facing down
	aCoord 8, 11	; (8, 9+2)
	inc d			; Y += 16
	jr .storeTile
.notFacingDown
	cp SPRITE_FACING_UP
	jr nz, .notFacingUp
; facing up
	aCoord 8, 7		; (8, 9-2)
	dec d			; Y -= 16s
	jr .storeTile
.notFacingUp
	cp SPRITE_FACING_LEFT
	jr nz, .notFacingLeft
; facing left
	aCoord 6, 9
	dec e
	jr .storeTile
.notFacingLeft
	cp SPRITE_FACING_RIGHT
	jr nz, .storeTile
; facing right
	aCoord 10, 9
	inc e
.storeTile
	ld c, a
	ld [wTileInFrontOfPlayer], a
	ret

; **GetTileTwoStepsInFrontOfPlayer**  
; プレイヤーの2マス目の前のタイル番号などを取得する  
; - - -  
; OUTPUT:  
; a = c = [wTileInFrontOfBoulderAndBoulderCollisionResult] = [wTileInFrontOfPlayer] = プレイヤーの2マス目の前のタイル番号  
; d = プレイヤーの目の前の16*16タイルのYCoord  
; e = プレイヤーの目の前の16*16タイルのXCoord  
; $ffdb = ???  
GetTileTwoStepsInFrontOfPlayer:
	; TODO: ???
	xor a
	ld [$ffdb], a

	; d = [wYCoord]
	; e = [wXCoord]
	ld hl, wYCoord
	ld a, [hli]
	ld d, a
	ld e, [hl]

	; プレイヤーが下を向いていない -> .notFacingDown
	ld a, [wSpriteStateData1 + 9] ; a = プレイヤーの方向
	and a ; cp SPRITE_FACING_DOWN
	jr nz, .notFacingDown

; .facingDown
	; $ffdb[0] = 1
	ld hl, $ffdb
	set 0, [hl]
	; a = (8, 9+4)
	aCoord 8, 13
	inc d
	jr .storeTile

.notFacingDown
	cp SPRITE_FACING_UP
	jr nz, .notFacingUp

; .facingUp
	; $ffdb[1] = 1
	ld hl, $ffdb
	set 1, [hl]
	; a = (8, 9-4)
	aCoord 8, 5
	dec d
	jr .storeTile

.notFacingUp
	cp SPRITE_FACING_LEFT
	jr nz, .notFacingLeft

; .facingLeft
	; $ffdb[2] = 1
	ld hl, $ffdb
	set 2, [hl]
	; a = (8-4, 9)
	aCoord 4, 9
	dec e
	jr .storeTile

.notFacingLeft
	cp SPRITE_FACING_RIGHT
	jr nz, .storeTile ; .notFacingRight

; .facingReft
	; $ffdb[3] = 1
	ld hl, $ffdb
	set 3, [hl]
	; a = (8+4, 9)
	aCoord 12, 9
	inc e

; 2マス先のタイル番号を格納して return
.storeTile
	ld c, a
	ld [wTileInFrontOfBoulderAndBoulderCollisionResult], a
	ld [wTileInFrontOfPlayer], a
	ret

; **CheckForCollisionWhenPushingBoulder**  
; かいりきで岩を押した先に障害物があるかどうかチェックする  
; - - -  
; 障害物: 通行不能タイル、Collisionテーブルのタイル、スプライトなど  
; Collisionテーブルについては `TilePairCollisionsLand` の説明参照  
; 
; OUTPUT: [wTileInFrontOfBoulderAndBoulderCollisionResult] = 0x00(障害物なし) or 0xff(障害物あり)
CheckForCollisionWhenPushingBoulder:
	call GetTileTwoStepsInFrontOfPlayer

	; hl = プレイヤーが通行可能なタイルのリストのアドレス
	ld hl, wTilesetCollisionPtr
	ld a, [hli]
	ld h, [hl]
	ld l, a

; プレイヤーの2マス前のタイルが通行可能か(かいりき岩を2マス前に押せるかどうかチェック)  
; 押せる -> loopの下へ  
; 押せない -> .done  
.loop
; {
	ld a, [hli]
	; プレイヤーの2マス前のタイルが通行不能だとわかった -> .done
	cp $ff
	jr z, .done

	; プレイヤーの2マス前のタイルが通行可能だとわかったらループを抜ける
	cp c
	jr nz, .loop
; }

; .ok
	; プレイヤーのマスとプレイヤーの2マス前のタイルがまたげないタイル同士である(TilePairCollisionsLandの説明参照) -> .done  
	ld hl, TilePairCollisionsLand
	call CheckForTilePairCollisions2
	ld a, $ff
	jr c, .done

	; プレイヤーの2マス前のタイルが階段のとき
	ld a, [wTileInFrontOfBoulderAndBoulderCollisionResult]	; a = プレイヤーの2マス前のタイル番号
	cp $15 ; 階段のタイル
	ld a, $ff
	jr z, .done

	call CheckForBoulderCollisionWithSprites

; チェックした結果を格納してreturn
.done
	; この時点で a = 0x00(障害物なし) or 0xff(障害物あり)
	ld [wTileInFrontOfBoulderAndBoulderCollisionResult], a
	ret

; かいりきで岩を押した先にスプライトがあるかどうかチェックする  
; OUTPUT: a = 0x00(障害物なし) or 0xff(障害物あり)  
CheckForBoulderCollisionWithSprites:
	ld a, [wBoulderSpriteIndex]
	dec a
	swap a
	ld d, 0
	ld e, a
	ld hl, wSpriteStateData2 + $14
	add hl, de
	ld a, [hli] ; map Y position
	ld [$ffdc], a
	ld a, [hl] ; map X position
	ld [$ffdd], a
	ld a, [wNumSprites]
	ld c, a
	ld de, $f
	ld hl, wSpriteStateData2 + $14
	ld a, [$ffdb]
	and $3 ; facing up or down?
	jr z, .pushingHorizontallyLoop
.pushingVerticallyLoop
	inc hl
	ld a, [$ffdd]
	cp [hl]
	jr nz, .nextSprite1 ; if X coordinates don't match
	dec hl
	ld a, [hli]
	ld b, a
	ld a, [$ffdb]
	rrca
	jr c, .pushingDown
; pushing up
	ld a, [$ffdc]
	dec a
	jr .compareYCoords
.pushingDown
	ld a, [$ffdc]
	inc a
.compareYCoords
	cp b
	jr z, .failure
.nextSprite1
	dec c
	jr z, .success
	add hl, de
	jr .pushingVerticallyLoop
.pushingHorizontallyLoop
	ld a, [hli]
	ld b, a
	ld a, [$ffdc]
	cp b
	jr nz, .nextSprite2
	ld b, [hl]
	ld a, [$ffdb]
	bit 2, a
	jr nz, .pushingLeft
; pushing right
	ld a, [$ffdd]
	inc a
	jr .compareXCoords
.pushingLeft
	ld a, [$ffdd]
	dec a
.compareXCoords
	cp b
	jr z, .failure
.nextSprite2
	dec c
	jr z, .success
	add hl, de
	jr .pushingHorizontallyLoop
.failure
	ld a, $ff
	ret
.success
	xor a
	ret
