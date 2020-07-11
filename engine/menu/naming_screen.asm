AskName:
	call SaveScreenTilesToBuffer1
	call GetPredefRegisters
	push hl
	ld a, [wIsInBattle]
	dec a
	coord hl, 0, 0
	ld b, 4
	ld c, 11
	call z, ClearScreenArea ; only if in wild battle
	ld a, [wcf91]
	ld [wd11e], a
	call GetMonName
	ld hl, DoYouWantToNicknameText
	call PrintText
	coord hl, 14, 7
	lb bc, 8, 15
	ld a, TWO_OPTION_MENU
	ld [wTextBoxID], a
	call DisplayTextBoxID
	pop hl
	ld a, [wCurrentMenuItem]
	and a
	jr nz, .declinedNickname
	ld a, [wUpdateSpritesEnabled]
	push af
	xor a
	ld [wUpdateSpritesEnabled], a
	push hl
	ld a, NAME_MON_SCREEN
	ld [wNamingScreenType], a
	call DisplayNamingScreen
	ld a, [wIsInBattle]
	and a
	jr nz, .inBattle
	call ReloadMapSpriteTilePatterns
.inBattle
	call LoadScreenTilesFromBuffer1
	pop hl
	pop af
	ld [wUpdateSpritesEnabled], a
	ld a, [wcf4b]
	cp "@"
	ret nz
.declinedNickname
	ld d, h
	ld e, l
	ld hl, wcd6d
	ld bc, NAME_LENGTH
	jp CopyData

DoYouWantToNicknameText:
	TX_FAR _DoYouWantToNicknameText
	db "@"

DisplayNameRaterScreen:
	ld hl, wBuffer
	xor a
	ld [wUpdateSpritesEnabled], a
	ld a, NAME_MON_SCREEN
	ld [wNamingScreenType], a
	call DisplayNamingScreen
	call GBPalWhiteOutWithDelay3
	call RestoreScreenTilesAndReloadTilePatterns
	call LoadGBPal
	ld a, [wcf4b]
	cp "@"
	jr z, .playerCancelled
	ld hl, wPartyMonNicks
	ld bc, NAME_LENGTH
	ld a, [wWhichPokemon]
	call AddNTimes
	ld e, l
	ld d, h
	ld hl, wBuffer
	ld bc, NAME_LENGTH
	call CopyData
	and a
	ret
.playerCancelled
	scf
	ret

; **DisplayNamingScreen**  
; テキスト入力ウィンドウを出し、プレイヤーが入力し終えるのを待つ  
; - - -  
; INPUT: hl = wPlayerName or wRivalName or ???
; OUTPUT: 
; - [wcf4b] = 入力された名前  
; - [wPlayerName] or [wRivalName] or [???] = 入力された名前  
DisplayNamingScreen:
	push hl
	; 遅延を発生
	ld hl, wd730
	set 6, [hl]
	
	; 画面を真っ白にする
	call GBPalWhiteOutWithDelay3
	call ClearScreen
	call UpdateSprites

	; SGBのときのみ機能
	ld b, SET_PAL_GENERIC
	call RunPaletteCommand

	call LoadHpBarAndStatusTilePatterns
	call LoadEDTile
	callba LoadMonPartySpriteGfx

	; キーボードとなるテキストボックスを描画
	coord hl, 0, 4
	ld b, 9
	ld c, 18
	call TextBoxBorder
	
	; 入力を促すテキスト
	call PrintNamingText

	; メニューカーソルの左上にキーボード『A』 を設定
	ld a, 3
	ld [wTopMenuItemY], a
	ld a, 1
	ld [wTopMenuItemX], a
	; メニューカーソルの初期値にキーボード『A』 を設定
	ld [wLastMenuItem], a
	ld [wCurrentMenuItem], a
	; 全部のキー入力をハンドルする
	ld a, $ff
	ld [wMenuWatchedKeys], a

	ld a, 7
	ld [wMaxMenuItem], a

	ld a, "@"
	ld [wcf4b], a
	
	xor a
	ld hl, wNamingScreenSubmitName
	ld [hli], a
	ld [hli], a						; [wNamingScreenSubmitName] = 0
	ld [wAnimCounter], a			; [wAnimCounter] = 0

; 初期化処理かつボタンが押された時の処理
	; selectボタンが押された時(大文字小文字を切り替える)
.selectReturnPoint
	call PrintAlphabet
	call GBPalNormal
	; ABStartボタンが押された時
.ABStartReturnPoint
	; [wNamingScreenSubmitName] != 0 -> .submitNickname
	ld a, [wNamingScreenSubmitName]
	and a
	jr nz, .submitNickname
	call PrintNicknameAndUnderscores
	; 方向キーが押された時
.dPadReturnPoint
	call PlaceMenuCursor

; ボタンが押されていない時名前入力画面でこの.inputLoop処理をループし続ける
.inputLoop
	ld a, [wCurrentMenuItem]
	
	; 名前をつける対象のポケモンのアイコンを動かす
	push af
	callba AnimatePartyMon_ForceSpeed1
	pop af
	
	ld [wCurrentMenuItem], a
	call JoypadLowSensitivity
	
	; ボタンが押されてないときはループ
	ld a, [hJoyPressed]
	and a
	jr z, .inputLoop

	ld hl, .namingScreenButtonFunctions

; hl = (.namingScreenButtonFunctions + 4*i)　を代入 -> .foundPressedButton
; [↓, ↑, ←, →, Start, Select, B, A] -> i = [0, 1, 2, 3, 4, 5, 6, 7]
.checkForPressedButton
	sla a
	jr c, .foundPressedButton
	inc hl
	inc hl
	inc hl
	inc hl
	jr .checkForPressedButton

; 押されたボタンに対応するハンドラのアドレスを de, hlに代入してhlにジャンプ
.foundPressedButton
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a		; e.g. de = .ABStartReturnPoint
	ld a, [hli]
	ld h, [hl]
	ld l, a		; e.g. hl = .pressedA
	push de		; hlのハンドラでのreturn先
	jp hl		; .pressedXに飛ぶ

; STARTか"ED"が押された時
.submitNickname
	; 名前入力結果を格納する
	pop de ; de = wPlayerName or wRivalName or ???
	ld hl, wcf4b
	ld bc, NAME_LENGTH
	call CopyData
	; 画面に関する変数をクリア
	call GBPalWhiteOutWithDelay3
	call ClearScreen
	call ClearSprites
	call RunDefaultPaletteCommand
	call GBPalNormal
	xor a
	ld [wAnimCounter], a
	ld hl, wd730
	res 6, [hl]
	; バトル中 -> LoadHudTilePatterns
	; それ以外 -> LoadTextBoxTilePatterns
	ld a, [wIsInBattle]
	and a
	jp z, LoadTextBoxTilePatterns ; ここで ret
	jpab LoadHudTilePatterns	  ; ここで ret

.namingScreenButtonFunctions
	dw .dPadReturnPoint
	dw .pressedDown
	dw .dPadReturnPoint
	dw .pressedUp
	dw .dPadReturnPoint
	dw .pressedLeft
	dw .dPadReturnPoint
	dw .pressedRight
	dw .ABStartReturnPoint
	dw .pressedStart
	dw .selectReturnPoint
	dw .pressedSelect
	dw .ABStartReturnPoint
	dw .pressedB
	dw .ABStartReturnPoint
	dw .pressedA

; 大文字小文字反転のところでAボタンが押された時の処理  
; セレクトが押された時と同じ処理
.pressedA_changedCase
	pop de
	ld de, .selectReturnPoint
	push de

; 名前入力画面でセレクトボタンを押されたときの処理  
; 大文字小文字を反転  
.pressedSelect
	ld a, [wAlphabetCase]
	xor $1
	ld [wAlphabetCase], a 	; [wAlphabetCase] の bitを反転
	ret						; jp .selectReturnPoint 

; 名前入力画面でスタートボタンを押されたときの処理  
; 名前入力を終了
.pressedStart
	ld a, 1
	ld [wNamingScreenSubmitName], a
	ret						; jp .ABStartReturnPoint

.pressedA
	; "ED" を押されたときは .pressedStart で名前入力を終了する
	ld a, [wCurrentMenuItem]
	cp $5 ; "ED" row
	jr nz, .didNotPressED
	ld a, [wTopMenuItemX]
	cp $11 ; "ED" column
	jr z, .pressedStart
	
	; "ED"以外が押された時
.didNotPressED
	; 大文字小文字反転のところでAボタンが押された時  
	ld a, [wCurrentMenuItem]
	cp $6 ; case switch row
	jr nz, .didNotPressCaseSwtich
	ld a, [wTopMenuItemX]
	cp $1 ; case switch column
	jr z, .pressedA_changedCase
	
	; 普通の文字が押された時
.didNotPressCaseSwtich
	; hl = [wMenuCursorLocation] = メニューカーソルのタイルのアドレス
	ld hl, wMenuCursorLocation
	ld a, [hli]
	ld h, [hl]
	ld l, a

	; a = [メニューカーソル+1] = 指している文字のタイルID = 入力した文字
	inc hl
	ld a, [hl]
	
	; a = [wNamingScreenLetter] = 入力した文字
	; c = 現在入力した文字数
	ld [wNamingScreenLetter], a
	call CalcStringLength
	ld a, [wNamingScreenLetter]

	; 入力した文字が 濁点か半角点のとき -> .dakutensAndHandakutens
	; このとき de には Dakutens or Handakutens
	cp $e5
	ld de, Dakutens
	jr z, .dakutensAndHandakutens
	cp $e4
	ld de, Handakutens
	jr z, .dakutensAndHandakutens

	ld a, [wNamingScreenType]
	cp NAME_MON_SCREEN
	jr nc, .checkMonNameLength

	; 入力できる文字数に空きがある -> .addLetter
	ld a, [wNamingScreenNameLength]
	cp $7 ; max length of player/rival names
	jr .checkNameLength
.checkMonNameLength
	ld a, [wNamingScreenNameLength]
	cp $a ; max length of pokemon nicknames
.checkNameLength
	jr c, .addLetter 	; [wNamingScreenNameLength] < 最大文字数
	ret					; 現在(Aボタンを押した文字を入れることなく)文字数がMAX -> jp .ABStartReturnPoint 
	; 濁点半角点が押された時の処理
.dakutensAndHandakutens
	push hl
	call DakutensAndHandakutens
	pop hl
	ret nc
	dec hl
.addLetter
	; この時点で hl = [wcf4b] の名前が格納されている場所の末尾@
	ld a, [wNamingScreenLetter] ; a = 入力した文字
	; "...@" -> "...X@"
	ld [hli], a					
	ld [hl], "@"
	; ボタン入力サウンドを出す
	ld a, SFX_PRESS_AB
	call PlaySound
	ret		; jp .ABStartReturnPoint

	; Bボタンが押された時
.pressedB
	; 入力している文字がない -> ret
	ld a, [wNamingScreenNameLength]
	and a
	ret z
	; 末尾の文字を@にして ret ("...X@" -> "...@@")
	call CalcStringLength
	dec hl
	ld [hl], "@"
	ret	; jp .ABStartReturnPoint

	; 右が押された時
.pressedRight
	; caseにカーソルがきているときは何もしない
	ld a, [wCurrentMenuItem]
	cp $6
	ret z ; can't scroll right on bottom row
	; 一番右で右押された時は左端に戻る
	ld a, [wTopMenuItemX]
	cp $11 ; max
	jp z, .wrapToFirstColumn
	; [wTopMenuItemX]をインクリメント
	inc a
	inc a
	jr .done
.wrapToFirstColumn
	ld a, $1
	jr .done
	; 左が押された時(右と同様)
.pressedLeft
	ld a, [wCurrentMenuItem]
	cp $6
	ret z ; can't scroll right on bottom row
	ld a, [wTopMenuItemX]
	dec a
	jp z, .wrapToLastColumn
	dec a
	jr .done
.wrapToLastColumn
	ld a, $11 ; max
	jr .done
	; 上が押された時
.pressedUp
	; [wCurrentMenuItem]
	ld a, [wCurrentMenuItem]
	dec a
	ld [wCurrentMenuItem], a
	and a
	ret nz
	; [wCurrentMenuItem] = 0のときは一番下にいく(xは左端に設定)
	ld a, $6 ; wrap to bottom row
	ld [wCurrentMenuItem], a
	ld a, $1 ; force left column
	jr .done
	; 下が押された時(上と同様)
.pressedDown
	ld a, [wCurrentMenuItem]
	inc a
	ld [wCurrentMenuItem], a
	cp $7
	jr nz, .wrapToTopRow
	ld a, $1
	ld [wCurrentMenuItem], a
	jr .done
.wrapToTopRow
	cp $6
	ret nz
	ld a, $1
.done
	; メニューのx座標を更新 -> EraseMenuCursor
	ld [wTopMenuItemX], a
	jp EraseMenuCursor ; EraseMenuCursorでreturnする

; ED_TileをVRAMに転送する
LoadEDTile:
	ld de, ED_Tile
	ld hl, vFont + $700
	ld bc, (ED_TileEnd - ED_Tile) / $8
	; to fix the graphical bug on poor emulators
	;lb bc, BANK(ED_Tile), (ED_TileEnd - ED_Tile) / $8
	jp CopyVideoDataDouble

ED_Tile:
	INCBIN "gfx/ED_tile.1bpp"
ED_TileEnd:

; **PrintAlphabet**  
; 英語キーボードを画面に表示する  
; - - -  
; 名前入力ウィンドウで使用  
; INPUT:   
; - [wAlphabetCase] = 0(小文字) or 1(大文字)
PrintAlphabet:
	; VRAM転送を無効化
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a
	; de = LowerCaseAlphabet or UpperCaseAlphabet
	ld a, [wAlphabetCase]
	and a
	ld de, LowerCaseAlphabet
	jr nz, .lowercase
	ld de, UpperCaseAlphabet
.lowercase
	; ここから英語キーボードの表示を開始
	coord hl, 2, 5	; (2, 5)からアルファベットの描画を開始
	lb bc, 5, 9 	; 5行9列

; ループごとに1行描画して5行描画する
.outerLoop
	push bc

	; ループごとに1文字ずつ描画して1行描画する
.innerLoop
	ld a, [de]
	ld [hli], a
	inc hl
	inc de ; [hl++] = [de++]
	dec c
	jr nz, .innerLoop

	ld bc, SCREEN_WIDTH + 2
	add hl, bc
	pop bc
	dec b
	jr nz, .outerLoop
; outerLoopを抜けた(lower case, UPPER CASE)をテキストボックスの外に描画
	call PlaceString
	ld a, $1
	ld [H_AUTOBGTRANSFERENABLED], a
	jp Delay3	; Delay3でreturnする

; db "abcdefghijklmnopqrstuvwxyz ×():;[]",$e1,$e2,"-?!♂♀/⠄,¥UPPER CASE@"
LowerCaseAlphabet:
	db "abcdefghijklmnopqrstuvwxyz ×():;[]",$e1,$e2,"-?!♂♀/⠄,¥UPPER CASE@"

; db "ABCDEFGHIJKLMNOPQRSTUVWXYZ ×():;[]",$e1,$e2,"-?!♂♀/⠄,¥lower case@"
UpperCaseAlphabet:
	db "ABCDEFGHIJKLMNOPQRSTUVWXYZ ×():;[]",$e1,$e2,"-?!♂♀/⠄,¥lower case@"

; **PrintNicknameAndUnderscores**  
; 入力した名前を下線とともに名前入力画面に表示する
PrintNicknameAndUnderscores:
	; [wNamingScreenNameLength] = ニックネームの長さ
	call CalcStringLength
	ld a, c
	ld [wNamingScreenNameLength], a

	; 入力した名前を表示欄からクリア
	coord hl, 10, 2
	lb bc, 1, 10
	call ClearScreenArea
	; 入力した名前を表示
	coord hl, 10, 2
	ld de, wcf4b
	call PlaceString

; ここから入力した名前を表示するところを描画する
	coord hl, 10, 3

	; b = 名前の最大文字数 7(主人公ライバル) or 10(ポケモンのニックネーム)
	ld a, [wNamingScreenType]
	cp NAME_MON_SCREEN
	jr nc, .pokemon1
	ld b, 7 ; player or rival max name length
	jr .playerOrRival1
.pokemon1
	ld b, 10 ; pokemon max name length
.playerOrRival1
	
; 下線を配置する(この上に名前が表示される)
	ld a, $76 ; 下線のタイルID
.placeUnderscoreLoop
	ld [hli], a
	dec b
	jr nz, .placeUnderscoreLoop

; 入力した文字数がMAXでない -> .emptySpacesRemaining
	ld a, [wNamingScreenType]
	cp NAME_MON_SCREEN
	ld a, [wNamingScreenNameLength]
	jr nc, .pokemon2
	cp 7 ; player or rival max name length
	jr .playerOrRival2
.pokemon2
	cp 10 ; pokemon max name length
.playerOrRival2
	jr nz, .emptySpacesRemaining

; 最大文字数まで名前を入力したとき
	; カーソルを強制的に 『ED』 に配置する
	call EraseMenuCursor
	ld a, $11 ; "ED" x coord
	ld [wTopMenuItemX], a
	ld a, $5 ; "ED" y coord
	ld [wCurrentMenuItem], a
	; a = 6(主人公ライバル) or 9(ポケモン)
	ld a, [wNamingScreenType]
	cp NAME_MON_SCREEN
	ld a, 9 ; keep the last underscore raised
	jr nc, .pokemon3
	ld a, 6 ; keep the last underscore raised
.pokemon3

; まだ文字数が余っているときは次の文字が入る下線を持ち上げる
.emptySpacesRemaining
	ld c, a
	ld b, $0
	coord hl, 10, 3
	add hl, bc		; hl = 次の文字が入る場所
	ld [hl], $77 	; raised underscore tile id
	ret

DakutensAndHandakutens:
	push de ; push Dakutens or Handakutens
	call CalcStringLength

	; 名前の最後の文字 e.g. 『あか』 + 『゛』 -> 『か』
	dec hl
	ld a, [hl]

	; 名前の最後の文字が 濁点 か 半角点 に対応している文字が確認
	pop hl ; hl = Dakutens or Handakutens
	ld de, $2
	call IsInArray
	ret nc	; 対応していない -> jp .ABStartReturnPoint

	; 最後に入力された文字を濁点(半角点)付きに変えて終了
	inc hl
	ld a, [hl]
	ld [wNamingScreenLetter], a
	ret	; jp .ABStartReturnPoint

Dakutens:
	db "かが", "きぎ", "くぐ", "けげ", "こご"
	db "さざ", "しじ", "すず", "せぜ", "そぞ"
	db "ただ", "ちぢ", "つづ", "てで", "とど"
	db "はば", "ひび", "ふぶ", "へべ", "ほぼ"
	db "カガ", "キギ", "クグ", "ケゲ", "コゴ"
	db "サザ", "シジ", "スズ", "セゼ", "ソゾ"
	db "タダ", "チヂ", "ツヅ", "テデ", "トド"
	db "ハバ", "ヒビ", "フブ", "へべ", "ホボ"
	db $ff

Handakutens:
	db "はぱ", "ひぴ", "ふぷ", "へぺ", "ほぽ"
	db "ハパ", "ヒピ", "フプ", "へぺ", "ホポ"
	db $ff

; wcf4bに格納された文字列の長さを計算してcレジスタに格納する  
; 終了時 hl は "@" を指している
CalcStringLength:
	ld hl, wcf4b
	ld c, $0
.loop
	ld a, [hl]
	cp "@"
	ret z
	inc hl
	inc c
	jr .loop

; **PrintNamingText**  
; 名前入力を促すテキストを表示する  
; - - -  
; INPUT:  [wNamingScreenType] = 名前入力のタイプ  
; 0: YOUR NAME? を表示  
; 1: RIVAL's NAME? を表示  
; other: ポケモンのアイコン,種族名,NICKNAME? を表示 (https://imgur.com/ym8Ogbz)
PrintNamingText:
	coord hl, 0, 1

	; 主人公の名前の場合 -> YOUR NAME?
	ld a, [wNamingScreenType]
	ld de, YourTextString
	and a
	jr z, .notNickname

	; ライバルのの名前の場合 -> RIVAL's NAME?
	ld de, RivalsTextString
	dec a
	jr z, .notNickname

	; ポケモンのニックネームの場合 -> ポケモンのアイコン,種族名,NICKNAME? (https://imgur.com/ym8Ogbz)
	ld a, [wcf91]
	ld [wMonPartySpriteSpecies], a
	push af
	callba WriteMonPartySpriteOAMBySpecies
	pop af
	ld [wd11e], a
	call GetMonName
	coord hl, 4, 1
	call PlaceString
	ld hl, $1
	add hl, bc
	ld [hl], $c9
	coord hl, 1, 3
	ld de, NicknameTextString
	jr .placeString

.notNickname
	call PlaceString
	ld l, c
	ld h, b
	ld de, NameTextString
.placeString
	jp PlaceString

; "YOUR @"
YourTextString:
	db "YOUR @"

; "RIVAL's @"
RivalsTextString:
	db "RIVAL's @"

NameTextString:
	db "NAME?@"

NicknameTextString:
	db "NICKNAME?@"
