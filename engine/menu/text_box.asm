; **DisplayTextBoxID_**  
; 様々なテキストボックスを描画する関数  
; - - -  
; 使いまわされる定型分的なテキストボックスとテキストなら中のテキストも描画する  
; 
; INPUT:  
; [wTextBoxID] = TextBoxID  
; hl = テキストボックスのボーダーが描画されるべきアドレス  
; [wTwoOptionMenuID] = 2択Menuを表示するなら 2択menu の種類  
DisplayTextBoxID_:
	ld a, [wTextBoxID]

	; 2択menu -> DisplayTwoOptionMenu
	cp TWO_OPTION_MENU
	jp z, DisplayTwoOptionMenu

	; TextBoxFunctionTable に [wTextBoxID]が当てはまるものがある -> .functionTableMatch
	ld c, a
	ld hl, TextBoxFunctionTable
	ld de, 3
	call SearchTextBoxTable
	jr c, .functionTableMatch

	; TextBoxCoordTable に [wTextBoxID]が当てはまるものがある -> .coordTableMatch
	ld hl, TextBoxCoordTable
	ld de, 5
	call SearchTextBoxTable
	jr c, .coordTableMatch

	; TextBoxTextAndCoordTable に [wTextBoxID]が当てはまるものがある -> .textAndCoordTableMatch
	ld hl, TextBoxTextAndCoordTable
	ld de, 9
	call SearchTextBoxTable
	jr c, .textAndCoordTableMatch

	; 当てはまるものなし -> return
.done
	ret

.functionTableMatch
	; hl = address of function
	inline "hl = [hl]"

	; call hl でテキストボックスを描画
	ld de, .done
	push de
	jp hl

.coordTableMatch
	; TextBoxBorder の実行に必要な引数を取得して テキストボックスを描画
	call GetTextBoxIDCoords
	call GetAddressOfScreenCoords
	call TextBoxBorder
	ret
	
.textAndCoordTableMatch
	; まずテキストボックスを描画
	call GetTextBoxIDCoords
	push hl
	call GetAddressOfScreenCoords
	call TextBoxBorder
	pop hl

	call GetTextBoxIDText

	; wd730 を退避
	ld a, [wd730]
	push af

	; 定型分は即時に文字が描画される必要がある
	ld a, [wd730]
	set 6, a
	ld [wd730], a

	; 定型分を描画
	call PlaceString

	; wd730 を復帰
	pop af
	ld [wd730], a
	call UpdateSprites
	ret

; **SearchTextBoxTable**  
; hlで指定した 終端記号0xffの エントリサイズがdeのテーブルから エントリが c に合うものを探す関数  
; - - -  
; エントリの最初の 1byte が c に合うものを探す  
; 
; OUTPUT:  
; hl = 該当エントリの2byte目(TextBoxの次のバイト)  
; carry = 1(見つかった) or 0(見つからない)  
SearchTextBoxTable:
	dec de
.loop
	ld a, [hli]
	cp $ff
	jr z, .notFound
	cp c
	jr z, .found
	add hl, de
	jr .loop
.found
	scf
.notFound
	ret

; **GetTextBoxIDCoords**  
; TextBoxCoordTable か TextBoxTextAndCoordTable の該当エントリからテキストボックスの座標プロパティを取り出す  
; - - -  
; INPUT:  
; hl = 該当エントリの2バイト目(TextBoxCoordTable[i][1] or TextBoxTextAndCoordTable[i][1])  
; 
; OUTPUT:  
; b = テキストボックスの高さ  
; c = テキストボックスの幅  
; d = y0(左上)   
; e = x0(左上)  
GetTextBoxIDCoords:
	ld a, [hli] ; x0(左上)
	ld e, a
	ld a, [hli] ; y0(左上)
	ld d, a
	ld a, [hli] ; x1(右下)
	sub e
	dec a
	ld c, a     ; c = width
	ld a, [hli] ; y1(右下)
	sub d
	dec a
	ld b, a     ; b = height
	ret

; **GetTextBoxIDText**  
; TextBoxTextAndCoordTable から テキストのアドレスと coordを取得する  
; - - -  
; INPUT:  
; hl = 該当エントリの2バイト目(TextBoxTextAndCoordTable[i][1])  
; 
; OUTPUT:  
; de = テキストのアドレス  
; hl = テキストの始まる coordの wTileMap でのタイルアドレス
GetTextBoxIDText:
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a ; de = address of text
	push de ; save text address
	ld a, [hli]
	ld e, a ; column of upper left corner of text
	ld a, [hl]
	ld d, a ; row of upper left corner of text
	call GetAddressOfScreenCoords
	pop de ; restore text address
	ret

; **GetAddressOfScreenCoords**  
; hl が画面のタイルアドレスを指すようにする  
; - - -  
; INPUT:  
; d = Ycoord  
; e = Xcoord  
; 
; OUTPUT:  
; hl = de のcoordの wTileMap でのタイルアドレス  
GetAddressOfScreenCoords:
	push bc
	coord hl, 0, 0
	ld bc, 20
.loop ; loop to add d rows to the base address
	ld a, d
	and a
	jr z, .addedRows
	add hl, bc
	dec d
	jr .loop
.addedRows
	pop bc
	add hl, de
	ret

; **TextBoxFunctionTable**  
; TextBoxID -> 描画関数 への mapping  
; - - -  
; 各エントリは 3byte で終端記号は0xff  
; TextBoxID(1byte) -> addr(2byte)  
TextBoxFunctionTable:
	dbw MONEY_BOX, DisplayMoneyBox
	dbw BUY_SELL_QUIT_MENU, DoBuySellQuitMenu
	dbw FIELD_MOVE_MON_MENU, DisplayFieldMoveMonMenu
	db $ff ; terminator

; **TextBoxCoordTable**  
; TextBoxID -> 描画範囲 への mapping  
; - - -  
; `db TextBoxID x0, y0, x1, y1` (16*16のマス単位, 左上 -> 右下) 
TextBoxCoordTable:
	db MESSAGE_BOX,       0, 12, 19, 17
	db $03,               0,  0, 19, 14
	db $07,               0,  0, 11,  6
	db LIST_MENU_BOX,     4,  2, 19, 12	; (4, 2) -> (19, 12)
	db $10,               7,  0, 19, 17
	db MON_SPRITE_POPUP,  6,  4, 14, 13	; (6, 4) -> (14, 13) https://imgur.com/0TKpIiz.png
	db $ff ; terminator

; **TextBoxTextAndCoordTable**  
; TextBoxID -> 使いまわされるテキストボックスとテキスト内容 のmapping
; - - -  
; フォーマット:  
; db TextBoxID  
; db x0,y0,x1,y1  
; dw Textのアドレス  
; db Textの描画を始めるcoord  
TextBoxTextAndCoordTable:
	db JP_MOCHIMONO_MENU_TEMPLATE
	db 0,0,14,17   ; text box coordinates
	dw JapaneseMochimonoText
	db 3,0   ; text coordinates

	db USE_TOSS_MENU_TEMPLATE
	db 13,10,19,14 ; text box coordinates
	dw UseTossText
	db 15,11 ; text coordinates

	db JP_SAVE_MESSAGE_MENU_TEMPLATE
	db 0,0,7,5     ; text box coordinates
	dw JapaneseSaveMessageText
	db 2,2   ; text coordinates

	db JP_SPEED_OPTIONS_MENU_TEMPLATE
	db 0,6,5,10    ; text box coordinates
	dw JapaneseSpeedOptionsText
	db 2,7   ; text coordinates

	db BATTLE_MENU_TEMPLATE
	db 8,12,19,17  ; text box coordinates
	dw BattleMenuText
	db 10,14 ; text coordinates

	db SAFARI_BATTLE_MENU_TEMPLATE
	db 0,12,19,17  ; text box coordinates
	dw SafariZoneBattleMenuText
	db 2,14  ; text coordinates

	db SWITCH_STATS_CANCEL_MENU_TEMPLATE
	db 11,11,19,17 ; text box coordinates
	dw SwitchStatsCancelText
	db 13,12 ; text coordinates

	db BUY_SELL_QUIT_MENU_TEMPLATE
	db 0,0,10,6    ; text box coordinates
	dw BuySellQuitText
	db 2,1   ; text coordinates

	db MONEY_BOX_TEMPLATE
	db 11,0,19,2   ; text box coordinates
	dw MoneyText
	db 13,0  ; text coordinates

	db JP_AH_MENU_TEMPLATE
	db 7,6,11,10   ; text box coordinates
	dw JapaneseAhText
	db 8,8   ; text coordinates

	db JP_POKEDEX_MENU_TEMPLATE
	db 11,8,19,17  ; text box coordinates
	dw JapanesePokedexMenu
	db 12,10 ; text coordinates
	; note that there is no terminator

; "BUY SELL QUIT"
BuySellQuitText:
	db   "BUY"
	next "SELL"
	next "QUIT@@"

; "USE TOSS"
UseTossText:
	db   "USE"
	next "TOSS@"

; "きろく メッセージ"
JapaneseSaveMessageText:
	db   "きろく"
	next "メッセージ@"

; "はやい おそい"
JapaneseSpeedOptionsText:
	db   "はやい"
	next "おそい@"

; "MONEY"
MoneyText:
	db "MONEY@"

; "もちもの"
JapaneseMochimonoText:
	db "もちもの@"

; "つづきから さいしょから"
JapaneseMainMenuText:
	db   "つづきから"
	next "さいしょから@"

; "FIGHT PKMN"  
; "ITEM RUN"  
BattleMenuText:
	db   "FIGHT ",$E1,$E2
	next "ITEM  RUN@"

SafariZoneBattleMenuText:
	db   "BALL×       BAIT"
	next "THROW ROCK  RUN@"

SwitchStatsCancelText:
	db   "SWITCH"
	next "STATS"
	next "CANCEL@"

; "アッ!"
JapaneseAhText:
	db "アッ!@"

JapanesePokedexMenu:
	db   "データをみる"
	next "なきごえ"
	next "ぶんぷをみる"
	next "キャンセル@"

DisplayMoneyBox:
	ld hl, wd730
	set 6, [hl]
	ld a, MONEY_BOX_TEMPLATE
	ld [wTextBoxID], a
	call DisplayTextBoxID
	coord hl, 13, 1
	ld b, 1
	ld c, 6
	call ClearScreenArea
	coord hl, 12, 1
	ld de, wPlayerMoney
	ld c, $a3	; ¥
	call PrintBCDNumber
	ld hl, wd730
	res 6, [hl]
	ret

CurrencyString:
	db "      ¥@"

DoBuySellQuitMenu:
	ld a, [wd730]
	set 6, a ; no printing delay
	ld [wd730], a
	xor a
	ld [wChosenMenuItem], a
	ld a, BUY_SELL_QUIT_MENU_TEMPLATE
	ld [wTextBoxID], a
	call DisplayTextBoxID
	ld a, A_BUTTON | B_BUTTON
	ld [wMenuWatchedKeys], a
	ld a, $2
	ld [wMaxMenuItem], a
	ld a, $1
	ld [wTopMenuItemY], a
	ld a, $1
	ld [wTopMenuItemX], a
	xor a
	ld [wCurrentMenuItem], a
	ld [wLastMenuItem], a
	ld [wMenuWatchMovingOutOfBounds], a
	ld a, [wd730]
	res 6, a ; turn on the printing delay
	ld [wd730], a
	call HandleMenuInput
	call PlaceUnfilledArrowMenuCursor
	bit 0, a ; was A pressed?
	jr nz, .pressedA
	bit 1, a ; was B pressed? (always true since only A/B are watched)
	jr z, .pressedA
	ld a, CANCELLED_MENU
	ld [wMenuExitMethod], a
	jr .quit
.pressedA
	ld a, CHOSE_MENU_ITEM
	ld [wMenuExitMethod], a
	ld a, [wCurrentMenuItem]
	ld [wChosenMenuItem], a
	ld b, a
	ld a, [wMaxMenuItem]
	cp b
	jr z, .quit
	ret
.quit
	ld a, CANCELLED_MENU
	ld [wMenuExitMethod], a
	ld a, [wCurrentMenuItem]
	ld [wChosenMenuItem], a
	scf
	ret

; **DisplayTwoOptionMenu**  
; 2択menuを描画する  
; - - -  
; INPUT:  
; b = 一番上(ID 0)の項目のカーソルの位置の Ycoords  
; c = 一番上(ID 0)の項目のカーソルの位置の Xcoords  
; hl = テキストボックスのボーダーが描画されるべきアドレス  
; [wTwoOptionMenuID] = 表示する2択menu の種類  
; 
; OUTPUT:  
; [wMenuExitMethod] = CHOSE_FIRST_ITEM or CHOSE_SECOND_ITEM  
DisplayTwoOptionMenu:
	push hl

	; テキスト描画の遅延を無効化
	ld a, [wd730]
	set 6, a ; no printing delay
	ld [wd730], a

	; この3行は無駄な処理
	xor a
	ld [wChosenMenuItem], a
	ld [wMenuExitMethod], a

	ld a, A_BUTTON | B_BUTTON
	ld [wMenuWatchedKeys], a	; (上下方向キーのぞいて)ABボタンのみ有効
	ld a, $1
	ld [wMaxMenuItem], a		; menu を 2択に
	ld a, b
	ld [wTopMenuItemY], a		; [wTopMenuItemY] = b
	ld a, c
	ld [wTopMenuItemX], a		; [wTopMenuItemX] = c
	xor a
	ld [wLastMenuItem], a		; [wLastMenuItem] = 0
	ld [wMenuWatchMovingOutOfBounds], a	; [wMenuWatchMovingOutOfBounds] = 0

; [wCurrentMenuItem] = 0(カーソルが1つめ) or 1(カーソルが2つめ)
	push hl
	ld hl, wTwoOptionMenuID
	bit 7, [hl] 
	res 7, [hl]
	jr z, .storeCurrentMenuItem	; wTwoOptionMenuID の bit7がセットされていたらカーソルの初期値は No
	inc a
.storeCurrentMenuItem
	ld [wCurrentMenuItem], a
	pop hl	; hl = テキストボックスのボーダーが描画されるべきアドレス

	; 2択 menu から元に戻るために 2択menu が出る前の状態を退避
	push hl
	push hl
	call TwoOptionMenu_SaveScreenTiles	

; hl = TwoOptionMenuStrings の対象エントリ (TwoOptionMenuStrings[i])
	ld a, [wTwoOptionMenuID]
	ld hl, TwoOptionMenuStrings
	ld e, a
	ld d, $0	; de = [wTwoOptionMenuID]
	ld a, $5	; TwoOptionMenuStringsの各エントリのサイズ
.menuStringLoop
	add hl, de
	dec a
	jr nz, .menuStringLoop	; hl = TwoOptionMenuStrings + 5*[wTwoOptionMenuID]

	ld a, [hli]	; c = X
	ld c, a
	ld a, [hli]	; b = Y
	ld b, a
	ld e, l
	ld d, h		; de = hl = TwoOptionMenuStrings[i][02] = 1つ目の選択肢の上に空白タイルを置くか

	pop hl	; hl = テキストボックスのボーダーが描画されるべきアドレス
	push de	; push TwoOptionMenuStrings[i][02]

; 2択menuのテキストボックスを描画 (`call TextBoxBorder` or `call CableClub_TextBoxBorder`)
	ld a, [wTwoOptionMenuID]
	cp TRADE_CANCEL_MENU
	jr nz, .notTradeCancelMenu
	call CableClub_TextBoxBorder
	jr .afterTextBoxBorder
.notTradeCancelMenu
	call TextBoxBorder

.afterTextBoxBorder
	call UpdateSprites

; bc = 文字の描画を始めるアドレス(20+2 or 2*20+2)
	pop hl	; hl = TwoOptionMenuStrings[i][02] = 1つ目の選択肢の上に空白タイルを置くか
	ld a, [hli]
	and a
	ld bc, 20 + 2
	jr z, .noBlankLine
	ld bc, 2 * 20 + 2	; 1つ目の選択肢の上に空白タイルを置く場合
.noBlankLine

	; 2択menuのテキストを描画
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	pop hl	; hl = テキストボックスのボーダーが描画されるべきアドレス
	add hl, bc	; hl = 文字の描画を始めるアドレス
	call PlaceString

	; テキスト描画の遅延を有効化
	ld hl, wd730
	res 6, [hl]

	; 2択menuが "No/Yes" でない -> .notNoYesMenu
	ld a, [wTwoOptionMenuID]
	cp NO_YES_MENU
	jr nz, .notNoYesMenu

; No/Yes menu
; セーブデータの削除の確認でのみ使われる
; この2択menuでは Bボタンを無視するようにする  
	; [wTwoOptionMenuID] = [wFlags_0xcd60] = 0
	xor a
	ld [wTwoOptionMenuID], a
	ld a, [wFlags_0xcd60]

	push af ; push 0

	; A/Bボタンが押された時にサウンドをならさない
	push hl
	ld hl, wFlags_0xcd60
	bit 5, [hl]
	set 5, [hl]
	pop hl

.noYesMenuInputLoop
; {
	call HandleMenuInput	; No/Yesの2択でユーザー入力(A/B)を待つ
	bit 1, a
	jr nz, .noYesMenuInputLoop ; Bボタンは無視
; }

	; Aボタンが押された場合 -> .pressedAButton
	pop af	; af = 0
	pop hl	; hl = テキストボックスのボーダーが描画されるべきアドレス
	ld [wFlags_0xcd60], a	; [wFlags_0xcd60] = 0
	ld a, SFX_PRESS_AB
	call PlaySound
	jr .pressedAButton

; "No/Yes" menu以外は文言は違えど処理は同じなので 2択menuが "No/Yes" でないときにここにくる
.notNoYesMenu
	xor a
	ld [wTwoOptionMenuID], a	; [wTwoOptionMenuID] = 0

	; 2択menuでユーザー入力(A/B)を待つ
	call HandleMenuInput

	pop hl	; hl = テキストボックスのボーダーが描画されるべきアドレス

	; Bボタンが押された時は強制的に2番目の択を選んだことにする
	bit 1, a
	jr nz, .choseSecondMenuItem

	; Aボタンが押された時
.pressedAButton
	; [wChosenMenuItem]のオフセットが0以上 つまり 2番目の択を選んだ -> .choseSecondMenuItem
	ld a, [wCurrentMenuItem]
	ld [wChosenMenuItem], a
	and a
	jr nz, .choseSecondMenuItem

	; 1番目の択を選んだ
	ld a, CHOSE_FIRST_ITEM
	ld [wMenuExitMethod], a
	ld c, 15
	call DelayFrames
	call TwoOptionMenu_RestoreScreenTiles 	; 2択前に画面を戻す
	and a
	ret

.choseSecondMenuItem
	; この3行は必要?
	ld a, 1
	ld [wCurrentMenuItem], a
	ld [wChosenMenuItem], a

	ld a, CHOSE_SECOND_ITEM
	ld [wMenuExitMethod], a
	ld c, 15
	call DelayFrames
	call TwoOptionMenu_RestoreScreenTiles	; 2択前に画面を戻す
	scf
	ret

; **TwoOptionMenu_SaveScreenTiles**  
; 2択menu で上書きされるタイルを wBuffer に保存する  
; - - -  
; 2択menu左上から6×5タイル(x×y)分のタイルが保存される  
; 2択menuの種類によっては全部保存しきれないものもある  
; その場合は、保存しきれなかった右下のタイルは関数終了後も画面に残り続けるので大丈夫?  
TwoOptionMenu_SaveScreenTiles:
	ld de, wBuffer
	lb bc, 5, 6	; 5*6 = 30(wBufferのサイズ)
.loop
	; 1行分保存
	inline "[de++] = [hl++]"
	dec c
	jr nz, .loop

	; hl を次の行に
	push bc
	ld bc, SCREEN_WIDTH - 6
	add hl, bc
	pop bc
	ld c, $6
	dec b
	jr nz, .loop

	ret

; **TwoOptionMenu_RestoreScreenTiles**  
; 2択menu で上書きされたタイルを上書きされる前の状態に戻す  
; - - -  
; 上書きされる前のタイルは TwoOptionMenu_SaveScreenTiles で wBuffer に退避している
TwoOptionMenu_RestoreScreenTiles:
	ld de, wBuffer
	lb bc, 5, 6
.loop
	ld a, [de]
	inc de
	ld [hli], a
	dec c
	jr nz, .loop
	push bc
	ld bc, SCREEN_WIDTH - 6
	add hl, bc
	pop bc
	ld c, 6
	dec b
	jr nz, .loop
	call UpdateSprites
	ret

; **TwoOptionMenuStrings**  
; 2択menu の 幅,高さ,pointer などを格納したテーブル  
; - - -  
; 各エントリは5byte  
; 00: テキストのとるタイル幅(+2したものがテキストボックス幅)  
; 01: テキストのとるタイル高さ(+2したものがテキストボックス高さ)  
; 02: 1つ目の選択肢の上に空白タイルを置くか(0:置かない, 1:置く)  
; 03-04: 2択menuのテキストのアドレス(2byte)  
; 
; 01は基本 1つ目 + 空白 + 2つ目 で3になる 02が1なら 空白 + 1つ目 + 空白 + 2つ目 で4  
; 02については 0: https://imgur.com/rJQSNz1.png, 1: https://imgur.com/wRa62p9.png
TwoOptionMenuStrings:
	db 4,3,0
	dw .YesNoMenu
	db 6,3,0
	dw .NorthWestMenu
	db 6,3,0
	dw .SouthEastMenu
	db 6,3,0
	dw .YesNoMenu
	db 6,3,0
	dw .NorthEastMenu
	db 7,3,0
	dw .TradeCancelMenu
	db 7,4,1
	dw .HealCancelMenu
	db 4,3,0
	dw .NoYesMenu

; "NO/YES"  
; セーブデータの削除の確認でのみ使われる
.NoYesMenu
	db   "NO"
	next "YES@"

; "YES/NO"
.YesNoMenu
	db   "YES"
	next "NO@"

; "NORTH/WEST"
.NorthWestMenu
	db   "NORTH"
	next "WEST@"

; "SOUTH/EAST"
.SouthEastMenu
	db   "SOUTH"
	next "EAST@"

; "NORTH/EAST"
.NorthEastMenu
	db   "NORTH"
	next "EAST@"

; "TRADE/CANCEL"
.TradeCancelMenu
	db   "TRADE"
	next "CANCEL@"

; "HEAL/CANCEL"
.HealCancelMenu
	db   "HEAL"
	next "CANCEL@"

DisplayFieldMoveMonMenu:
	xor a
	ld hl, wFieldMoves
	ld [hli], a ; wFieldMoves
	ld [hli], a ; wFieldMoves + 1
	ld [hli], a ; wFieldMoves + 2
	ld [hli], a ; wFieldMoves + 3
	ld [hli], a ; wNumFieldMoves
	ld [hl], 12 ; wFieldMovesLeftmostXCoord
	call GetMonFieldMoves
	ld a, [wNumFieldMoves]
	and a
	jr nz, .fieldMovesExist

; no field moves
	coord hl, 11, 11
	ld b, 5
	ld c, 7
	call TextBoxBorder
	call UpdateSprites
	ld a, 12
	ld [hFieldMoveMonMenuTopMenuItemX], a
	coord hl, 13, 12
	ld de, PokemonMenuEntries
	jp PlaceString

.fieldMovesExist
	push af

; Calculate the text box position and dimensions based on the leftmost X coord
; of the field move names before adjusting for the number of field moves.
	coord hl, 0, 11
	ld a, [wFieldMovesLeftmostXCoord]
	dec a
	ld e, a
	ld d, 0
	add hl, de
	ld b, 5
	ld a, 18
	sub e
	ld c, a
	pop af

; For each field move, move the top of the text box up 2 rows while the leaving
; the bottom of the text box at the bottom of the screen.
	ld de, -SCREEN_WIDTH * 2
.textBoxHeightLoop
	add hl, de
	inc b
	inc b
	dec a
	jr nz, .textBoxHeightLoop

; Make space for an extra blank row above the top field move.
	ld de, -SCREEN_WIDTH
	add hl, de
	inc b

	call TextBoxBorder
	call UpdateSprites

; Calculate the position of the first field move name to print.
	coord hl, 0, 12
	ld a, [wFieldMovesLeftmostXCoord]
	inc a
	ld e, a
	ld d, 0
	add hl, de
	ld de, -SCREEN_WIDTH * 2
	ld a, [wNumFieldMoves]
.calcFirstFieldMoveYLoop
	add hl, de
	dec a
	jr nz, .calcFirstFieldMoveYLoop

	xor a
	ld [wNumFieldMoves], a
	ld de, wFieldMoves
.printNamesLoop
	push hl
	ld hl, FieldMoveNames
	ld a, [de]
	and a
	jr z, .donePrintingNames
	inc de
	ld b, a ; index of name
.skipNamesLoop ; skip past names before the name we want
	dec b
	jr z, .reachedName
.skipNameLoop ; skip past current name
	ld a, [hli]
	cp "@"
	jr nz, .skipNameLoop
	jr .skipNamesLoop
.reachedName
	ld b, h
	ld c, l
	pop hl
	push de
	ld d, b
	ld e, c
	call PlaceString
	ld bc, SCREEN_WIDTH * 2
	add hl, bc
	pop de
	jr .printNamesLoop

.donePrintingNames
	pop hl
	ld a, [wFieldMovesLeftmostXCoord]
	ld [hFieldMoveMonMenuTopMenuItemX], a
	coord hl, 0, 12
	ld a, [wFieldMovesLeftmostXCoord]
	inc a
	ld e, a
	ld d, 0
	add hl, de
	ld de, PokemonMenuEntries
	jp PlaceString

FieldMoveNames:
	db "CUT@"
	db "FLY@"
	db "@"
	db "SURF@"
	db "STRENGTH@"
	db "FLASH@"
	db "DIG@"
	db "TELEPORT@"
	db "SOFTBOILED@"

PokemonMenuEntries:
	db   "STATS"
	next "SWITCH"
	next "CANCEL@"

GetMonFieldMoves:
	ld a, [wWhichPokemon]
	ld hl, wPartyMon1Moves
	ld bc, wPartyMon2 - wPartyMon1
	call AddNTimes
	ld d, h
	ld e, l
	ld c, NUM_MOVES + 1
	ld hl, wFieldMoves
.loop
	push hl
.nextMove
	dec c
	jr z, .done
	ld a, [de] ; move ID
	and a
	jr z, .done
	ld b, a
	inc de
	ld hl, FieldMoveDisplayData
.fieldMoveLoop
	ld a, [hli]
	cp $ff
	jr z, .nextMove ; if the move is not a field move
	cp b
	jr z, .foundFieldMove
	inc hl
	inc hl
	jr .fieldMoveLoop
.foundFieldMove
	ld a, b
	ld [wLastFieldMoveID], a
	ld a, [hli] ; field move name index
	ld b, [hl] ; field move leftmost X coordinate
	pop hl
	ld [hli], a ; store name index in wFieldMoves
	ld a, [wNumFieldMoves]
	inc a
	ld [wNumFieldMoves], a
	ld a, [wFieldMovesLeftmostXCoord]
	cp b
	jr c, .skipUpdatingLeftmostXCoord
	ld a, b
	ld [wFieldMovesLeftmostXCoord], a
.skipUpdatingLeftmostXCoord
	ld a, [wLastFieldMoveID]
	ld b, a
	jr .loop
.done
	pop hl
	ret

; Format: [Move id], [name index], [leftmost tile]
; Move id = id of move
; Name index = index of name in FieldMoveNames
; Leftmost tile = -1 + tile column in which the first letter of the move's name should be displayed
;                 "SOFTBOILED" is $08 because it has 4 more letters than "SURF", for example, whose value is $0C
FieldMoveDisplayData:
	db CUT, $01, $0C
	db FLY, $02, $0C
	db $B4, $03, $0C ; unused field move
	db SURF, $04, $0C
	db STRENGTH, $05, $0A
	db FLASH, $06, $0C
	db DIG, $07, $0C
	db TELEPORT, $08, $0A
	db SOFTBOILED, $09, $08
	db $ff ; list terminator
