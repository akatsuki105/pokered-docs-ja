; ゲームに関する変数を初期化した後で、プレイヤーとライバルの名前にデフォルトネーム(NINTEN, SONY)を設定する
SetDefaultNames:
	; [wLetterPrintingDelayFlags], [wOptions], [wd732]を退避
	ld a, [wLetterPrintingDelayFlags]
	push af
	ld a, [wOptions]
	push af
	ld a, [wd732]
	push af

	; wPlayerName から wBoxDataEnd までを0クリア
	ld hl, wPlayerName
	ld bc, wBoxDataEnd - wPlayerName
	xor a
	call FillMemory

	; スプライトデータをクリア
	ld hl, wSpriteStateData1
	ld bc, $200 ; wSpriteStateData1の始まりからwSpriteStateData2の終わりまで
	xor a
	call FillMemory

	; 関数の最初で退避した[wLetterPrintingDelayFlags], [wOptions], [wd732]を復帰
	pop af
	ld [wd732], a
	pop af
	ld [wOptions], a
	pop af
	ld [wLetterPrintingDelayFlags], a

	; [wOptionsInitialized] == 0 -> InitOptions
	ld a, [wOptionsInitialized]
	and a
	call z, InitOptions

	; 自分の名前を NINTEN にする
	ld hl, NintenText
	ld de, wPlayerName
	ld bc, NAME_LENGTH
	call CopyData
	; ライバルの名前を SONY にする
	ld hl, SonyText
	ld de, wRivalName
	ld bc, NAME_LENGTH
	jp CopyData

OakSpeech:
	ld a, $FF
	call PlaySound ; BGMを止める

	; オーキドのスピーチのBGMを再生
	ld a, BANK(Music_Routes2)
	ld c, a
	ld a, MUSIC_ROUTES2
	call PlayMusic

	; 画面描画の準備
	call ClearScreen
	call LoadTextBoxTilePatterns
	
	; プレイヤーデータを初期化 
	call SetDefaultNames
	predef InitPlayerData2

	; プレイヤーのPCBoxに『キズぐすり』を1つ入れておく
	ld hl, wNumBoxItems
	ld a, POTION
	ld [wcf91], a
	ld a, 1
	ld [wItemQuantity], a
	call AddItemToInventory  ; give one potion

	; [wDefaultMap](FirstMapSpec, 主人公の家の2階)へ主人公をwarpさせておく
	ld a, [wDefaultMap]
	ld [wDestinationMap], a
	call SpecialWarpIn
	xor a
	ld [hTilesetType], a

	; デバッグモード -> .skipChoosingNames
	ld a, [wd732]
	bit 1, a ; possibly a debug mode bit
	jp nz, .skipChoosingNames

	; ここからオーキド博士のスピーチが始まり、主人公とライバルの名前を入力してもらう処理を行う  

	ld de, ProfOakPic
	lb bc, Bank(ProfOakPic), $00
	call IntroDisplayPicCenteredOrUpperRight

	call FadeInIntroPic
	ld hl, OakSpeechText1
	call PrintText
	call GBFadeOutToWhite
	call ClearScreen
	ld a, NIDORINO
	ld [wd0b5], a
	ld [wcf91], a
	call GetMonHeader
	coord hl, 6, 4
	call LoadFlippedFrontSpriteByMonIndex
	call MovePicLeft
	ld hl, OakSpeechText2
	call PrintText
	call GBFadeOutToWhite
	call ClearScreen
	ld de, RedPicFront
	lb bc, Bank(RedPicFront), $00
	call IntroDisplayPicCenteredOrUpperRight
	call MovePicLeft
	ld hl, IntroducePlayerText
	call PrintText
	call ChoosePlayerName
	call GBFadeOutToWhite
	call ClearScreen
	ld de, Rival1Pic
	lb bc, Bank(Rival1Pic), $00
	call IntroDisplayPicCenteredOrUpperRight
	call FadeInIntroPic
	ld hl, IntroduceRivalText
	call PrintText
	call ChooseRivalName

.skipChoosingNames
	call GBFadeOutToWhite
	call ClearScreen
	ld de, RedPicFront
	lb bc, Bank(RedPicFront), $00
	call IntroDisplayPicCenteredOrUpperRight
	call GBFadeInFromWhite
	ld a, [wd72d]
	and a
	jr nz, .next
	ld hl, OakSpeechText3
	call PrintText
.next
	ld a, [H_LOADEDROMBANK]
	push af
	ld a, SFX_SHRINK
	call PlaySound
	pop af
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	ld c, 4
	call DelayFrames
	ld de, RedSprite
	ld hl, vSprites
	lb bc, BANK(RedSprite), $0C
	call CopyVideoData
	ld de, ShrinkPic1
	lb bc, BANK(ShrinkPic1), $00
	call IntroDisplayPicCenteredOrUpperRight
	ld c, 4
	call DelayFrames
	ld de, ShrinkPic2
	lb bc, BANK(ShrinkPic2), $00
	call IntroDisplayPicCenteredOrUpperRight
	call ResetPlayerSpriteData
	ld a, [H_LOADEDROMBANK]
	push af
	ld a, BANK(Music_PalletTown)
	ld [wAudioROMBank], a
	ld [wAudioSavedROMBank], a
	ld a, 10
	ld [wAudioFadeOutControl], a
	ld a, $FF
	ld [wNewSoundID], a
	call PlaySound ; stop music
	pop af
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	ld c, 20
	call DelayFrames
	coord hl, 6, 5
	ld b, 7
	ld c, 7
	call ClearScreenArea
	call LoadTextBoxTilePatterns
	ld a, 1
	ld [wUpdateSpritesEnabled], a
	ld c, 50
	call DelayFrames
	call GBFadeOutToWhite
	jp ClearScreen
OakSpeechText1:
	TX_FAR _OakSpeechText1
	db "@"
OakSpeechText2:
	TX_FAR _OakSpeechText2A
	TX_CRY_NIDORINA
	TX_FAR _OakSpeechText2B
	db "@"
IntroducePlayerText:
	TX_FAR _IntroducePlayerText
	db "@"
IntroduceRivalText:
	TX_FAR _IntroduceRivalText
	db "@"
OakSpeechText3:
	TX_FAR _OakSpeechText3
	db "@"

FadeInIntroPic:
	ld hl, IntroFadePalettes
	ld b, 6
.next
	ld a, [hli]
	ld [rBGP], a
	ld c, 10
	call DelayFrames
	dec b
	jr nz, .next
	ret

IntroFadePalettes:
	db %01010100
	db %10101000
	db %11111100
	db %11111000
	db %11110100
	db %11100100

MovePicLeft:
	ld a, 119
	ld [rWX], a
	call DelayFrame

	ld a, %11100100
	ld [rBGP], a
.next
	call DelayFrame
	ld a, [rWX]
	sub 8
	cp $FF
	ret z
	ld [rWX], a
	jr .next

; **DisplayPicCenteredOrUpperRight**  
; 引数で指定したpicを画面の真ん中か右上に配置する  
; - - -  
; IntroDisplayPicCenteredOrUpperRightをfarcallで呼び出したい場合にこれをpredefで呼び出す
; b = 圧縮されたpicのあるバンク番号  
; c = 0 (真ん中) or 0以外(右上)  
; de = 圧縮されたpicのアドレス  
DisplayPicCenteredOrUpperRight:
	call GetPredefRegisters
; **IntroDisplayPicCenteredOrUpperRight**  
; 引数で指定したpicを画面の真ん中か右上に配置する  
; - - -  
; b = バンク番号  
; c = 0 (真ん中) or 0以外(右上)  
; de = 圧縮されたpicのアドレス  
IntroDisplayPicCenteredOrUpperRight:
	; 圧縮されたpicデータを解凍
	push bc
	ld a, b
	call UncompressSpriteFromDE ; DisplayPicCenteredOrUpperRightで解凍するpicは sSpriteBuffer1に解凍結果が入ることになっている

	; 解凍結果の入った sSpriteBuffer1 から sSpriteBuffer0 に 784バイト コピー
	ld hl, sSpriteBuffer1
	ld de, sSpriteBuffer0
	ld bc, $310	; 784
	call CopyData

	ld de, vFrontPic
	call InterlaceMergeSpriteBuffers
	pop bc
	ld a, c
	and a
	coord hl, 15, 1
	jr nz, .next
	coord hl, 6, 4
.next
	xor a
	ld [hStartTileID], a
	predef_jump CopyUncompressedPicToTilemap
