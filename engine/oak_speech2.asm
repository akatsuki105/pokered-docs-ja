ChoosePlayerName:
	; 名前メニュー表示のために主人公を真ん中から少し右にずらす
	call OakSpeechSlidePicRight

	ld de, DefaultNamesPlayer
	call DisplayIntroNameTextBox
	ld a, [wCurrentMenuItem]
	and a
	jr z, .customName
	ld hl, DefaultNamesPlayerList
	call GetDefaultName
	ld de, wPlayerName
	call OakSpeechSlidePicLeft
	jr .done
.customName
	ld hl, wPlayerName
	xor a ; NAME_PLAYER_SCREEN
	ld [wNamingScreenType], a
	call DisplayNamingScreen
	ld a, [wcf4b]
	cp "@"
	jr z, .customName
	call ClearScreen
	call Delay3
	ld de, RedPicFront
	ld b, BANK(RedPicFront)
	call IntroDisplayPicCenteredOrUpperRight
.done
	ld hl, YourNameIsText
	jp PrintText

YourNameIsText:
	TX_FAR _YourNameIsText
	db "@"

ChooseRivalName:
	call OakSpeechSlidePicRight
	ld de, DefaultNamesRival
	call DisplayIntroNameTextBox
	ld a, [wCurrentMenuItem]
	and a
	jr z, .customName
	ld hl, DefaultNamesRivalList
	call GetDefaultName
	ld de, wRivalName
	call OakSpeechSlidePicLeft
	jr .done
.customName
	ld hl, wRivalName
	ld a, NAME_RIVAL_SCREEN
	ld [wNamingScreenType], a
	call DisplayNamingScreen
	ld a, [wcf4b]
	cp "@"
	jr z, .customName
	call ClearScreen
	call Delay3
	ld de, Rival1Pic
	ld b, $13
	call IntroDisplayPicCenteredOrUpperRight
.done
	ld hl, HisNameIsText
	jp PrintText

HisNameIsText:
	TX_FAR _HisNameIsText
	db "@"

OakSpeechSlidePicLeft:
	push de
	coord hl, 0, 0
	lb bc, 12, 11
	call ClearScreenArea ; clear the name list text box
	ld c, 10
	call DelayFrames
	pop de
	ld hl, wcd6d
	ld bc, NAME_LENGTH
	call CopyData
	call Delay3
	coord hl, 12, 4
	lb de, 6, 6 * SCREEN_WIDTH + 5
	ld a, $ff
	jr OakSpeechSlidePicCommon

; 名前メニュー表示のために主人公(ライバル)を真ん中から少し右にずらす
OakSpeechSlidePicRight:
	coord hl, 5, 4 ; (5, 4)からスライド 
	lb de, 6, 6 * SCREEN_WIDTH + 5 ; d = 6(6回スライド), e = 6 * SCREEN_WIDTH + 5(各スライドで6行 + 5タイル動かす)
	xor a ; 右スライド

; **OakSpeechSlidePicCommon**  
; 名前メニュー表示のために主人公(ライバル)を真ん中から少し右(左)にずらす  
; - - -  
; INPUT:  
; - a = -1(左スライド) or 0(右スライド)  
; - d = スライド処理を何回行うか  
; - e = 各スライド処理で動かすタイル数  
; - hl = スライドの始点となるタイルアドレス e.g. coord hl, 5, 4
OakSpeechSlidePicCommon:
	push hl
	push de
	push bc
	ld [hSlideDirection], a
	
	ld a, d
	ld [hSlideAmount], a
	
	ld a, e
	ld [hSlidingRegionSize], a
	ld c, a
	
	; de = hl = タイルずらし作業の始点
	ld a, [hSlideDirection]
	and a
	jr nz, .next
	ld d, 0
	add hl, de ; 右スライドの場合は、HLがpicのタイルの終端を指すようにする
.next
	ld d, h
	ld e, l

; [hl]から[hl+c]まで、1つずつずらす (+-はスライド方向による) つまり タイルを1つずつずらしていく
.loop
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a
	ld a, [hSlideDirection]
	and a
	jr nz, .slideLeft
; .slideRight
	; [hl + 1] = [hl] && hl-- つまり [hl]を +1方向にずらしていく
	ld a, [hli]
	ld [hld], a
	dec hl
	jr .next2
.slideLeft
	; [hl-1] = [hl] && hl++ つまり [hl] を -1方向にずらしていく
	ld a, [hld]
	ld [hli], a
	inc hl
.next2
	dec c
	jr nz, .loop ; c回ループする

	ld a, [hSlideDirection]
	and a
	jr z, .next3
	; 左にスライドしているときは、picの最後のタイル(hlが指している)を0クリアする必要がある
	; 右にスライドするときは hlは 既に0タイルを指しているのでその必要はない
	xor a
	dec hl
	ld [hl], a

.next3
	ld a, 1
	ld [H_AUTOBGTRANSFERENABLED], a
	call Delay3

	; c = グラの各スライド処理で動かすタイル数
	ld a, [hSlidingRegionSize]
	ld c, a
	
	; hl = ずらし処理の始点
	ld h, d
	ld l, e
	
	; hl = hl + 1 or hl - 1
	ld a, [hSlideDirection]
	and a
	jr nz, .slideLeft2
	inc hl
	jr .next4
.slideLeft2
	dec hl

.next4
	ld d, h
	ld e, l
	ld a, [hSlideAmount]
	dec a
	ld [hSlideAmount], a
	jr nz, .loop
	pop bc
	pop de
	pop hl
	ret

DisplayIntroNameTextBox:
	push de

	; デフォルトの名前メニュー用のテキストボックスを描画
	coord hl, 0, 0
	ld b, $a
	ld c, $9
	call TextBoxBorder

	; 『NAME』(なまえこうほ)という文字をテキストボックスの枠の上に描画
	coord hl, 3, 0
	ld de, .namestring
	call PlaceString

	; 名前候補一覧をテキストボックスにメニューのアイテムとして配置
	pop de
	coord hl, 2, 2
	call PlaceString ; @が来るまで配置

	call UpdateSprites
	
	; メニューにかかわる変数を初期化してキー入力を待つ
	xor a
	ld [wCurrentMenuItem], a
	ld [wLastMenuItem], a
	inc a
	ld [wTopMenuItemX], a
	ld [wMenuWatchedKeys], a ; A_BUTTON
	inc a
	ld [wTopMenuItemY], a
	inc a
	ld [wMaxMenuItem], a
	jp HandleMenuInput

; "なまえこうほ"
.namestring
	db "NAME@"

IF DEF(_RED)
; [NEW NAME, RED, ASH, JACK]
DefaultNamesPlayer:
	db   "NEW NAME"
	next "RED"
	next "ASH"
	next "JACK"
	db   "@"

; [NEW NAME, BLUE, GARY, JOHN]
DefaultNamesRival:
	db   "NEW NAME"
	next "BLUE"
	next "GARY"
	next "JOHN"
	db   "@"
ENDC

IF DEF(_BLUE)
; [NEW NAME, BLUE, GARY, JOHN]
DefaultNamesPlayer:
	db   "NEW NAME"
	next "BLUE"
	next "GARY"
	next "JOHN"
	db   "@"

; [NEW NAME, RED, ASH, JACK]
DefaultNamesRival:
	db   "NEW NAME"
	next "RED"
	next "ASH"
	next "JACK"
	db   "@"
ENDC

GetDefaultName:
; a = name index
; hl = name list
	ld b, a
	ld c, 0
.loop
	ld d, h
	ld e, l
.innerLoop
	ld a, [hli]
	cp "@"
	jr nz, .innerLoop
	ld a, b
	cp c
	jr z, .foundName
	inc c
	jr .loop
.foundName
	ld h, d
	ld l, e
	ld de, wcd6d
	ld bc, $14
	jp CopyData

IF DEF(_RED)
DefaultNamesPlayerList:
	db "NEW NAME@"
	db "RED@"
	db "ASH@"
	db "JACK@"
DefaultNamesRivalList:
	db "NEW NAME@"
	db "BLUE@"
	db "GARY@"
	db "JOHN@"
ENDC
IF DEF(_BLUE)
DefaultNamesPlayerList:
	db "NEW NAME@"
	db "BLUE@"
	db "GARY@"
	db "JOHN@"
DefaultNamesRivalList:
	db "NEW NAME@"
	db "RED@"
	db "ASH@"
	db "JACK@"
ENDC

TextTerminator_6b20:
	db "@"
