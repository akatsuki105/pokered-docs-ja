; **DisplayPCMainMenu**  
; PCのメニューを画面に表示する  
; - - -  
; メニューのテキストボックスを表示して、カーソルを一番上に表示するところまでを行う  
; ゲームの進行状況によって表示内容が変わる  
; 
; ![image](https://imgur.com/DrqGbC6.png)
DisplayPCMainMenu::
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a

	; BillsPCMenu などで使うので現在のPCを開く前の画面の状況を保存
	call SaveScreenTilesToBuffer2

	; 殿堂入りしたことがある -> .leaguePCAvailable
	ld a, [wNumHoFTeams]
	and a
	jr nz, .leaguePCAvailable

	; ポケモン図鑑取得イベントを消化していない -> .noOaksPC
	CheckEvent EVENT_GOT_POKEDEX
	jr z, .noOaksPC

	; 上と同じ処理??
	ld a, [wNumHoFTeams]
	and a
	jr nz, .leaguePCAvailable

; 表示するメニューの項目数によってテキストボックスの大きさを変える
	coord hl, 0, 0
	ld b, 8
	ld c, 14
	jr .next
.noOaksPC
	coord hl, 0, 0
	ld b, 6
	ld c, 14
	jr .next
.leaguePCAvailable
	coord hl, 0, 0
	ld b, 10
	ld c, 14

	; テキストボックスを描画
.next
	call TextBoxBorder

	call UpdateSprites
	ld a, 3
	ld [wMaxMenuItem], a

	; メニューの1番上の項目に "BILL's PC" か "SOMEONE's PC" を配置 (マサキとのイベントを消化済みかで変わる)
	CheckEvent EVENT_MET_BILL
	jr nz, .metBill
	coord hl, 2, 2
	ld de, SomeonesPCText
	jr .next2
.metBill
	coord hl, 2, 2
	ld de, BillsPCText
.next2
	call PlaceString

	; メニューの2番目の項目に<Player>'s PC
	coord hl, 2, 4
	ld de, wPlayerName
	call PlaceString
	ld l, c
	ld h, b
	ld de, PlayersPCText
	call PlaceString

	; 次の項目に "PROF.OAK's PC" (図鑑取得済みのみ)
	CheckEvent EVENT_GOT_POKEDEX
	jr z, .noOaksPC2
	coord hl, 2, 6
	ld de, OaksPCText
	call PlaceString

	; 次の項目に "Pokemon LEAGUE" (殿堂入りしたことがある場合のみ)
	ld a, [wNumHoFTeams]
	and a
	jr z, .noLeaguePC
	ld a, 4
	ld [wMaxMenuItem], a
	coord hl, 2, 8
	ld de, PKMNLeaguePCText
	call PlaceString

; 自分の状況に応じて適した位置に "LOG OFF"
	coord hl, 2, 10
	ld de, LogOffPCText
	jr .next3
.noLeaguePC
	coord hl, 2, 8
	ld de, LogOffPCText
	jr .next3
.noOaksPC2
	ld a, $2
	ld [wMaxMenuItem], a
	coord hl, 2, 6
	ld de, LogOffPCText
.next3
	call PlaceString

; メニューにカーソルを配置
	ld a, A_BUTTON | B_BUTTON
	ld [wMenuWatchedKeys], a
	ld a, 2
	ld [wTopMenuItemY], a
	ld a, 1
	ld [wTopMenuItemX], a
	xor a
	ld [wCurrentMenuItem], a
	ld [wLastMenuItem], a

	; 終了
	ld a, 1
	ld [H_AUTOBGTRANSFERENABLED], a
	ret

SomeonesPCText:   db "SOMEONE's PC@"	; "SOMEONE's PC"  
BillsPCText:      db "BILL's PC@"		; "BILL's PC"
PlayersPCText:    db "'s PC@"			; "'s PC"
OaksPCText:       db "PROF.OAK's PC@"	; "PROF.OAK's PC"
PKMNLeaguePCText: db $4a, "LEAGUE@"		; "Pokemon LEAGUE"
LogOffPCText:     db "LOG OFF@"			; "LOG OFF"

; **BillsPC_**  
; PCで "BILL's PC" を選んだときの処理
BillsPC_::
	; テキスト表示に遅延を設定
	ld hl, wd730
	set 6, [hl]

	; [wParentMenuItem] = BILL's PC
	xor a							; BILL's PC
	ld [wParentMenuItem], a
	; [wNameListType] = MONSTER_NAME
	inc a               			; MONSTER_NAME
	ld [wNameListType], a
	call LoadHpBarAndStatusTilePatterns

	; push [wListScrollOffset](マサキのPCはメインメニューの一番上なので おそらく0)
	ld a, [wListScrollOffset]
	push af
	
	; 普通のPC(ポケセンのPCなど)で "BILL's PC" を選んだ場合 -> BillsPCMenu
	ld a, [wFlags_0xcd60]
	bit 3, a
	jr nz, BillsPCMenu

	; マサキのパソコンを使った場合 "Switch on!"
	ld a, SFX_TURN_ON_PC
	call PlaySound
	ld hl, SwitchOnText
	call PrintText

; **BillsPCMenu**  
; ![image](https://imgur.com/Deb4PTH.png)
BillsPCMenu:
	; [wCurrentMenuItem] = [wParentMenuItem]
	ld a, [wParentMenuItem]
	ld [wCurrentMenuItem], a

	; VRAM にモンスターボールの 2bppデータ を転送
	ld hl, vChars2 + $780
	ld de, PokeballTileGraphics
	lb bc, BANK(PokeballTileGraphics), $01
	call CopyVideoData

	; DisplayPCMainMenu で保存した PCのメインメニューのテキストボックスが存在しない画面を復帰
	call LoadScreenTilesFromBuffer2DisableBGTransfer

	; テキストボックスとマサキのPCボックスのメニューを表示
	coord hl, 0, 0
	ld b, 10
	ld c, 12
	call TextBoxBorder
	coord hl, 2, 2
	ld de, BillsPCMenuText
	call PlaceString

	; カーソルの初期位置は (1, 2)
	ld hl, wTopMenuItemY
	ld a, 2
	ld [hli], a ; [wTopMenuItemY] = 2
	dec a
	ld [hli], a ; [wTopMenuItemX] = 1

	; menuの項目数は 5
	inc hl
	inc hl
	ld a, 4
	ld [hli], a ; [wMaxMenuItem] = 4

	; (上下方向キーのぞいて)ABボタンのみ有効
	ld a, A_BUTTON | B_BUTTON
	ld [hli], a

	; その他変数を初期化
	xor a
	ld [hli], a ; [wLastMenuItem] = 0
	ld [hli], a ; [wPartyAndBillsPCSavedMenuItem] = 0
	ld hl, wListScrollOffset
	ld [hli], a ; [wListScrollOffset] = 0
	ld [hl], a ; [wMenuWatchMovingOutOfBounds] = 0
	ld [wPlayerMonNumber], a	; [wPlayerMonNumber] = 0

	; "What?"
	ld hl, WhatText
	call PrintText

	; 画面右下に現在のボックス番号のためのテキストボックスを表示
	coord hl, 9, 14
	ld b, 2
	ld c, 9
	call TextBoxBorder

	; a = ボックス番号
	ld a, [wCurrentBoxNum]
	and $7f

	; ボックス番号が 1桁 -> .singleDigitBoxNum
	cp 9
	jr c, .singleDigitBoxNum

; ボックス番号を描画
	; 二桁のとき
	sub 9
	coord hl, 17, 16
	ld [hl], "1"		; 2桁目
	add "0"				; 1桁目 数値 -> 文字コード
	jr .next
.singleDigitBoxNum
	; 一桁のとき
	add "1"	; 数値 -> 文字コード
.next
	Coorda 18, 16

	; "BOX No."
	coord hl, 10, 16
	ld de, BoxNoPCText
	call PlaceString

	ld a, 1
	ld [H_AUTOBGTRANSFERENABLED], a
	call Delay3

	; ユーザーがmenuの項目でA/Bボタンを押すのを待つ
	call HandleMenuInput

	; Bボタン -> ExitBillsPC
	bit 1, a
	jp nz, ExitBillsPC

	; Aボタン
	; ユーザーが選んだメニュー項目のカーソルを ▶︎ から ▷ にする
	call PlaceUnfilledArrowMenuCursor

	; a = [wParentMenuItem] = [wCurrentMenuItem]
	ld a, [wCurrentMenuItem]
	ld [wParentMenuItem], a

	; 選んだメニュー項目によって分岐
	and a
	jp z, BillsPCWithdraw ; withdraw
	cp $1
	jp z, BillsPCDeposit ; deposit
	cp $2
	jp z, BillsPCRelease ; release
	cp $3
	jp z, BillsPCChangeBox ; change box
	; SEE YA!

; マサキのPCのメニューで Bボタンを押したか "SEE YA!" を選んだ場合の処理
ExitBillsPC:
	; 普通のPC(ポケセンのPCなど)で "BILL's PC" を選んだ場合 -> .next
	ld a, [wFlags_0xcd60]
	bit 3, a
	jr nz, .next

	; マサキのパソコンを使った場合はサウンドをつける
	call LoadTextBoxTilePatterns
	ld a, SFX_TURN_OFF_PC
	call PlaySound
	call WaitForSoundToFinish

.next
	ld hl, wFlags_0xcd60
	res 5, [hl]

	; DisplayPCMainMenu で保存した PCのメインメニューのテキストボックスが存在しない画面を復帰
	call LoadScreenTilesFromBuffer2

	; BillsPC_ で退避した値を戻す
	pop af
	ld [wListScrollOffset], a

	; 遅延を戻す
	ld hl, wd730
	res 6, [hl]
	ret

; マサキのPCでポケモンを deposit を選んだ場合
BillsPCDeposit:
	; 手持ち数が2匹以上 -> .partyLargeEnough
	ld a, [wPartyCount]
	dec a
	jr nz, .partyLargeEnough

	; 手持ちが一匹しかいない -> BillsPCMenu
	ld hl, CantDepositLastMonText
	call PrintText		; "You can't deposit the last #MON!"
	jp BillsPCMenu

.partyLargeEnough
	; ボックスに空きがある -> .boxNotFull
	ld a, [wNumInBox]
	cp MONS_PER_BOX
	jr nz, .boxNotFull

	; ボックスがいっぱい -> BillsPCMenu
	ld hl, BoxFullText
	call PrintText		; "Oops! This Box is full of #MON."
	jp BillsPCMenu

.boxNotFull
	; 預けるポケモンの list menu のテキストボックスを表示
	ld hl, wPartyCount
	call DisplayMonListMenu
	jp c, BillsPCMenu	; キャンセルされたとき -> BillsPCMenu

	call DisplayDepositWithdrawMenu
	jp nc, BillsPCMenu	; キャンセルされたとき -> BillsPCMenu

	; 鳴き声を出しながら、ポケモンのデータを手持ちからPCBoxに移動する
	ld a, [wcf91]
	call GetCryData
	call PlaySoundWaitForCurrent
	ld a, PARTY_TO_BOX
	ld [wMoveMonType], a
	call MoveMon			; コピー
	xor a
	ld [wRemoveMonFromBox], a
	call RemovePokemon		; コピー元の削除
	call WaitForSoundToFinish

; [wBoxNumString] = ボックス番号(文字列)
	ld hl, wBoxNumString
	ld a, [wCurrentBoxNum]
	and $7f
	cp 9
	jr c, .singleDigitBoxNum
	sub 9
	ld [hl], "1"
	inc hl
	add "0"
	jr .next
.singleDigitBoxNum
	add "1"
.next
	ld [hli], a
	ld [hl], "@"

	; "${wcf4b} was stored in Box ${wBoxNumString}."
	ld hl, MonWasStoredText
	call PrintText
	
	; 戻る
	jp BillsPCMenu

; マサキのPCでポケモンを withdraw を選んだ場合
BillsPCWithdraw:
	; PCBoxの中身が空 かチェック
	ld a, [wNumInBox]
	and a
	jr nz, .boxNotEmpty

	; PCBoxの中身が空 -> 戻る
	ld hl, NoMonText	; "What? There are no #MON here!"
	call PrintText
	jp BillsPCMenu

.boxNotEmpty
	; 手持ちがいっぱい かチェック
	ld a, [wPartyCount]
	cp PARTY_LENGTH
	jr nz, .partyNotFull

	; 手持ちがいっぱい -> 戻る
	ld hl, CantTakeMonText	; "You can't take any more #MON. Deposit #MON first."
	call PrintText
	jp BillsPCMenu

.partyNotFull
	; 引き出すポケモンの list menu のテキストボックスを表示
	ld hl, wNumInBox
	call DisplayMonListMenu	; hl = wNumInBox
	jp c, BillsPCMenu	; キャンセルされたとき -> BillsPCMenu

	call DisplayDepositWithdrawMenu
	jp nc, BillsPCMenu	; キャンセルされたとき -> BillsPCMenu

	ld a, [wListMenuOffset]
	ld hl, wBoxMonNicks
	call GetPartyMonName

	; 鳴き声を出しながら、ポケモンのデータをPCBoxから手持ちに移動する
	ld a, [wcf91]
	call GetCryData
	call PlaySoundWaitForCurrent
	xor a ; BOX_TO_PARTY
	ld [wMoveMonType], a
	call MoveMon
	ld a, 1
	ld [wRemoveMonFromBox], a
	call RemovePokemon
	call WaitForSoundToFinish

	; "${Pokemon} is taken out. Got ${Pokemon}."
	ld hl, MonIsTakenOutText
	call PrintText

	; 戻る
	jp BillsPCMenu

; マサキのPCでポケモンを release を選んだ場合
BillsPCRelease:
	; ボックスに1匹以上ポケモンがいる -> .loop
	ld a, [wNumInBox]
	and a
	jr nz, .loop

	; ボックスにポケモンが1匹もいないなら終了
	ld hl, NoMonText
	call PrintText	; "What? There are no #MON here!"
	jp BillsPCMenu	; 戻る

.loop	
	; 逃すポケモンの list menu のテキストボックスを表示
	ld hl, wNumInBox
	call DisplayMonListMenu ; hl = wNumInBox
	jp c, BillsPCMenu		; キャンセルされたとき -> BillsPCMenu

	; 逃していいか確認
	ld hl, OnceReleasedText
	call PrintText			; "Once released, ${Pokemon} is gone forever. OK?"
	call YesNoChoice
	
	; 確認で No を押されたら戻る
	ld a, [wCurrentMenuItem]
	and a
	jr nz, .loop	; キャンセルされたとき -> .loop

	; PCBoxから逃す処理を行う
	inc a
	ld [wRemoveMonFromBox], a
	call RemovePokemon
	call WaitForSoundToFinish
	ld a, [wcf91]
	call PlayCry

	; "${Pokemon} was released outside. Bye"
	ld hl, MonWasReleasedText
	call PrintText

	; 戻る
	jp BillsPCMenu

BillsPCChangeBox:
	callba ChangeBox
	jp BillsPCMenu

; **DisplayMonListMenu**  
; ポケモンの list menuを表示しプレイヤーの選択を待つ  
; - - -  
; INPUT: hl = wPartyCount or wNumInBox
DisplayMonListMenu:
	; [wListPointer] = hl (wPartyCount or wNumInBox)
	ld a, l
	ld [wListPointer], a
	ld a, h
	ld [wListPointer + 1], a

	; ポケモンのリストなので価格は表示しないようにする
	xor a
	ld [wPrintItemPrices], a

	; [wListMenuID] = ポケモンのリスト
	ld [wListMenuID], a

	; [wNameListType] = MONSTER_NAME
	inc a
	ld [wNameListType], a

	; ポケモンの list menuを表示しプレイヤーの選択を待つ
	ld a, [wPartyAndBillsPCSavedMenuItem]
	ld [wCurrentMenuItem], a
	call DisplayListMenuID
	ld a, [wCurrentMenuItem]
	ld [wPartyAndBillsPCSavedMenuItem], a	; [wPartyAndBillsPCSavedMenuItem] = 選んだポケモンの menu ID
	ret

; **BillsPCMenuText**  
; - - -  
; "WITHDRAW POKEMON"  
; "DEPOSIT POKEMON"  
; "RELEASE POKEMON"  
; "CHANGE BOX"  
; "SEE YA!"  
BillsPCMenuText:
	db   "WITHDRAW ", $4a
	next "DEPOSIT ",  $4a
	next "RELEASE ",  $4a
	next "CHANGE BOX"
	next "SEE YA!"
	db "@"

; "BOX No."
BoxNoPCText:
	db "BOX No.@"

KnowsHMMove::
; returns whether mon with party index [wWhichPokemon] knows an HM move
	ld hl, wPartyMon1Moves
	ld bc, wPartyMon2 - wPartyMon1
	jr .next
; unreachable
	ld hl, wBoxMon1Moves
	ld bc, wBoxMon2 - wBoxMon1
.next
	ld a, [wWhichPokemon]
	call AddNTimes
	ld b, NUM_MOVES
.loop
	ld a, [hli]
	push hl
	push bc
	ld hl, HMMoveArray
	ld de, 1
	call IsInArray
	pop bc
	pop hl
	ret c
	dec b
	jr nz, .loop
	and a
	ret

HMMoveArray:
	db CUT
	db FLY
	db SURF
	db STRENGTH
	db FLASH
	db -1

; **DisplayDepositWithdrawMenu**  
; 画像右下の DEPOSIT/STATS/CANCEL の menu を表示  
; - - -  
; WITHDRAW/STATS/CANCEL のときもある  
; 
; OUTPUT: carry = 1(deposit or withdrawをした) or 0(しなかった)
; ![deposit](https://imgur.com/VvLg5kR.png)  
DisplayDepositWithdrawMenu:
	; テキストボックスの枠を描画
	coord hl, 9, 10
	ld b, 6
	ld c, 9
	call TextBoxBorder

; 1項目目の DEPOSIT(WITHDRAW) を描画
	ld a, [wParentMenuItem]
	and a
	ld de, DepositPCText
	jr nz, .next
	ld de, WithdrawPCText	; de = DepositPCText(ポケモンを預ける場合) or WithdrawPCText(引き出す場合)
.next
	coord hl, 11, 12
	call PlaceString

	; 2,3項目目の "STATS/CANCEL" を描画
	coord hl, 11, 14
	ld de, StatsCancelPCText
	call PlaceString

	; (10, 12) にカーソル設置
	ld hl, wTopMenuItemY
	ld a, 12
	ld [hli], a ; wTopMenuItemY
	ld a, 10
	ld [hli], a ; wTopMenuItemX

	; 1項目目にカーソルを置き、menu は全部で3項目
	xor a
	ld [hli], a
	inc hl
	ld a, 2
	ld [hli], a

	; (上下方向キーのぞいて)ABボタンのみ有効
	ld a, A_BUTTON | B_BUTTON
	ld [hli], a ; wMenuWatchedKeys
	
	; その他の変数を初期化
	xor a
	ld [hl], a ; wLastMenuItem
	ld hl, wListScrollOffset
	ld [hli], a ; wListScrollOffset
	ld [hl], a ; wMenuWatchMovingOutOfBounds
	ld [wPlayerMonNumber], a
	ld [wPartyAndBillsPCSavedMenuItem], a

.loop
	; Bボタン -> .exit
	call HandleMenuInput
	bit 1, a ; pressed B?
	jr nz, .exit

	; DEPOSIT(WITHDRAW) を選択 -> .choseDepositWithdraw
	ld a, [wCurrentMenuItem]
	and a
	jr z, .choseDepositWithdraw
	; STATS を選択 -> .viewStats
	dec a
	jr z, .viewStats
	; CANCEL を選択 -> .exit(fallthrough)

.exit
	and a
	ret

.choseDepositWithdraw
	scf
	ret

.viewStats
	; a = PLAYER_PARTY_DATA(deposit) or BOX_DATA(withdraw)
	call SaveScreenTilesToBuffer1	; statsから戻るときのために退避
	ld a, [wParentMenuItem]
	and a
	ld a, PLAYER_PARTY_DATA	; deposit
	jr nz, .next2
	ld a, BOX_DATA			; withdraw

.next2
	; stats画面
	ld [wMonDataLocation], a
	predef StatusScreen
	predef StatusScreen2

	; stats画面から元に戻る
	call LoadScreenTilesFromBuffer1
	call ReloadTilesetTilePatterns
	call RunDefaultPaletteCommand
	call LoadGBPal
	jr .loop

DepositPCText:  db "DEPOSIT@"	; "DEPOSIT"
WithdrawPCText: db "WITHDRAW@"	; "WITHDRAW"
StatsCancelPCText:	; "STATS/CANCEL"
	db   "STATS"
	next "CANCEL@"

; "Switch on!"
SwitchOnText:
	TX_FAR _SwitchOnText
	db "@"

; "What?"
WhatText:
	TX_FAR _WhatText
	db "@"

DepositWhichMonText:
	TX_FAR _DepositWhichMonText
	db "@"

; "${wcf4b} was stored in Box ${wBoxNumString}."
MonWasStoredText:
	TX_FAR _MonWasStoredText
	db "@"

; "You can't deposit the last #MON!"
CantDepositLastMonText:
	TX_FAR _CantDepositLastMonText
	db "@"

; "Oops! This Box is full of #MON."
BoxFullText:
	TX_FAR _BoxFullText
	db "@"

; "${Pokemon} is taken out. Got ${Pokemon}."
MonIsTakenOutText:
	TX_FAR _MonIsTakenOutText
	db "@"

; "What? There are no #MON here!"
NoMonText:
	TX_FAR _NoMonText
	db "@"

; "You can't take any more #MON. Deposit #MON first."
CantTakeMonText:
	TX_FAR _CantTakeMonText
	db "@"

ReleaseWhichMonText:
	TX_FAR _ReleaseWhichMonText
	db "@"

; "Once released, ${Pokemon} is gone forever. OK?"
OnceReleasedText:
	TX_FAR _OnceReleasedText
	db "@"

; "${Pokemon} was released outside. Bye"
MonWasReleasedText:
	TX_FAR _MonWasReleasedText
	db "@"

CableClubLeftGameboy::
	ld a, [hSerialConnectionStatus]
	cp USING_EXTERNAL_CLOCK
	ret z
	ld a, [wSpriteStateData1 + 9] ; player's sprite facing direction
	cp SPRITE_FACING_RIGHT
	ret nz
	ld a, [wCurMap]
	cp TRADE_CENTER
	ld a, LINK_STATE_START_TRADE
	jr z, .next
	inc a ; LINK_STATE_START_BATTLE
.next
	ld [wLinkState], a
	call EnableAutoTextBoxDrawing
	tx_pre_jump JustAMomentText

CableClubRightGameboy::
	ld a, [hSerialConnectionStatus]
	cp USING_INTERNAL_CLOCK
	ret z
	ld a, [wSpriteStateData1 + 9] ; player's sprite facing direction
	cp SPRITE_FACING_LEFT
	ret nz
	ld a, [wCurMap]
	cp TRADE_CENTER
	ld a, LINK_STATE_START_TRADE
	jr z, .next
	inc a ; LINK_STATE_START_BATTLE
.next
	ld [wLinkState], a
	call EnableAutoTextBoxDrawing
	tx_pre_jump JustAMomentText

JustAMomentText::
	TX_FAR _JustAMomentText
	db "@"

	ld a, [wSpriteStateData1 + 9] ; player's sprite facing direction
	cp SPRITE_FACING_UP
	ret nz
	call EnableAutoTextBoxDrawing
	tx_pre_jump OpenBillsPCText

OpenBillsPCText::
	db $FD ; FuncTX_BillsPC

