; **DrawBadges**  
; Draw 4x2 gym leader faces, with the faces replaced by badges if they are owned. Used in the player status screen.
DrawBadges:
	; .FaceBadgeTiles -> wBadgeOrFaceTiles にコピー
	ld de, wBadgeOrFaceTiles
	ld hl, .FaceBadgeTiles
	ld bc, 8
	call CopyData

	; wTempObtainedBadgesBooleans を 0 で初期化
	ld hl, wTempObtainedBadgesBooleans
	ld bc, 8
	xor a
	call FillMemory

; バッジを一つずつみていき取得済みならタイル番号とフラグを変更する
	ld de, wTempObtainedBadgesBooleans
	ld hl, wBadgeOrFaceTiles
	ld a, [wObtainedBadges]
	ld b, a
	ld c, 8	; bc = X8
.CheckBadge
; {
	; バッジ未取得 -> .NextBadge
	srl b
	jr nc, .NextBadge

	; バッジ取得済み
	; [hl] += 4 にして タイル番号を顔ではなくバッジのタイルに
	ld a, [hl]
	add 4
	ld [hl], a
	; wTempObtainedBadgesBooleansを取得済みに
	ld a, 1
	ld [de], a

	; 次のバッジへ
.NextBadge
	inc hl
	inc de
	dec c
	jr nz, .CheckBadge
; }

	; バッジ欄を描画していく
	ld hl, wBadgeNumberTile
	ld a, $d8 ; [1]
	ld [hli], a
	ld [hl], $60 ; [wBadgeNameTile] = $60(First name)

	; [1] ~ [4]
	coord hl, 2, 11
	ld de, wTempObtainedBadgesBooleans
	call .DrawBadgeRow

	; [5] ~ [8]
	coord hl, 2, 14
	ld de, wTempObtainedBadgesBooleans + 4
;	.DrawBadgeRow(fallthrough) & return

.DrawBadgeRow
	; バッジ欄を1行描画する
	; バッジ番号 -> (ジムリーダー名) -> 
	ld c, 4
.DrawBadge
	push de
	push hl

	; バッジ番号を描画([wBadgeNumberTile++] = [hl++])
	ld a, [wBadgeNumberTile]
	ld [hli], a
	inc a
	ld [wBadgeNumberTile], a

	; バッジ取得済みならジムリーダーの名前は描画しない
	ld a, [de]
	and a
	ld a, [wBadgeNameTile]
	jr nz, .SkipName
	; バッジ未取得ならジムリーダーの名前を描画する(英語版ROMでは空白を描画している)
	call .PlaceTiles
	jr .PlaceBadge

.SkipName
	inc a
	inc a
	inc hl

.PlaceBadge
	; [wBadgeNameTile]を次のバッジのために更新しておく  
	ld [wBadgeNameTile], a
	
	; バッジ番号の行 -> バッジの行
	ld de, SCREEN_WIDTH - 1
	add hl, de

	; バッジ(or 顔)を配置
	ld a, [wBadgeOrFaceTiles]
	call .PlaceTiles
	add hl, de	; 2行目
	call .PlaceTiles

	; wBadgeOrFaceTilesを前に1byteずらす
	push bc
	ld hl, wBadgeOrFaceTiles + 1
	ld de, wBadgeOrFaceTiles
	ld bc, 8
	call CopyData
	pop bc

	; hl = 次のバッジのタイルアドレス
	pop hl
	ld de, 4	; e.g. (2, 11) -> (6, 11)
	add hl, de

	; 次のバッジへ
	pop de
	inc de	; de = wTempObtainedBadgesBooleans + N
	dec c
	jr nz, .DrawBadge

	; 1行(4つ)描画し終えたら終了
	ret

.PlaceTiles
	; 2×1のタイルを配置
	ld [hli], a
	inc a	; [hl++] = a++
	ld [hl], a
	inc a	; [hl] = a++
	ret

; Tile ids for face/badge graphics.  
; $20 -> タケシの顔グラ  
; $24 -> グレーバッジのグラ  
; $28 -> カスミの顔グラ  
; ... 
.FaceBadgeTiles
	db $20, $28, $30, $38, $40, $48, $50, $58

GymLeaderFaceAndBadgeTileGraphics:
	INCBIN "gfx/badges.2bpp"
