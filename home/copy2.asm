; aバンクのhlが示すアドレスから(aバンクの)deが示すアドレスにbcバイトだけコピー  
; wBufferの代わりにhROMBankTempを使う以外はFarCopyDataと同じ
FarCopyData2::
	ld [hROMBankTemp], a
	ld a, [H_LOADEDROMBANK]
	push af
	ld a, [hROMBankTemp]
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	call CopyData
	pop af
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	ret

; aバンクのhlが示すアドレスから(aバンクの)deが示すアドレスにbcバイトだけコピー 
; 使われていない様子
FarCopyData3::
	ld [hROMBankTemp], a
	ld a, [H_LOADEDROMBANK]
	push af
	ld a, [hROMBankTemp]
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	push hl
	push de
	push de
	ld d, h
	ld e, l
	pop hl
	call CopyData
	pop de
	pop hl
	pop af
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	ret

; aバンクのhlが示すアドレスから(aバンクの)deが示すアドレスにbcバイトだけコピー 
; その際に[hl]の1bppフォーマットのデータを2bppのデータに変換している
FarCopyDataDouble::
	; ROMバンクの保存と切り替え
	ld [hROMBankTemp], a
	ld a, [H_LOADEDROMBANK]
	push af
	ld a, [hROMBankTemp]
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
.loop
	; 1bpp -> 2bppに変換
	ld a, [hli] 
	ld [de], a
	inc de
	ld [de], a
	inc de

	dec bc
	ld a, c
	or b
	jr nz, .loop

	; ROMバンクの復帰
	pop af
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	ret

; 次のVBlankを待ってc枚の2bppフォーマットのタイルデータをbバンクのdeからhlにコピーする  
; 一度の実行で8タイル分転送を行う  
; つまりすべてのタイルデータの転送にc/8フレームほどの時間を要する  
; 
; 転送はH_VBCOPYSRC, H_VBCOPYDEST, H_VBCOPYSIZEに転送元、転送先、転送サイズを入れておけばVBlank時にVBlankハンドラが転送してくれる
CopyVideoData::

	; コピー中はBGの自動転送を無効にする
	ld a, [H_AUTOBGTRANSFERENABLED]
	push af
	xor a 
	ld [H_AUTOBGTRANSFERENABLED], a
	
	; 元のROMバンクを退避
	ld a, [H_LOADEDROMBANK]
	ld [hROMBankTemp], a
	; bの示すバンクにスイッチ
	ld a, b
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a

	; コピー元を設定
	ld a, e
	ld [H_VBCOPYSRC], a
	ld a, d
	ld [H_VBCOPYSRC + 1], a

	; コピー先を設定
	ld a, l
	ld [H_VBCOPYDEST], a
	ld a, h
	ld [H_VBCOPYDEST + 1], a

.loop
	; c-8 >= 0 なら次のフレームでも転送続行
	ld a, c
	cp 8
	jr nc, .keepgoing

.done
	; 残りのタイルを転送
	ld [H_VBCOPYSIZE], a
	call DelayFrame			; 次のVBlankを待つ

	; バンクをもとに戻す
	ld a, [hROMBankTemp]
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a

	; BGの自動転送フラグを戻す
	pop af
	ld [H_AUTOBGTRANSFERENABLED], a
	ret

.keepgoing
	; 8タイル分転送
	ld a, 8
	ld [H_VBCOPYSIZE], a
	call DelayFrame

	; c -= 8(タイル)
	ld a, c
	sub 8
	ld c, a

	jr .loop

; 次のVBlankを待ってc枚の1bppフォーマットのタイルデータをbバンクのdeからhlにコピーする  
; 一度の実行で8タイル分転送を行う  
; つまりすべてのタイルデータの転送にc/8フレームほどの時間を要する  
; 
; 転送はH_VBCOPYDOUBLESRC, H_VBCOPYDOUBLEDEST, H_VBCOPYDOUBLESIZEに転送元、転送先、転送サイズを入れておけばVBlank時にVBlankハンドラが転送してくれる
CopyVideoDataDouble::
	ld a, [H_AUTOBGTRANSFERENABLED]
	push af
	xor a ; disable auto-transfer while copying
	ld [H_AUTOBGTRANSFERENABLED], a
	ld a, [H_LOADEDROMBANK]
	ld [hROMBankTemp], a

	ld a, b
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a

	ld a, e
	ld [H_VBCOPYDOUBLESRC], a
	ld a, d
	ld [H_VBCOPYDOUBLESRC + 1], a

	ld a, l
	ld [H_VBCOPYDOUBLEDEST], a
	ld a, h
	ld [H_VBCOPYDOUBLEDEST + 1], a

.loop
	ld a, c
	cp 8
	jr nc, .keepgoing

.done
	ld [H_VBCOPYDOUBLESIZE], a
	call DelayFrame
	ld a, [hROMBankTemp]
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	pop af
	ld [H_AUTOBGTRANSFERENABLED], a
	ret

.keepgoing
	ld a, 8
	ld [H_VBCOPYDOUBLESIZE], a
	call DelayFrame
	ld a, c
	sub 8
	ld c, a
	jr .loop

; hlを始点としてタイルマップを c*b枚だけクリア(空白タイルで上書き)する
ClearScreenArea::
	ld a, " " ; 空白のタイル
	ld de, 20 ; スクリーンサイズ
.y
	push hl
	push bc
.x
	; 1行分をクリア
	ld [hli], a
	dec c
	jr nz, .x

	; タイルアドレスとy座標を1行分進める
	pop bc
	pop hl
	add hl, de
	dec b

	; 次の行へ
	jr nz, .y
	ret

; 
CopyScreenTileBufferToVRAM::
; Copy wTileMap to the BG Map starting at b * $100.
; This is done in thirds of 6 rows, so it takes 3 frames.

	ld c, 6

	ld hl, $600 * 0
	coord de, 0, 6 * 0
	call .setup
	call DelayFrame

	ld hl, $600 * 1
	coord de, 0, 6 * 1
	call .setup
	call DelayFrame

	ld hl, $600 * 2
	coord de, 0, 6 * 2
	call .setup
	jp DelayFrame

.setup
	ld a, d
	ld [H_VBCOPYBGSRC+1], a
	call GetRowColAddressBgMap
	ld a, l
	ld [H_VBCOPYBGDEST], a
	ld a, h
	ld [H_VBCOPYBGDEST+1], a
	ld a, c
	ld [H_VBCOPYBGNUMROWS], a
	ld a, e
	ld [H_VBCOPYBGSRC], a
	ret

ClearScreen::
; Clear wTileMap, then wait
; for the bg map to update.
	ld bc, 20 * 18
	inc b
	coord hl, 0, 0
	ld a, " "
.loop
	ld [hli], a
	dec c
	jr nz, .loop
	dec b
	jr nz, .loop
	jp Delay3
