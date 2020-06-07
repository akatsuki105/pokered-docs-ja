SpecialWarpIn:
	call LoadSpecialWarpData
	predef LoadTilesetHeader
	ld hl, wd732
	bit 2, [hl] ; dungeon warp or fly warp?
	res 2, [hl]
	jr z, .next
; if dungeon warp or fly warp
	ld a, [wDestinationMap]
	jr .next2
.next
	bit 1, [hl]
	jr z, .next3
	call EmptyFunc
.next3
	ld a, 0
.next2
	ld b, a
	ld a, [wd72d]
	and a
	jr nz, .next4
	ld a, b
.next4
	ld hl, wd732
	bit 4, [hl] ; dungeon warp?
	ret nz
; if not dungeon warp
	ld [wLastMap], a
	ret

; **LoadSpecialWarpData**  
; gets the map ID, tile block map view pointer, tileset, and coordinates  
; マップID、tile block map view pointer, タイルセット、座標を取得する  
LoadSpecialWarpData:
	; [wd72d] != TRADE_CENTER -> .notTradeCenter
	ld a, [wd72d]
	cp TRADE_CENTER
	jr nz, .notTradeCenter

	; トレードセンター(通信交換部屋)でスプライトの方向が初期化されているときにここにくる

	; hl = TradeCenterSpec1(masterとして通信) or TradeCenterSpec2(slaveとして通信) -> .copyWarpData
	ld hl, TradeCenterSpec1
	ld a, [hSerialConnectionStatus]
	cp USING_INTERNAL_CLOCK ; ゲームボーイのシリアルのクロックによって通信ルームの立ち位置(右か左か)が決まる
	jr z, .copyWarpData
	ld hl, TradeCenterSpec2
	jr .copyWarpData

.notTradeCenter
	; [wd72d] != COLOSSEUM -> .notColosseum
	cp COLOSSEUM
	jr nz, .notColosseum
	
	; コロシアム(通信対戦部屋)のときここにくる

	; hl = ColosseumSpec1(master) or ColosseumSpec2(slave) -> .copyWarpData
	ld hl, ColosseumSpec1
	ld a, [hSerialConnectionStatus]
	cp USING_INTERNAL_CLOCK
	jr z, .copyWarpData
	ld hl, ColosseumSpec2
	jr .copyWarpData

.notColosseum
	; [wd732]の bit1 か bit2 が 0 でないなら .notFirstMapへ 
	; special warp時にデバッグモードのときや、fly warpやdungeon warpの時点で、FirstMapSpecでないことが確定する
	ld a, [wd732]
	bit 1, a
	jr nz, .notFirstMap
	bit 2, a
	jr nz, .notFirstMap
	
	; 消去法的にspecial warpの種類が FirstMapSpec(主人公の2階へのワープ) だと確定する
	ld hl, FirstMapSpec

	; INPUT: hl = 対象のwarpのspec e.g. FirstMapSpec, ColosseumSpec2
.copyWarpData
	ld de, wCurMap
	ld c, $7 ; .copyWarpDataLoop のループ回数 

	; Special warpの情報をwCurMapに格納
	; [wCurMap:wCurMap+7] = [XXXSpec:XXXSpec+7]
.copyWarpDataLoop
	; [de++] = [hl++]
	ld a, [hli]
	ld [de], a
	inc de
	dec c
	jr nz, .copyWarpDataLoop

	; Special warpのタイルセットIDをwCurMapTilesetに格納
	ld a, [hli]
	ld [wCurMapTileset], a
	
	xor a
	jr .done
.notFirstMap
	ld a, [wLastMap] ; this value is overwritten before it's ever read
	ld hl, wd732
	bit 4, [hl] ; used dungeon warp (jumped down hole/waterfall)?
	jr nz, .usedDunegonWarp
	bit 6, [hl] ; return to last pokemon center (or player's house)?
	res 6, [hl]
	jr z, .otherDestination
; return to last pokemon center or player's house
	ld a, [wLastBlackoutMap]
	jr .usedFlyWarp
.usedDunegonWarp
	ld hl, wd72d
	res 4, [hl]
	ld a, [wDungeonWarpDestinationMap]
	ld b, a
	ld [wCurMap], a
	ld a, [wWhichDungeonWarp]
	ld c, a
	ld hl, DungeonWarpList
	ld de, 0
	ld a, 6
	ld [wDungeonWarpDataEntrySize], a
.dungeonWarpListLoop
	ld a, [hli]
	cp b
	jr z, .matchedDungeonWarpDestinationMap
	inc hl
	jr .nextDungeonWarp
.matchedDungeonWarpDestinationMap
	ld a, [hli]
	cp c
	jr z, .matchedDungeonWarpID
.nextDungeonWarp
	ld a, [wDungeonWarpDataEntrySize]
	add e
	ld e, a
	jr .dungeonWarpListLoop
.matchedDungeonWarpID
	ld hl, DungeonWarpData
	add hl, de
	jr .copyWarpData2
.otherDestination
	ld a, [wDestinationMap]
.usedFlyWarp
	ld b, a
	ld [wCurMap], a
	ld hl, FlyWarpDataPtr
.flyWarpDataPtrLoop
	ld a, [hli]
	inc hl
	cp b
	jr z, .foundFlyWarpMatch
	inc hl
	inc hl
	jr .flyWarpDataPtrLoop
.foundFlyWarpMatch
	ld a, [hli]
	ld h, [hl]
	ld l, a
.copyWarpData2
	ld de, wCurrentTileBlockMapViewPointer
	ld c, $6
.copyWarpDataLoop2
	ld a, [hli]
	ld [de], a
	inc de
	dec c
	jr nz, .copyWarpDataLoop2
	xor a ; OVERWORLD
	ld [wCurMapTileset], a
.done
	ld [wYOffsetSinceLastSpecialWarp], a
	ld [wXOffsetSinceLastSpecialWarp], a
	ld a, $ff ; the player's coordinates have already been updated using a special warp, so don't use any of the normal warps
	ld [wDestinationWarpID], a
	ret

INCLUDE "data/special_warps.asm"
