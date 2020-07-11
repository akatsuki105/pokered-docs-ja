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

; **OakSpeech**  
; オーキド博士のスピーチを行う  
; - - -  
; 『さいしょからはじめる』をスタートメニューで押した後から、スピーチが終わる(主人公の2階からゲーム開始)までをこの関数が担当する  
; 特にINPUT, OUTPUTは無し  
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

	; オーキド博士のグラを画面真ん中に配置
	ld de, ProfOakPic
	lb bc, Bank(ProfOakPic), $00
	call IntroDisplayPicCenteredOrUpperRight

	; オーキド博士のグラをフェードイン
	call FadeInIntroPic

	; OakSpeechText1 を表示
	ld hl, OakSpeechText1
	call PrintText

	; 画面を真っ白にする
	call GBFadeOutToWhite
	call ClearScreen

	; ニドリーノを左からスライドさせてくる
	ld a, NIDORINO
	ld [wd0b5], a
	ld [wcf91], a
	call GetMonHeader
	coord hl, 6, 4
	call LoadFlippedFrontSpriteByMonIndex
	call MovePicLeft ; ニドリーノはウィンドウとして描画されている?
	
	; OakSpeechText2 を表示
	ld hl, OakSpeechText2
	call PrintText

	; 画面を真っ白にする
	call GBFadeOutToWhite
	call ClearScreen

	; 主人公を左からスライドさせてくる
	ld de, RedPicFront
	lb bc, Bank(RedPicFront), $00
	call IntroDisplayPicCenteredOrUpperRight
	call MovePicLeft

	; 主人公の名前選択
	ld hl, IntroducePlayerText
	call PrintText
	call ChoosePlayerName 	; [wPlayerName] = 主人公の名前

	call GBFadeOutToWhite
	call ClearScreen
	
	; 次にライバルのグラを表示
	ld de, Rival1Pic
	lb bc, Bank(Rival1Pic), $00
	call IntroDisplayPicCenteredOrUpperRight
	call FadeInIntroPic

	; ライバルの名前選択
	ld hl, IntroduceRivalText
	call PrintText
	call ChooseRivalName	; [wRivalName] = ライバルの名前

.skipChoosingNames
	; 主人公のグラを表示
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
	; ここから主人公のグラをアイコンサイズに縮ませる処理
	
	; 縮むSE
	ld a, [H_LOADEDROMBANK]
	push af
	ld a, SFX_SHRINK
	call PlaySound
	pop af
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a

	ld c, 4
	call DelayFrames

	; 縮んだ後のRedSprite(主人公の16*16pxのアイコン)をVRAMに
	ld de, RedSprite
	ld hl, vSprites
	lb bc, BANK(RedSprite), $0C
	call CopyVideoData

	; 収縮途中のスプライト1 を表示
	ld de, ShrinkPic1
	lb bc, BANK(ShrinkPic1), $00
	call IntroDisplayPicCenteredOrUpperRight

	ld c, 4
	call DelayFrames

	; 収縮途中のスプライト2 を表示
	ld de, ShrinkPic2
	lb bc, BANK(ShrinkPic2), $00
	call IntroDisplayPicCenteredOrUpperRight

	call ResetPlayerSpriteData

	; マサラタウンのBGMを再生する準備
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

	; 画面をクリアしてreturn
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
	jp ClearScreen ; return

; "Hello there! Welcome to the world of #MON!"  
; "My name is OAK! People call me the #MON PROF!"  
OakSpeechText1:
	TX_FAR _OakSpeechText1
	db "@"

; "This world is inhabited by creatures called #MON!@@"  
; 『ニドリーナの鳴き声』  
; "For some people, #MON are pets."  
; "Others use them for fights."  
; "Myself... I study #MON as a profession."  
OakSpeechText2:
	TX_FAR _OakSpeechText2A
	TX_CRY_NIDORINA
	TX_FAR _OakSpeechText2B
	db "@"

; "First, what is your name?"
IntroducePlayerText:
	TX_FAR _IntroducePlayerText
	db "@"

; "This is my grand-son. He's been your rival since you were a baby."
; "...Erm, what is his name again?"
IntroduceRivalText:
	TX_FAR _IntroduceRivalText
	db "@"

; "\<PLAYER\>!"  
; "Your very own #MON legend is about to unfold!"  
; "A world of dreams and adventures with #MON awaits!"  
; "Let's go!"  
OakSpeechText3:
	TX_FAR _OakSpeechText3
	db "@"

; **FadeInIntroPic**
; イントロのグラのフェードイン処理
; - - -  
; 10フレームごとに BGPパレットを 以下のように変更する  
; 
; 0-10:  %01010100  
; 10-20: %10101000  
; 20-30: %11111100  
; 30-40: %11111000  
; 40-50: %11110100  
; 50-60: %11100100  
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

; **MovePicLeft**  
; グラフィックを左に動かす  
; WXを徐々に減らす、つまりウィンドウを左に動かすことで実現している
MovePicLeft:
	ld a, 119
	ld [rWX], a
	call DelayFrame

	; BGP = [3, 2, 1, 0]
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
	ld bc, $310	; 784 => 49 * 16 = 2bppで 49タイル分のグラフィックデータ
	call CopyData

	; sSpriteBuffer0 と sSpriteBuffer1 の1bppのデータを 2bppとして vFrontPicに配置
	; 今回は sSpriteBuffer1 を sSpriteBuffer0 にコピーしているので実質 1bpp
	ld de, vFrontPic
	call InterlaceMergeSpriteBuffers

	; hl = (15, 1)(右上) or (6, 4)(真ん中)
	pop bc
	ld a, c
	and a
	coord hl, 15, 1
	jr nz, .next
	coord hl, 6, 4
	; Uncompressedされたグラフィックデータ(7*7タイル)を hl のアドレスにコピーすることで描画
.next
	xor a
	ld [hStartTileID], a
	predef_jump CopyUncompressedPicToTilemap
