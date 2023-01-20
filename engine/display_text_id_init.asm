; DisplayTextIDの初期化処理
DisplayTextIDInit:
	; wListMenuID = 0
	xor a
	ld [wListMenuID], a
	
	; wAutoTextBoxDrawingControlのbit0が1ならテキストボックスを描画
	ld a, [wAutoTextBoxDrawingControl]
	bit 0, a
	jr nz, .skipDrawingTextBoxBorder

	; テキストIDが0ならスタートメニュー
	ld a, [hSpriteIndexOrTextID] ; テキストID (または スプライトID)
	and a
	jr nz, .notStartMenu

; テキストIDが0のとき (例: スタートメニュー)
; スタートメニューの枠線は直下の関数で描画されるのでこれは不要に見えることに注意
; Note that the start menu text border is also drawn in the function directly
; below this, so this seems unnecessary.

	; ポケモン図鑑取得のイベントを消化しているかによって枠線の描画処理が変わる
	CheckEvent EVENT_GOT_POKEDEX
	; ポケモン図鑑取得後
	coord hl, 10, 0
	ld b, $0e
	ld c, $08
	jr nz, .drawTextBoxBorder
	; ポケモン図鑑取得前
	coord hl, 10, 0
	ld b, $0c				; POKEDEXの欄がない分、枠線の高さが小さい
	ld c, $08
	jr .drawTextBoxBorder

; テキストIDが0でないなら、通常のテキストボックスを描画
.notStartMenu
	coord hl, 0, 12
	ld b, $04
	ld c, $12

; テキストボックスを描画
.drawTextBoxBorder
	call TextBoxBorder

.skipDrawingTextBoxBorder
	; プレイヤーやNPCの移動を無効化
	ld hl, wFontLoaded
	set 0, [hl]
	
	; wFlags_0xcd60のbit 4をチェックしてクリア
	ld hl, wFlags_0xcd60
	bit 4, [hl]
	res 4, [hl]					; bit 4をクリア
	jr nz, .skipMovingSprites	; bit 4が1なら

	call UpdateSprites

; loop to copy C1X9 (direction the sprite is facing) to C2X9 for each sprite
; this is done because when you talk to an NPC, they turn to look your way
; the original direction they were facing must be restored after the dialogue is over 
.skipMovingSprites
	ld hl, wSpriteStateData1 + $19
	ld c, $0f
	ld de, $0010

.spriteFacingDirectionCopyLoop
	ld a, [hl]
	inc h
	ld [hl], a
	dec h
	add hl, de
	dec c
	jr nz, .spriteFacingDirectionCopyLoop
; loop to force all the sprites in the middle of animation to stand still
; (so that they don't like they're frozen mid-step during the dialogue)
	ld hl, wSpriteStateData1 + 2
	ld de, $0010
	ld c, e
.spriteStandStillLoop
	ld a, [hl]
	cp $ff ; is the sprite visible?
	jr z, .nextSprite
; if it is visible
	and $fc
	ld [hl], a
.nextSprite
	add hl, de
	dec c
	jr nz, .spriteStandStillLoop
	ld b, $9c ; window background address
	call CopyScreenTileBufferToVRAM ; transfer background in WRAM to VRAM
	xor a
	ld [hWY], a ; put the window on the screen
	call LoadFontTilePatterns
	ld a, $01
	ld [H_AUTOBGTRANSFERENABLED], a ; enable continuous WRAM to VRAM transfer each V-blank
	ret
