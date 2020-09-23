; **UsedCut**  
; いあいぎりを使用したときの処理
UsedCut:
	; 失敗したときの値で結果を入れる変数(wActionResultOrTookBattleTurn)を初期化
	xor a
	ld [wActionResultOrTookBattleTurn], a

	; タイルセットが OVERWORLD -> .overworld
	ld a, [wCurMapTileset]
	and a ; OVERWORLD
	jr z, .overworld

	; タイルセットが GYM でない -> .nothingToCut
	cp GYM
	jr nz, .nothingToCut

	; タイルセットが GYM のときに 目の前のタイルが居合切りできるタイルではない -> .nothingToCut
	ld a, [wTileInFrontOfPlayer]
	cp $50 ; gym cut tree
	jr nz, .nothingToCut

	jr .canCut

; タイルセットが OVERWORLD のときに目の前のタイルが居合切り可能なタイルなら -> .canCut
.overworld
	dec a
	ld a, [wTileInFrontOfPlayer]
	cp $3d ; cut tree
	jr z, .canCut
	cp $52 ; grass
	jr z, .canCut

; 目の前のタイルが居合切り可能なタイルでないときは、その旨のテキストを表示して処理を終える
.nothingToCut
	ld hl, .NothingToCutText
	jp PrintText

; "There isn't anything to CUT!"
.NothingToCutText
	TX_FAR _NothingToCutText
	db "@"

.canCut
	ld [wCutTile], a ; [wCutTile] = [wTileInFrontOfPlayer]

	; [wActionResultOrTookBattleTurn] = 1
	ld a, 1
	ld [wActionResultOrTookBattleTurn], a ; used cut

	; 居合切りの際に、ポケモンの名前をテキストとして出すので名前を取得する
	ld a, [wWhichPokemon]
	ld hl, wPartyMonNicks
	call GetPartyMonName

	; テキスト遅延フラグをセット
	ld hl, wd730
	set 6, [hl]

	; overworld描画に必要なアセットを復帰する
	call GBPalWhiteOutWithDelay3
	call ClearSprites
	call RestoreScreenTilesAndReloadTilePatterns

	; ウィンドウ表示を無効化
	ld a, SCREEN_HEIGHT_PIXELS
	ld [hWY], a
	
	call Delay3

	; overworldのタイルデータを wTileMapBackup2 に退避
	call LoadGBPal
	call LoadCurrentMapView
	call SaveScreenTilesToBuffer2
	
	call Delay3

	; ウィンドウ表示を有効化 
	xor a
	ld [hWY], a

	; "<POKEMON> hacked away with CUT!"
	ld hl, UsedCutText
	call PrintText

	; 退避したoverworldのタイルデータを復帰
	call LoadScreenTilesFromBuffer2

	; テキスト遅延を無効化
	ld hl, wd730
	res 6, [hl]
	
	; スプライトの更新を無効化
	ld a, $ff
	ld [wUpdateSpritesEnabled], a

	call InitCutAnimOAM
	ld de, CutTreeBlockSwaps
	call ReplaceTreeTileBlock
	call RedrawMapView
	callba AnimCut
	ld a, $1
	ld [wUpdateSpritesEnabled], a
	ld a, SFX_CUT
	call PlaySound
	ld a, $90
	ld [hWY], a
	call UpdateSprites
	jp RedrawMapView

; "<POKEMON> hacked away with CUT!"
UsedCutText:
	TX_FAR _UsedCutText
	db "@"

; **InitCutAnimOAM**  
; いあいぎり、かいりきのアニメーションに必要なOAMを準備する
InitCutAnimOAM:
	; [wWhichAnimationOffsets] = 0
	xor a
	ld [wWhichAnimationOffsets], a

	; 
	ld a, %11100100
	ld [rOBP1], a

	; 切る対象のタイルID = $52 -> .grass
	ld a, [wCutTile]
	cp $52
	jr z, .grass

	; tree
	; 木のタイルデータをVRAMに読み込む
	ld de, Overworld_GFX + $2d0 ; cuttable tree sprite top row
	ld hl, vChars1 + $7c0
	lb bc, BANK(Overworld_GFX), $02
	call CopyVideoData
	ld de, Overworld_GFX + $3d0 ; cuttable tree sprite bottom row
	ld hl, vChars1 + $7e0
	lb bc, BANK(Overworld_GFX), $02
	call CopyVideoData

	jr WriteCutOrBoulderDustAnimationOAMBlock

.grass
	; 草のグラフィックデータをVRAMに読み込む
	ld hl, vChars1 + $7c0
	call LoadCutGrassAnimationTilePattern
	ld hl, vChars1 + $7d0
	call LoadCutGrassAnimationTilePattern
	ld hl, vChars1 + $7e0
	call LoadCutGrassAnimationTilePattern
	ld hl, vChars1 + $7f0
	call LoadCutGrassAnimationTilePattern

	call WriteCutOrBoulderDustAnimationOAMBlock
	ld hl, wOAMBuffer + $93
	ld de, 4
	ld a, $30
	ld c, e
.loop
	ld [hl], a
	add hl, de
	xor $60
	dec c
	jr nz, .loop
	ret

LoadCutGrassAnimationTilePattern:
	ld de, AnimationTileset2 + $60 ; tile depicting a leaf
	lb bc, BANK(AnimationTileset2), $01
	jp CopyVideoData

; **WriteCutOrBoulderDustAnimationOAMBlock**  
; wOAMBuffer(正確には wOAMBuffer + 0x90) に いあいぎり や かいりき のアニメーションを書き込む処理  
; - - -  
; 主人公の向いている方向や、いあいぎり か かいりき かによって結果が変わってくる  
; いあいぎり なら　木が切れるアニメーション  
; かいりき なら 土埃のアニメーション  
WriteCutOrBoulderDustAnimationOAMBlock:
	call GetCutOrBoulderDustAnimationOffsets
	ld a, $9
	ld de, CutOrBoulderDustAnimationTilesAndAttributes
	; wOAMBuffer の 9(a)*4(OAM blockが 2*2なので) -> 36番目に配置する  
	; OAMは4byteなので 36 * 4 = 144 = 0x90 つまり wOAMBuffer + 0x90に配置
	jp WriteOAMBlock

CutOrBoulderDustAnimationTilesAndAttributes:
	db $FC,$10,$FD,$10
	db $FE,$10,$FF,$10

; **GetCutOrBoulderDustAnimationOffsets**  
; アニメーションを表示するXY座標を得る関数  
; - - -  
; 主人公の向いている方向や、いあいぎり か かいりき かによって結果が変わってくる  
; いあいぎり なら　木が切れるアニメーション  
; かいりき なら 土埃のアニメーション  
; 
; INPUT:  
; [wWhichAnimationOffsets] = 0(いあいぎり) or 1(かいりき)  
; 
; OUTPUT:  
; b = アニメのX座標  
; c = アニメのY座標
GetCutOrBoulderDustAnimationOffsets:
	; bc = 主人公のXY座標
	ld hl, wSpriteStateData1 + 4
	ld a, [hli]
	ld b, a ; b = 主人公のY座標
	inc hl
	ld a, [hli]
	ld c, a ; c = 主人公のX座標
	
	; de = 主人公の方向 = 0(下) or 2(上) or 4(左) or 6(右)
	inc hl
	inc hl
	ld a, [hl] ; a holds direction of player (00: down, 04: up, 08: left, 0C: right)
	srl a
	ld e, a
	ld d, $0 ; de holds direction (00: down, 02: up, 04: left, 06: right)

	; hl = CutAnimationOffsets or BoulderDustAnimationOffsets
	ld a, [wWhichAnimationOffsets]
	and a
	ld hl, CutAnimationOffsets
	jr z, .next
	ld hl, BoulderDustAnimationOffsets

.next
	; d = アニメの相対X座標,  e = アニメの相対Y座標
	add hl, de
	ld e, [hl]
	inc hl
	ld d, [hl]

	; b = アニメの画面上でのX座標
	ld a, b
	add d
	ld b, a
	; c = アニメの画面上でのY座標
	ld a, c
	add e
	ld c, a
	ret

; プレイヤーを基準とした木のオフセットのテーブル  
; プレイヤーの位置は (8, 20)  
CutAnimationOffsets:
	db  8, 36 ; 下 y += 16
	db  8,  4 ; 上 y -= 16
	db -8, 20 ; 左 x -= 16
	db 24, 20 ; 右 x += 16

; Each pair represents the x and y pixels offsets from the player of where the cut tree animation should be drawn
; These offsets represent 2 blocks away from the player  
; プレイヤーの位置は (8, 20)  
BoulderDustAnimationOffsets:
	db  8,  52 ; 下 y += 32
	db  8, -12 ; 上 y -= 32
	db -24, 20 ; 左 x -= 32
	db 40,  20 ; 右 x += 32

; プレイヤーの目の前のタイルブロックのタイルアドレスを計算し(そこに木がある)、木のないタイルブロックで置換する
ReplaceTreeTileBlock:
	push de
	; bc = [wCurMapWidth] + 6(MAP_BORDER*2?) = 現在のマップの1行分のブロックの枚数 + ボーダーの枚数
	ld a, [wCurMapWidth]
	add 6
	ld c, a
	ld b, 0

	ld d, 0

	; hl = [wCurrentTileBlockMapViewPointer]
	ld hl, wCurrentTileBlockMapViewPointer
	inline "hl = [hl]"

	add hl, bc

	; プレイヤーの向いている方向で場合分け
	ld a, [wSpriteStateData1 + 9]
	and a
	jr z, .down
	cp SPRITE_FACING_UP
	jr z, .up
	cp SPRITE_FACING_LEFT
	jr z, .left

; .right
	ld a, [wXBlockCoord]
	and a
	jr z, .centerTileBlock
	jr .rightOfCenter

.down
	ld a, [wYBlockCoord]
	and a
	jr z, .centerTileBlock
	jr .belowCenter

.up
	ld a, [wYBlockCoord]
	and a
	jr z, .aboveCenter
	jr .centerTileBlock

.left
	ld a, [wXBlockCoord]
	and a
	jr z, .leftOfCenter
	jr .centerTileBlock
.belowCenter
	add hl, bc
.centerTileBlock
	add hl, bc
.aboveCenter
	ld e, $2	; de = 02
	add hl, de
	jr .next
.leftOfCenter
	ld e, $1	; de = 01
	add hl, bc
	add hl, de
	jr .next
.rightOfCenter
	ld e, $3 	; de = 03
	add hl, bc
	add hl, de
.next
	pop de
	ld a, [hl]
	ld c, a
.loop ; find the matching tile block in the array
	ld a, [de]
	inc de
	inc de
	cp $ff
	ret z
	cp c
	jr nz, .loop
	dec de
	ld a, [de] ; replacement tile block from matching array entry
	ld [hl], a
	ret

; 居合切り時に使う1エントリ2バイトのテーブル  
; 1バイト目 = 木を含む tileset block  
; 2バイト目 = 木を切った後の tileset block  
CutTreeBlockSwaps:
	db $32, $6D
	db $33, $6C
	db $34, $6F
	db $35, $4C
	db $60, $6E
	db $0B, $0A
	db $3C, $35
	db $3F, $35
	db $3D, $36
	db $FF ; list terminator
