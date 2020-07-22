; A,B,Start,Selectなどが押されたときのReset処理  
; 音を消して、画面を真っ白にした後、Init処理からゲームをリスタートする
SoftReset::
	call StopAllSounds 	; 音を停止
	call GBPalWhiteOut	; 画面を真っ白に
	ld c, 32
	call DelayFrames
	; Init処理に続く

; **Init**  
; ここからゲームの起動が始まる  
; - - -  
; ここにジャンプしてくるのは  
; - ハード起動時のStart関数  
; - 殿堂入り後
; - etc...
Init::

; ゲーム起動時の LCDC の状態
; * LCD は有効
; * ウィンドウの tile mapのアドレスは $9C00
; * ウィンドウ は有効
; * BG and window tile data at $8800
; * BG tile map at $9800
; * OAM のサイズは 8x8
; * OAM の表示は有効
; * BG の表示は有効
rLCDC_DEFAULT EQU %11100011

	di

	; 各レジスタの初期化
	xor a
	ld [rIF], a
	ld [rIE], a
	ld [rSCX], a
	ld [rSCY], a
	ld [rSB], a
	ld [rSC], a
	ld [rWX], a
	ld [rWY], a
	ld [rTMA], a
	ld [rTAC], a
	ld [rBGP], a
	ld [rOBP0], a
	ld [rOBP1], a

	; LCDCを無効に
	ld a, rLCDC_ENABLE_MASK
	ld [rLCDC], a
	call DisableLCD

	ld sp, wStack ; spのスタートポイント = 0xdfff

	ld hl, $c000 ; WRAM のスタートポイント
	ld bc, $2000 ; WRAM のサイズ

; WRAMを 0クリアする
.loop
; {
	ld [hl], 0
	inc hl
	dec bc
	ld a, b
	or c
	jr nz, .loop
; }

; VRAM を 0クリア
	call ClearVram

; HRAM を 0クリア
	ld hl, $ff80
	ld bc, $ffff - $ff80
	call FillMemory

; wOAMBuffer を 0クリア
	call ClearSprites

; DMARoutine を設定
	ld a, Bank(WriteDMACodeToHRAM)
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	call WriteDMACodeToHRAM

; 画面に関するレジスタを 0クリア
	xor a
	ld [hTilesetType], a
	ld [rSTAT], a
	ld [hSCX], a
	ld [hSCY], a

; VBlank + Timer + Serial 割り込みを許可(IMEが0なので割り込みはこの時点では生じない)
	ld [rIF], a
	ld a, 1 << VBLANK + 1 << TIMER + 1 << SERIAL
	ld [rIE], a

; ウィンドウを非表示に
	ld a, 144
	ld [hWY], a
	ld [rWY], a
	ld a, 7
	ld [rWX], a

; シリアル通信のコネクションを非確立状態にする
	ld a, CONNECTION_NOT_ESTABLISHED
	ld [hSerialConnectionStatus], a

; VRAM を0クリア
	ld h, vBGMap0 / $100
	call ClearBgMap
	ld h, vBGMap1 / $100
	call ClearBgMap

; ここで初めて LCDCを有効化
	ld a, rLCDC_DEFAULT
	ld [rLCDC], a

; [hSoftReset] = 16
	ld a, 16
	ld [hSoftReset], a 
	call StopAllSounds

; IMEを有効にして割り込みを許可する
; VBlank + Timer + Serial 割り込みが IEで許可されている
	ei

	predef LoadSGB

	; イントロの流れ星のサウンドを準備
	ld a, BANK(SFX_Shooting_Star)
	ld [wAudioROMBank], a
	ld [wAudioSavedROMBank], a

	; VRAM転送先 = 0x9c00
	ld a, $9c
	ld [H_AUTOBGTRANSFERDEST + 1], a
	xor a
	ld [H_AUTOBGTRANSFERDEST], a
	; スプライトを無効化
	dec a ; a = 0xff
	ld [wUpdateSpritesEnabled], a

	; ゲーム起動時のアニメーションを流す
	predef PlayIntro

	; 画面を真っ白にして、再度有効化
	call DisableLCD
	call ClearVram
	call GBPalNormal
	call ClearSprites
	ld a, rLCDC_DEFAULT
	ld [rLCDC], a

	; タイトル画面へ
	; TODO: 名前はデフォルトでいいの？
	jp SetDefaultNamesBeforeTitlescreen

; VRAMを 0 クリア
ClearVram:
	ld hl, $8000
	ld bc, $2000
	xor a
	jp FillMemory


; **StopAllSounds**  
; BGMやSEの再生を即座に停止する  
StopAllSounds::
	ld a, BANK(Audio1_UpdateMusic)
	ld [wAudioROMBank], a
	ld [wAudioSavedROMBank], a
	xor a
	ld [wAudioFadeOutControl], a
	ld [wNewSoundID], a
	ld [wLastMusicSoundID], a
	dec a
	jp PlaySound
