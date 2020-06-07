; **SpecialWarpIn**  
; special warpを行う  
; - - -  
; OUTPUT: [wLastMap] = special warp先のマップID  
SpecialWarpIn:
	call LoadSpecialWarpData
	predef LoadTilesetHeader ; LoadSpecialWarpData で取得したワープ先のタイルセットを読み込む

	; dungeon warp, fly warpでない -> .next
	ld hl, wd732
	bit 2, [hl] ; dungeon warp or fly warp?
	res 2, [hl]
	jr z, .next
	; dungeon warp か fly warp のとき -> a = [wDestinationMap]して .next2
	ld a, [wDestinationMap]
	jr .next2

.next
	bit 1, [hl]
	jr z, .next3
	call EmptyFunc ; デバッグモードのとき
.next3
	ld a, 0

	; INPUT: a = 0 or [wDestinationMap]
.next2
	ld b, a
	; a = [wd72d]([wd72d] != 0) or b([wd72d] == 0)
	ld a, [wd72d]
	and a
	jr nz, .next4
	ld a, b
.next4
	; dungeon warpなら終了
	ld hl, wd732
	bit 4, [hl] ; dungeon warp?
	ret nz
	; dungeon warpじゃないとき
	ld [wLastMap], a
	ret

; **LoadSpecialWarpData**  
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
	; 上で トレードセンターやコロシアムでないことも確定しているので、.notFirstMapの時点でfly warpやdungeon warpなどのワープとわかる
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

	; dungeon warp のとき -> .usedDunegonWarp
	bit 4, [hl]
	jr nz, .usedDunegonWarp

	; wd732のbit6が立っていない -> .otherDestination
	bit 6, [hl] ; return to last pokemon center (or player's house)?
	res 6, [hl]
	jr z, .otherDestination

	; このとき warp先は[wLastBlackoutMap](最後に利用したポケモンセンターか主人公の家)
	ld a, [wLastBlackoutMap]
	jr .usedFlyWarp

	; dungeon warp(『ポケモンやしき』や『ふたごじま』、『チャンピオンロード』での穴によるマップ移動や『ふたごじま』の水流によるマップ移動)のとき
.usedDunegonWarp
	; dungeon warp中のフラグをクリア
	ld hl, wd72d
	res 4, [hl]

	; [wCurMap] = [wDungeonWarpDestinationMap]
	ld a, [wDungeonWarpDestinationMap]
	ld b, a	; b = [wDungeonWarpDestinationMap]
	ld [wCurMap], a

	; c = [wWhichDungeonWarp]
	ld a, [wWhichDungeonWarp]
	ld c, a
	
	ld hl, DungeonWarpList
	ld de, 0

	; [wDungeonWarpDataEntrySize] = 6
	ld a, 6
	ld [wDungeonWarpDataEntrySize], a

.dungeonWarpListLoop
	ld a, [hli]
	; dungeon warpのlistにワープ先のマップが[wDungeonWarpDestinationMap]と一致するものがあった -> .matchedDungeonWarpDestinationMap
	cp b	; b = [wDungeonWarpDestinationMap]
	jr z, .matchedDungeonWarpDestinationMap
	; 一致しない場合は次のエントリへ
	inc hl
	jr .nextDungeonWarp

	; ここに来たときは dungeon warp のlistのエントリの1バイト目はOKなので2バイト目も一致するか確認する
.matchedDungeonWarpDestinationMap
	ld a, [hli]
	; dungeon warpIDも一致する -> .matchedDungeonWarpID
	cp c ; c = [wWhichDungeonWarp]
	jr z, .matchedDungeonWarpID
	; 一致しないならそのまま .nextDungeonWarpへ続く
	
	; e += 6　して 次のエントリへ
.nextDungeonWarp
	ld a, [wDungeonWarpDataEntrySize]
	add e
	ld e, a
	jr .dungeonWarpListLoop

	; ここに来たときは対象のdungeon warpをlistから見つけたとき
	; このとき e = 6*(DungeonWarpListオフセット)
.matchedDungeonWarpID
	ld hl, DungeonWarpData
	add hl, de
	jr .copyWarpData2 ; hl = DungeonWarpDataのエントリのアドレス

.otherDestination
	ld a, [wDestinationMap]
	; .usedFlyWarp へ続く

	; INPUT: a = [wLastBlackoutMap] or [wDestinationMap]
.usedFlyWarp
	; b と wCurMap にワープ先のマップを格納
	ld b, a
	ld [wCurMap], a

	ld hl, FlyWarpDataPtr
.flyWarpDataPtrLoop
	ld a, [hli] ; a = ワープ先
	inc hl
	; FlyWarpDataPtr の現在のエントリにワープ先が一致する -> .foundFlyWarpMatch
	cp b
	jr z, .foundFlyWarpMatch
	; 次のエントリ
	inc hl
	inc hl
	jr .flyWarpDataPtrLoop

.foundFlyWarpMatch
	; hl = PalletTownFlyWarp
	ld a, [hli]
	ld h, [hl]
	ld l, a

	; INPUT: hl = XXXWarpDataのアドレス
.copyWarpData2
	ld de, wCurrentTileBlockMapViewPointer
	ld c, $6
	; wCurrentTileBlockMapViewPointerにWarpDataをコピーする
.copyWarpDataLoop2
	; [de++] = [hl++]
	ld a, [hli]
	ld [de], a
	inc de
	dec c
	jr nz, .copyWarpDataLoop2
	; [wCurMapTileset] = OVERWORLD
	xor a ; OVERWORLD
	ld [wCurMapTileset], a
	; INPUT: a = 0
.done
	; [wXOffsetSinceLastSpecialWarp] = 0 [wYOffsetSinceLastSpecialWarp] = 0
	ld [wYOffsetSinceLastSpecialWarp], a
	ld [wXOffsetSinceLastSpecialWarp], a
	; [wDestinationWarpID] = $ff
	ld a, $ff ; プレイヤーの座標はspecial warpでは既に更新されているため通常のワープは使用しない ??
	ld [wDestinationWarpID], a
	ret

INCLUDE "data/special_warps.asm"
