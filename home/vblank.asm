VBlank::

	push af
	push bc
	push de
	push hl

	ld a, [H_LOADEDROMBANK]
	ld [wVBlankSavedROMBank], a

	; HRAM　に格納してあった 擬似SCX, SCY を実際の SCX, SCY に格納
	ld a, [hSCX]
	ld [rSCX], a
	ld a, [hSCY]
	ld [rSCY], a

	; HRAM に格納してあった 擬似WY を実際の WY に格納 (wDisableVBlankWYUpdateフラグが立っていたらスキップ)
	ld a, [wDisableVBlankWYUpdate]
	and a
	jr nz, .ok
	ld a, [hWY]
	ld [rWY], a
	
.ok

	call AutoBgMapTransfer 		; wTileMap -> VRAM(?)への転送
	call VBlankCopyBgMap		; H_VBCOPYBGSRC -> H_VBCOPYBGDEST への転送
	call RedrawRowOrColumn		; BG1行(16px) or BG1列 (16px) を再描画
	call VBlankCopy				; H_VBCOPYSRC から H_VBCOPYDEST に [H_VBCOPYSIZE]タイル分の 2bpp データを転送する
	call VBlankCopyDouble		; H_VBCOPYDOUBLESRC から H_VBCOPYDOUBLEDEST に [H_VBCOPYDOUBLESIZE]タイル分の 2bppデータ(元は1bppデータ) を転送する
	call UpdateMovingBgTiles	; マップ上での花や水のアニメーション処理を行う
	call $ff80 					; hOAMDMA (DMARoutine)
	
	; 現在、可視化する必要がある スプライト(人や岩など)のOAMデータ を決定して、それを wOAMBuffer に書き込む
	ld a, BANK(PrepareOAMData)
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	call PrepareOAMData

	; VBlank-sensitive operations end.

	call Random

	ld a, [H_VBLANKOCCURRED]
	and a
	jr z, .skipZeroing
	xor a
	ld [H_VBLANKOCCURRED], a

.skipZeroing
	ld a, [H_FRAMECOUNTER]
	and a
	jr z, .skipDec
	dec a
	ld [H_FRAMECOUNTER], a

.skipDec
	call FadeOutAudio

	ld a, [wAudioROMBank] ; music ROM bank
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a

	cp BANK(Audio1_UpdateMusic)
	jr nz, .checkForAudio2
.audio1
	call Audio1_UpdateMusic
	jr .afterMusic
.checkForAudio2
	cp BANK(Audio2_UpdateMusic)
	jr nz, .audio3
.audio2
	call Music_DoLowHealthAlarm
	call Audio2_UpdateMusic
	jr .afterMusic
.audio3
	call Audio3_UpdateMusic
.afterMusic

	callba TrackPlayTime ; keep track of time played

	ld a, [hDisableJoypadPolling]
	and a
	call z, ReadJoypad

	ld a, [wVBlankSavedROMBank]
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a

	pop hl
	pop de
	pop bc
	pop af
	reti

; 次のVBlank割り込みがくるまでHALTする  
; 無駄にCPUを働かせずバッテリーを節約するため
DelayFrame::

NOT_VBLANKED EQU 1

	ld a, NOT_VBLANKED
	ld [H_VBLANKOCCURRED], a
.halt
	halt
	ld a, [H_VBLANKOCCURRED]
	and a
	jr nz, .halt
	ret
