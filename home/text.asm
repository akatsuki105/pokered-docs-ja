; **TextBoxBorder**  
; テキストボックスの枠を描画する  
; - - -  
; c(width) × b(height)分の文字が入るテキストボックスの枠を hl から描画する
TextBoxBorder::

	; ボックスの上枠 ┌--------┐ 
	push hl	; HLに文字を入れると描画されるようにするので元のHLを取っておく
	ld a, "┌"
	ld [hli], a ; AレジスタをHLをアドレスとするメモリに入れた後HL++する
	inc a ; ─
	call NPlaceChar
	inc a ; ┐
	ld [hl], a
	pop hl

	ld de, SCREEN_WIDTH
	add hl, de

	; 真ん中の行 │        │ 
.next
; {
	push hl
	ld a, "│"
	ld [hli], a
	ld a, " "	; テキストボックスの中身は空白
	call NPlaceChar
	ld [hl], "│"
	pop hl
	; 次の行へ
	ld de, SCREEN_WIDTH
	add hl, de
	dec b
	jr nz, .next
; }

	; ボックスの下枠 └--------┘
	ld a, "└"
	ld [hli], a
	ld a, "─"
	call NPlaceChar
	ld [hl], "┘"
	ret

; **NPlaceChar**  
; aレジスタ の文字を c回だけ hl に描画
NPlaceChar::
	ld d, c
.loop
	ld [hli], a
	dec d
	jr nz, .loop
	ret

; **PlaceString**  
; 終端文字が来るまで文字列を描画する  
; - - -  
; de = 配置対象のテキストのアドレス  
; hl = テキストの配置先  
PlaceString::
	push hl

; **PlaceNextChar**  
; deに配置された文字をhlに描画する  
PlaceNextChar::
	ld a, [de]

	; 描画する文字が @ でない -> Char4ETest(ここから特殊文字かどうかの制御が始まる)
	cp "@"
	jr nz, Char4ETest	; -> .char4FTest

	; @ (終端記号)が来たなら文字列の描画を終える

	; TX_RAMのためにBCにHLの中身を入れる
	; TX_RAM: BCに第一引数で渡されたアドレスの中の文字列を渡す  
	ld b, h
	ld c, l
	pop hl
	ret

; ここから特殊文字かどうか1つ1つ検討していく

; **Char4ETest**  
; 特殊文字のチェック
Char4ETest::
	; 描画文字がnext($4E)なら改行 
	cp $4E ; next
	jr nz, .char4FTest ; 次は line のチェック

	; bc = SCREEN_WIDTH or 2*SCREEN_WIDTH ([hFlags_0xFFF6] の bit1次第)
	ld bc, 2 * SCREEN_WIDTH ; 1行 = 2タイル
	ld a, [hFlags_0xFFF6]
	bit 2, a
	jr z, .ok
	ld bc, SCREEN_WIDTH		; 1行 = 1タイル

.ok
	; hl を改行
	pop hl
	add hl, bc				
	push hl
	jp PlaceNextChar_inc

.char4FTest
	; 描画文字が line($4F) なら改行 
	cp $4F ; line
	jr nz, .next3	; 次はその他特殊文字のチェック

	; テキスト描画場所を (1, 16) に配置
	pop hl
	coord hl, 1, 16	; (1, 16) = テキストボックスの2行目
	push hl
	jp PlaceNextChar_inc

.next3
	; 描画対象の文字が特殊文字のどれかなら対応するハンドラに飛ぶ
	; SWITCH $XX, addr -> a == $XX のとき jr addr
	SWITCH $00, Char00 ; error
	SWITCH $4C, Char4C ; autocont
	SWITCH $4B, Char4B ; cont_
	SWITCH $51, Char51 ; para
	SWITCH $49, Char49 ; page
	SWITCH $52, Char52 ; player
	SWITCH $53, Char53 ; rival
	SWITCH $54, Char54 ; POKé
	SWITCH $5B, Char5B ; PC
	SWITCH $5E, Char5E ; ROCKET
	SWITCH $5C, Char5C ; TM
	SWITCH $5D, Char5D ; TRAINER
	SWITCH $55, Char55 ; cont
	SWITCH $56, Char56 ; 6 dots
	SWITCH $57, Char57 ; done
	SWITCH $58, Char58 ; prompt
	SWITCH $4A, Char4A ; PKMN
	SWITCH $5F, Char5F ; dex
	SWITCH $59, Char59 ; TARGET
	SWITCH $5A, Char5A ; USER

	; 通常文字の場合は文字を描画して遅延処理
	ld [hli], a
	call PrintLetterDelay
	; jr PlaceNextChar_inc (fallthrough)

; 次の文字を描画
PlaceNextChar_inc::
	inc de
	jp PlaceNextChar

Char00::
	ld b, h
	ld c, l
	pop hl
	ld de, Char00Text
	dec de
	ret

Char00Text:: ; “%d ERROR.”
	TX_FAR _Char00Text
	db "@"

Char52:: ; player’s name
	push de
	ld de, wPlayerName
	jr FinishDTE

Char53:: ; rival’s name
	push de
	ld de, wRivalName
	jr FinishDTE

Char5D:: ; TRAINER
	push de
	ld de, Char5DText
	jr FinishDTE

Char5C:: ; TM
	push de
	ld de, Char5CText
	jr FinishDTE

Char5B:: ; PC
	push de
	ld de, Char5BText
	jr FinishDTE

Char5E:: ; ROCKET
	push de	; 現在の文字ポインタを保存
	ld de, Char5EText ; ROCKET@を入れる
	jr FinishDTE ; 次の終端記号@(ROCKETの終わり)まで描画して、カーソルをROCKETの次の文字にして戻ってくる

Char54:: ; POKé
	push de
	ld de, Char54Text
	jr FinishDTE

Char56:: ; ……
	push de
	ld de, Char56Text
	jr FinishDTE

Char4A:: ; PKMN
	push de
	ld de, Char4AText
	jr FinishDTE

Char59::
; depending on whose turn it is, print
; enemy active monster’s name, prefixed with “Enemy ”
; or
; player active monster’s name
; (like Char5A but flipped)
	ld a, [H_WHOSETURN]
	xor 1
	jr MonsterNameCharsCommon

Char5A::
; depending on whose turn it is, print
; player active monster’s name
; or
; enemy active monster’s name, prefixed with “Enemy ”
	ld a, [H_WHOSETURN]
MonsterNameCharsCommon::
	push de
	and a
	jr nz, .Enemy
	ld de, wBattleMonNick ; player active monster name
	jr FinishDTE

.Enemy
	; print “Enemy ”
	ld de, Char5AText
	call PlaceString
	ld h, b
	ld l, c
	ld de, wEnemyMonNick ; enemy active monster name

; **FinishDTE**  
; 特殊文字に対応する文字列を全部描画する  
; - - -  
; 特殊文字は必ず@で終わっていることに留意する  
; FinishDTE実行前にpush deによりどの文字まで描画したかが保存されている  
; 特殊文字の描画は通常の文字列描画に対する割り込み処理と考えると理解しやすいかも  
; 特殊文字の描画が終わったらpop deにより中断した文字列描画から復帰して戻る  
FinishDTE::
	call PlaceString
	ld h, b
	ld l, c
	pop de
	inc de
	jp PlaceNextChar

Char5CText::
	db "TM@"
Char5DText::
	db "TRAINER@"
Char5BText::
	db "PC@"
Char5EText::
	db "ROCKET@"
Char54Text::
	db "POKé@"
Char56Text::
	db "……@"
Char5AText::
	db "Enemy @"
Char4AText::
	db $E1,$E2,"@" ; PKMN

Char55::
	push de
	ld b, h
	ld c, l
	ld hl, Char55Text
	call TextCommandProcessor
	ld h, b
	ld l, c
	pop de
	inc de
	jp PlaceNextChar

Char55Text::
; equivalent to Char4B
	TX_FAR _Char55Text
	db "@"

Char5F::
; ends a Pokédex entry
	ld [hl], "."
	pop hl
	ret

Char58:: ; prompt
	ld a, [wLinkState]
	cp LINK_STATE_BATTLING
	jp z, .ok

	ld a, "▼"
	Coorda 18, 16
.ok
	call ProtectedDelay3
	call ManualTextScroll
	ld a, " "
	Coorda 18, 16
	; Char57(fallthrough)

Char57:: ; done
	pop hl
	ld de, Char58Text
	dec de
	ret

Char58Text::
	db "@"

Char51:: ; para
	push de

	; "▼"を点滅させながら A/Bボタンの入力を待つ
	ld a, "▼"
	Coorda 18, 16
	call ProtectedDelay3
	call ManualTextScroll

	coord hl, 1, 13
	lb bc, 4, 18
	call ClearScreenArea
	ld c, 20
	call DelayFrames

	pop de
	coord hl, 1, 14
	jp PlaceNextChar_inc

Char49::
	push de
	ld a, "▼"
	Coorda 18, 16
	call ProtectedDelay3
	call ManualTextScroll
	coord hl, 1, 10
	lb bc, 7, 18
	call ClearScreenArea
	ld c, 20
	call DelayFrames
	pop de
	pop hl
	coord hl, 1, 11
	push hl
	jp PlaceNextChar_inc

Char4B::
	ld a, "▼"
	Coorda 18, 16
	call ProtectedDelay3
	push de
	call ManualTextScroll
	pop de
	ld a, " "
	Coorda 18, 16
	;fall through
Char4C::
	push de
	call ScrollTextUpOneLine
	call ScrollTextUpOneLine
	coord hl, 1, 16
	pop de
	jp PlaceNextChar_inc

; 2行のテキストが表示されたテキストボックスを1行上にスクロールさせる  
; この処理は2回連続して呼ばれる  
; 1回目: 2行のテキストを『in between』行という常に空白の行にコピーする(スクロールのアニメーションを表現するため？)  
; 2回目: 2行目のテキストを1行目にコピーする  
ScrollTextUpOneLine::
	coord hl, 0, 14 ; top row of text
	coord de, 0, 13 ; empty line above text
	ld b, SCREEN_WIDTH * 3
.copyText
	ld a, [hli]
	ld [de], a
	inc de
	dec b
	jr nz, .copyText
	coord hl, 1, 16
	ld a, " "
	ld b, SCREEN_WIDTH - 2
.clearText
	ld [hli], a
	dec b
	jr nz, .clearText

	; wait five frames
	ld b, 5
.WaitFrame
	call DelayFrame
	dec b
	jr nz, .WaitFrame

	ret

; bc の値が変わらない Delay3
ProtectedDelay3::
	push bc
	call Delay3
	pop bc
	ret

; **TextCommandProcessor**  
; - - -  
; 文字の描画が目的ではなくテキストデータを命令として扱う  
; INPUT:  
; bc = 描画先  
; hl = 処理対象のテキスト  
TextCommandProcessor::
	; wLetterPrintingDelayFlags を退避
	ld a, [wLetterPrintingDelayFlags]
	push af

	; TODO: ポケモン図鑑のみの処理
	set 1, a
	ld e, a
	ld a, [$fff4]
	xor e	; [wLetterPrintingDelayFlags] | [$fff4]
	ld [wLetterPrintingDelayFlags], a

	; [wTextDest] = 描画先
	ld a, c
	ld [wTextDest], a
	ld a, b
	ld [wTextDest + 1], a
	; fallthrough

NextTextCommand::
	ld a, [hli]	; a = 文字

	; @でない -> .doTextCommand
	cp "@"
	jr nz, .doTextCommand

	; @なら終了
	pop af
	ld [wLetterPrintingDelayFlags], a
	ret

.doTextCommand
	push hl ; コマンドを保存しておく

	; 文字が $17(TX_FAR) -> TextCommand17
	cp $17
	jp z, TextCommand17

	; (文字 >= 0x0e) -> TextCommand0B
	cp $0e
	jp nc, TextCommand0B

	; 対応するTextCommandJumpTable のエントリにジャンプ
	ld hl, TextCommandJumpTable
	push bc
	add a
	ld b, 0
	ld c, a
	add hl, bc
	pop bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp hl

; draw box
; 04AAAABBCC
; AAAA = address of upper left corner
; BB = height
; CC = width
TextCommand04::
	pop hl
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld b, a
	ld a, [hli]
	ld c, a
	push hl
	ld h, d
	ld l, e
	call TextBoxBorder
	pop hl
	jr NextTextCommand

; **TextCommand00**  
; textマクロのためのテキストコマンド    
; - - -  
; 以降のテキストコマンドを単純な文字列として描画する  
TextCommand00::
	pop hl
	ld d, h
	ld e, l
	ld h, b
	ld l, c
	call PlaceString
	ld h, d
	ld l, e
	inc hl
	jr NextTextCommand

; **TextCommand01**  
; TX_RAM のためのテキストコマンド  
; - - -  
; RAM内の文字列を描画する  
TextCommand01::
	pop hl
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	push hl
	ld h, b
	ld l, c
	call PlaceString
	pop hl
	jr NextTextCommand

; print BCD number
; 02AAAABB
; AAAA = address of BCD number
; BB
; bits 0-4 = length in bytes
; bits 5-7 = unknown flags
TextCommand02::
	pop hl
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hli]
	push hl
	ld h, b
	ld l, c
	ld c, a
	call PrintBCDNumber
	ld b, h
	ld c, l
	pop hl
	jr NextTextCommand

; repoint destination address
; 03AAAA
; AAAA = new destination address
TextCommand03::
	pop hl
	ld a, [hli]
	ld [wTextDest], a
	ld c, a
	ld a, [hli]
	ld [wTextDest + 1], a
	ld b, a
	jp NextTextCommand

; repoint destination to second line of dialogue text box
; 05
; (no arguments)
TextCommand05::
	pop hl
	coord bc, 1, 16 ; address of second line of dialogue text box
	jp NextTextCommand

; blink arrow and wait for A or B to be pressed
; 06
; (no arguments)
TextCommand06::
	ld a, [wLinkState]
	cp LINK_STATE_BATTLING
	jp z, TextCommand0D
	ld a, "▼"
	Coorda 18, 16 ; place down arrow in lower right corner of dialogue text box
	push bc
	call ManualTextScroll ; blink arrow and wait for A or B to be pressed
	pop bc
	ld a, " "
	Coorda 18, 16 ; overwrite down arrow with blank space
	pop hl
	jp NextTextCommand

; scroll text up one line
; 07
; (no arguments)
TextCommand07::
	ld a, " "
	Coorda 18, 16 ; place blank space in lower right corner of dialogue text box
	call ScrollTextUpOneLine
	call ScrollTextUpOneLine
	pop hl
	coord bc, 1, 16 ; address of second line of dialogue text box
	jp NextTextCommand

; execute asm inline
; 08{code}
TextCommand08::
	pop hl
	ld de, NextTextCommand
	push de ; return address
	jp hl

; print decimal number (converted from binary number)
; 09AAAABB
; AAAA = address of number
; BB
; bits 0-3 = how many digits to display
; bits 4-7 = how long the number is in bytes
TextCommand09::
	pop hl
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hli]
	push hl
	ld h, b
	ld l, c
	ld b, a
	and $0f
	ld c, a
	ld a, b
	and $f0
	swap a
	set BIT_LEFT_ALIGN,a
	ld b, a
	call PrintNumber
	ld b, h
	ld c, l
	pop hl
	jp NextTextCommand

; wait half a second if the user doesn't hold A or B
; 0A
; (no arguments)
TextCommand0A::
	push bc
	call Joypad
	ld a, [hJoyHeld]
	and A_BUTTON | B_BUTTON
	jr nz, .skipDelay
	ld c, 30
	call DelayFrames
.skipDelay
	pop bc
	pop hl
	jp NextTextCommand

; **TextCommand0B**  
; 音を鳴らすテキストコマンド  
; - - -  
; $0b 以外のテキストコマンドにも対応している  
TextCommand0B::
	pop hl
	push bc

	; b = このコマンドで描画対象の文字
	dec hl
	ld a, [hli]
	ld b, a

	push hl
	ld hl, TextCommandSounds

; TextCommandSoundsの中からTextCmdIDと一致するエントリを探す
.loop
; {
	ld a, [hli]
	cp b
	jr z, .matchFound
	inc hl
	jr .loop
; }

.matchFound
	SWITCH_JR $14, .pokemonCry
	SWITCH_JR $15, .pokemonCry
	SWITCH_JR $16, .pokemonCry

	ld a, [hl]	; a = SoundID
	call PlaySound
	call WaitForSoundToFinish

	pop hl
	pop bc
	jp NextTextCommand

.pokemonCry
	push de
	ld a, [hl]
	call PlayCry
	pop de
	pop hl
	pop bc
	jp NextTextCommand

; TextCmdID -> SoundID or CryID のマッピング
TextCommandSounds::
	db $0B, SFX_GET_ITEM_1 ; actually plays SFX_LEVEL_UP when the battle music engine is loaded
	db $12, SFX_CAUGHT_MON
	db $0E, SFX_POKEDEX_RATING ; unused?
	db $0F, SFX_GET_ITEM_1 ; unused?
	db $10, SFX_GET_ITEM_2
	db $11, SFX_GET_KEY_ITEM
	db $13, SFX_DEX_PAGE_ADDED
	db $14, NIDORINA ; used in OakSpeech
	db $15, PIDGEOT  ; used in SaffronCityText12
	db $16, DEWGONG  ; unused?

; draw ellipses
; 0CAA
; AA = number of ellipses to draw
TextCommand0C::
	pop hl
	ld a, [hli]
	ld d, a
	push hl
	ld h, b
	ld l, c
.loop
	ld a, "…"
	ld [hli], a
	push de
	call Joypad
	pop de
	ld a, [hJoyHeld] ; joypad state
	and A_BUTTON | B_BUTTON
	jr nz, .skipDelay ; if so, skip the delay
	ld c, 10
	call DelayFrames
.skipDelay
	dec d
	jr nz, .loop
	ld b, h
	ld c, l
	pop hl
	jp NextTextCommand

; wait for A or B to be pressed
; 0D
; (no arguments)
TextCommand0D::
	push bc
	call ManualTextScroll ; wait for A or B to be pressed
	pop bc
	pop hl
	jp NextTextCommand

; **TextCommand17**  
; TX_FAR のためのテキストコマンド  
; - - -  
; 別のROMバンクにあるテキストコマンドを処理する   
TextCommand17::
	; テキストコマンドのあるバンク番号にスイッチ
	pop hl
	ld a, [H_LOADEDROMBANK]
	push af
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a		; de = テキストコマンドのアドレス
	ld a, [hli]	; a = テキストコマンドのあるバンク番号
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	
	; 終端記号までテキストコマンドを処理
	push hl
	ld l, e
	ld h, d
	call TextCommandProcessor
	pop hl

	; バンクを復帰して次へ
	pop af
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	jp NextTextCommand

TextCommandJumpTable::
	dw TextCommand00
	dw TextCommand01
	dw TextCommand02
	dw TextCommand03
	dw TextCommand04
	dw TextCommand05
	dw TextCommand06
	dw TextCommand07
	dw TextCommand08
	dw TextCommand09
	dw TextCommand0A
	dw TextCommand0B
	dw TextCommand0C
	dw TextCommand0D
