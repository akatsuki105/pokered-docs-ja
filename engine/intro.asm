const_value = -1
	const MOVE_NIDORINO_RIGHT 	; -1
	const MOVE_GENGAR_RIGHT		; 0
	const MOVE_GENGAR_LEFT		; 1

ANIMATION_END EQU 80

const_value = 3
	const GENGAR_INTRO_TILES1	; 3
	const GENGAR_INTRO_TILES2	; 4
	const GENGAR_INTRO_TILES3	; 5

; **PlayIntro**  
; ゲーム起動時のアニメーションを流す  
; - - -  
; 画面真っ白 -> コピーライト -> ゲーフリロゴと流れ星 -> ゲンガーとニドリーノのアニメ -> 画面真っ白 までを担当する
PlayIntro:
	xor a
	ld [hJoyHeld], a 	; [hJoyHeld] = 0
	inc a
	ld [H_AUTOBGTRANSFERENABLED], a	; [H_AUTOBGTRANSFERENABLED] = 1
	call PlayShootingStar 			; コピーライト + ゲーフリロゴ
	call PlayIntroScene				; イントロアニメ(ゲンガーとニドリーノのやつ)
	; 終了処理をして return
	call GBFadeOutToWhite
	xor a
	ld [hSCX], a
	ld [H_AUTOBGTRANSFERENABLED], a
	call ClearSprites
	call DelayFrame
	ret

; ゲンガーとニドリーノが戦っているアニメーションを流す
PlayIntroScene:
	; SGB only
	ld b, SET_PAL_NIDORINO_INTRO
	call RunPaletteCommand
	
	; パレットを設定
	ldPal a, BLACK, DARK_GRAY, LIGHT_GRAY, WHITE
	ld [rBGP], a
	ld [rOBP0], a
	ld [rOBP1], a

	; SCX = 0
	xor a
	ld [hSCX], a

	; ゲンガーをBGとして画面右端に配置
	ld b, GENGAR_INTRO_TILES1
	call IntroCopyTiles

	; ニドリーノをスプライトとして(0px, 80px)配置
	ld a, 0
	ld [wBaseCoordX], a
	ld a, 80
	ld [wBaseCoordY], a
	lb bc, 6, 6
	call InitIntroNidorinoOAM

; ニドリーノを右に、ゲンガーを左にスライドさせる
	; d = 40, e = MOVE_NIDORINO_RIGHT(ゲンガーの移動も兼ねている)
	lb de, 80 / 2, MOVE_NIDORINO_RIGHT
	call IntroMoveMon
	ret c ; ユーザーのキー入力があったときはこの後のアニメーションをスキップする

; ニドリーノが左右にステップする1
; 左(ユーザーから見て右)
	ld a, SFX_INTRO_HIP
	call PlaySound
	xor a
	ld [wIntroNidorinoBaseTile], a
	ld de, IntroNidorinoAnimation1
	call AnimateIntroNidorino
; 右(ユーザーから見て左)
	ld a, SFX_INTRO_HOP
	call PlaySound
	ld de, IntroNidorinoAnimation2
	call AnimateIntroNidorino
	ld c, 10
	call CheckForUserInterruption
	ret c

; ニドリーノが左右にステップする2
; 左
	ld a, SFX_INTRO_HIP
	call PlaySound
	ld de, IntroNidorinoAnimation1
	call AnimateIntroNidorino
; 右
	ld a, SFX_INTRO_HOP
	call PlaySound
	ld de, IntroNidorinoAnimation2
	call AnimateIntroNidorino
	ld c, 30
	call CheckForUserInterruption
	ret c

; ゲンガーが右手をあげる
	ld b, GENGAR_INTRO_TILES2
	call IntroCopyTiles
	ld a, SFX_INTRO_RAISE
	call PlaySound
	lb de, 8 / 2, MOVE_GENGAR_LEFT
	call IntroMoveMon
	ld c, 30
	call CheckForUserInterruption
	ret c

; ゲンガーがあげた右手を振り下ろす
	ld b, GENGAR_INTRO_TILES3
	call IntroCopyTiles
	ld a, SFX_INTRO_CRASH
	call PlaySound
	lb de, 16 / 2, MOVE_GENGAR_RIGHT
	call IntroMoveMon

; ゲンガーの振り下ろしと同時にニドリーノがバックステップして振り下ろしをかわす
	ld a, SFX_INTRO_HIP
	call PlaySound
	ld a, (FightIntroFrontMon2 - FightIntroFrontMon) / BYTES_PER_TILE
	ld [wIntroNidorinoBaseTile], a
	ld de, IntroNidorinoAnimation3
	call AnimateIntroNidorino
	ld c, 30
	call CheckForUserInterruption
	ret c

; ゲンガーが振り下ろし状態から攻撃前の状態に戻る
	lb de, 8 / 2, MOVE_GENGAR_LEFT
	call IntroMoveMon
	ld b, GENGAR_INTRO_TILES1
	call IntroCopyTiles
	ld c, 60
	call CheckForUserInterruption
	ret c

; ニドリーノが左右にステップする3
; 左
	ld a, SFX_INTRO_HIP
	call PlaySound
	xor a
	ld [wIntroNidorinoBaseTile], a
	ld de, IntroNidorinoAnimation4
	call AnimateIntroNidorino
; 右
	ld a, SFX_INTRO_HOP
	call PlaySound
	ld de, IntroNidorinoAnimation5
	call AnimateIntroNidorino
	ld c, 20
	call CheckForUserInterruption
	ret c

; 噛みつきのための飛び上がり準備
	ld a, (FightIntroFrontMon2 - FightIntroFrontMon) / BYTES_PER_TILE
	ld [wIntroNidorinoBaseTile], a
	ld de, IntroNidorinoAnimation6
	call AnimateIntroNidorino
	ld c, 30
	call CheckForUserInterruption
	ret c

; 飛び上がって噛みつき
	ld a, SFX_INTRO_LUNGE
	call PlaySound
	ld a, (FightIntroFrontMon3 - FightIntroFrontMon) / BYTES_PER_TILE
	ld [wIntroNidorinoBaseTile], a
	ld de, IntroNidorinoAnimation7
	jp AnimateIntroNidorino ; ここで return

AnimateIntroNidorino:
	; 描画終了
	ld a, [de]
	cp ANIMATION_END
	ret z ;
	ld [wBaseCoordY], a
	inc de
	ld a, [de]
	ld [wBaseCoordX], a
	push de
	ld c, 6 * 6
	call UpdateIntroNidorinoOAM
	ld c, 5
	call DelayFrames
	pop de
	inc de
	jr AnimateIntroNidorino

; ニドリーノのOAMに (+[wBaseCoordX], +[wBaseCoordY])する
UpdateIntroNidorinoOAM:
	ld hl, wOAMBuffer
	ld a, [wIntroNidorinoBaseTile]
	ld d, a

.loop 
; {
	; Y += [wBaseCoordY]
	ld a, [wBaseCoordY]
	add [hl]
	ld [hli], a ; Y
	; X += [wBaseCoordX]
	ld a, [wBaseCoordX]
	add [hl]
	ld [hli], a ; X
	; update Tile
	ld a, d
	ld [hli], a ; tile
	inc hl
	inc d
	dec c
	jr nz, .loop 
; }
	ret

; (0px, 80px)から ニドリーノのスプライトを 6*6枚配置  
; 
; INPUT:  
; [wBaseCoordX] = 0  px
; [wBaseCoordY] = 80 px 
; b = 6  
; c = 6  
InitIntroNidorinoOAM:
	ld hl, wOAMBuffer
	ld d, 0

; {
.loop
	; 全列(6列)描画し終えるまで、1列描画のループ
	push bc
	ld a, [wBaseCoordY]
	ld e, a

.innerLoop ; {
	; 1列(6枚)描画し終えるまで、1枚描画のループ

	; Y = [wBaseCoordY]
	; [wBaseCoordY] += 8(1タイル分)
	ld a, e
	add 8
	ld e, a
	ld [hli], a

	; X = [wBaseCoordX]
	ld a, [wBaseCoordX]
	ld [hli], a

	; タイルID = d
	ld a, d
	ld [hli], a

	; attr = OAM_BEHIND_BG
	ld a, OAM_BEHIND_BG
	ld [hli], a

	inc d ; 次のタイル
	dec c
	jr nz, .innerLoop ; }

	ld a, [wBaseCoordX]
	add 8
	ld [wBaseCoordX], a
	pop bc
	dec b
	jr nz, .loop 
; }
	ret

IntroClearScreen:
	ld hl, vBGMap1
	ld bc, BG_MAP_WIDTH * SCREEN_HEIGHT
	jr IntroClearCommon

; 画面の上下の黒枠に挟まれた部分をクリアする
IntroClearMiddleOfScreen:
	coord hl, 0, 4
	ld bc, SCREEN_WIDTH * 10

IntroClearCommon:
	ld [hl], 0
	inc hl
	dec bc
	ld a, b
	or c
	jr nz, IntroClearCommon
	ret

IntroPlaceBlackTiles:
	ld a, 1
.loop
	ld [hli], a
	dec c
	jr nz, .loop
	ret

; INPUT:  
; d = ポケモンを動かす回数(1回ごとに2px動かす)  
; e = 動作タイプ(MOVE_NIDORINO_RIGHT or MOVE_GENGAR_LEFT or MOVE_GENGAR_RIGHT)  
; 
; OUTPUT:  
; carry = ユーザーのキー入力によってスキップされたときは carryがセットされている
IntroMoveMon:
	ld a, e
	
	; 動作タイプによって分岐
	cp MOVE_NIDORINO_RIGHT
	jr z, .moveNidorinoRight
	cp MOVE_GENGAR_LEFT
	jr z, .moveGengarLeft
	; MOVE_GENGAR_RIGHT のときは下に続く

; .moveGengarRight
	; 右に2pxスクロール
	ld a, [hSCX]
	dec a
	dec a
	jr .next

.moveNidorinoRight
	; ニドリーノのOAMを (+2, +0)する
	push de
	ld a, 2
	ld [wBaseCoordX], a
	xor a
	ld [wBaseCoordY], a
	ld c, 6 * 6
	call UpdateIntroNidorinoOAM
	pop de
	; 下に続く(? ニドリーノが動くときはゲンガーも動くから？)

.moveGengarLeft
	; 左に2pxスクロール
	ld a, [hSCX]
	inc a
	inc a
.next
	ld [hSCX], a
	push de
	ld c, 2
	call CheckForUserInterruption ; ユーザー入力があったときは carryを立ててreturn
	pop de
	ret c
	dec d
	jr nz, IntroMoveMon
	ret

; 画面(13, 7) からタイルを配置していく  
; b = GENGAR_INTRO_TILES1 or GENGAR_INTRO_TILES2 or GENGAR_INTRO_TILES3  
; GENGAR_INTRO_TILES は全部 7*7枚なので (13, 7)から配置すれば ゲンガーがぴったり画面右端に描画される  
IntroCopyTiles:
	coord hl, 13, 7 ; (13, 7) -> (20, 14)

; CopyTileIDsFromList_ZeroBaseTileID  
; TileIDListPointerTableのタイルのリストを画面上に配置していく  
; - - -  
; c = 0 で CopyTileIDsFromList を呼び出す  
; 
; INPUT:  
; b = TileIDListPointerTable のインデックス  
; hl = タイルを配置する場所 e.g. coord hl, 13, 7  
CopyTileIDsFromList_ZeroBaseTileID:
	ld c, 0
	predef_jump CopyTileIDsFromList

PlayMoveSoundB:
; unused
	predef GetMoveSoundB
	ld a, b
	jp PlaySound

; イントロアニメーションに必要なグラをVRAMに転送
LoadIntroGraphics:
	; ゲンガー
	ld hl, FightIntroBackMon
	ld de, vChars2
	ld bc, FightIntroBackMonEnd - FightIntroBackMon
	ld a, BANK(FightIntroBackMon)
	call FarCopyData2
	; ゲーフリのロゴ や 星
	ld hl, GameFreakIntro
	ld de, vChars2 + (FightIntroBackMonEnd - FightIntroBackMon)
	ld bc, GameFreakIntroEnd - GameFreakIntro
	ld a, BANK(GameFreakIntro)
	call FarCopyData2
	ld hl, GameFreakIntro
	ld de, vChars1
	ld bc, GameFreakIntroEnd - GameFreakIntro
	ld a, BANK(GameFreakIntro)
	call FarCopyData2
	; ニドリーノ
	ld hl, FightIntroFrontMon
	ld de, vChars0
	ld bc, FightIntroFrontMonEnd - FightIntroFrontMon
	ld a, BANK(FightIntroFrontMon)
	jp FarCopyData2

; コピーライトを表示したあと、ゲーフリのロゴと流れ星のアニメーションを流す  
; 最後にイントロアニメの準備をしてreturn  
PlayShootingStar:
	; コピーライト を 3秒間表示
	ld b, SET_PAL_GAME_FREAK_INTRO
	call RunPaletteCommand
	callba LoadCopyrightAndTextBoxTiles
	ldPal a, BLACK, DARK_GRAY, LIGHT_GRAY, WHITE
	ld [rBGP], a
	ld c, 180
	call DelayFrames

	; 画面をまっさらにする
	call ClearScreen
	
	; 画面上下に黒い枠を表示し、その間にイントロアニメの描画の準備を進める
	call DisableLCD
	xor a
	ld [wCurOpponent], a
	call IntroDrawBlackBars
	call LoadIntroGraphics
	call EnableLCD
	ld hl, rLCDC
	res 5, [hl]
	set 3, [hl]
	ld c, 64
	call DelayFrames

	; ゲーフリのロゴと流れ星のアニメーションを流す(予めVRAMに転送ずみ)
	callba AnimateShootingStar

	push af
	pop af

	; AnimateShootingStarで ユーザーが CheckForUserInterruptionのキー入力 でアニメーションに割り込んだときは遅延処理をスキップする
	jr c, .next
	ld c, 40
	call DelayFrames

.next
	; イントロアニメ(ゲンガーとニドリーノのやつ)の準備
	ld a, BANK(Music_IntroBattle)
	ld [wAudioROMBank], a
	ld [wAudioSavedROMBank], a
	ld a, MUSIC_INTRO_BATTLE
	ld [wNewSoundID], a
	call PlaySound
	call IntroClearMiddleOfScreen
	call ClearSprites
	jp Delay3	; return

IntroDrawBlackBars:
; clear the screen and draw black bars on the top and bottom
	call IntroClearScreen
	coord hl, 0, 0
	ld c, SCREEN_WIDTH * 4
	call IntroPlaceBlackTiles
	coord hl, 0, 14
	ld c, SCREEN_WIDTH * 4
	call IntroPlaceBlackTiles
	ld hl, vBGMap1
	ld c,  BG_MAP_WIDTH * 4
	call IntroPlaceBlackTiles
	ld hl, vBGMap1 + BG_MAP_WIDTH * 14
	ld c,  BG_MAP_WIDTH * 4
	jp IntroPlaceBlackTiles

EmptyFunc4:
	ret

IntroNidorinoAnimation0:
	db 0, 0
	db ANIMATION_END

IntroNidorinoAnimation1:
; This is a sequence of pixel movements for part of the Nidorino animation. This
; list describes how Nidorino should hop.
; First byte is y movement, second byte is x movement
	db  0, 0
	db -2, 2
	db -1, 2
	db  1, 2
	db  2, 2
	db ANIMATION_END

IntroNidorinoAnimation2:
; This is a sequence of pixel movements for part of the Nidorino animation.
; First byte is y movement, second byte is x movement
	db  0,  0
	db -2, -2
	db -1, -2
	db  1, -2
	db  2, -2
	db ANIMATION_END

IntroNidorinoAnimation3:
; This is a sequence of pixel movements for part of the Nidorino animation.
; First byte is y movement, second byte is x movement
	db   0, 0
	db -12, 6
	db  -8, 6
	db   8, 6
	db  12, 6
	db ANIMATION_END

IntroNidorinoAnimation4:
; This is a sequence of pixel movements for part of the Nidorino animation.
; First byte is y movement, second byte is x movement
	db  0,  0
	db -8, -4
	db -4, -4
	db  4, -4
	db  8, -4
	db ANIMATION_END

IntroNidorinoAnimation5:
; This is a sequence of pixel movements for part of the Nidorino animation.
; First byte is y movement, second byte is x movement
	db  0, 0
	db -8, 4
	db -4, 4
	db  4, 4
	db  8, 4
	db ANIMATION_END

IntroNidorinoAnimation6:
; This is a sequence of pixel movements for part of the Nidorino animation.
; First byte is y movement, second byte is x movement
	db 0, 0
	db 2, 0
	db 2, 0
	db 0, 0
	db ANIMATION_END

IntroNidorinoAnimation7:
; This is a sequence of pixel movements for part of the Nidorino animation.
; First byte is y movement, second byte is x movement
	db -8, -16
	db -7, -14
	db -6, -12
	db -4, -10
	db ANIMATION_END

GameFreakIntro:
	INCBIN "gfx/gamefreak_intro.2bpp"
	INCBIN "gfx/gamefreak_logo.2bpp"
	rept 16
	db $00 ; blank tile
	endr
GameFreakIntroEnd:

FightIntroBackMon:
	INCBIN "gfx/intro_fight.2bpp"
FightIntroBackMonEnd:

FightIntroFrontMon:

IF DEF(_RED)
	INCBIN "gfx/red/intro_nido_1.2bpp"
FightIntroFrontMon2:
	INCBIN "gfx/red/intro_nido_2.2bpp"
FightIntroFrontMon3:
	INCBIN "gfx/red/intro_nido_3.2bpp"
ENDC

IF DEF(_BLUE)
	INCBIN "gfx/blue/intro_purin_1.2bpp"
FightIntroFrontMon2:
	INCBIN "gfx/blue/intro_purin_2.2bpp"
FightIntroFrontMon3:
	INCBIN "gfx/blue/intro_purin_3.2bpp"
ENDC

FightIntroFrontMonEnd:

	ds $10 ; blank tile
