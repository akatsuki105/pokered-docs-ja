; \1 = uint8(\2) | uint8(\3)
; 
; INPUT:
; - \1: 2バイトレジスタ e.g. BC, DE
; - \2: 上位バイト
; - \3: 下位バイト
lb: MACRO
	ld \1, ((\2) & $ff) << 8 + ((\3) & $ff)
ENDM

; **homecall**  
; \1で指定された関数をバンクスイッチして実行し、実行後元のバンクに復帰する  
homecall: MACRO
	ld a, [H_LOADEDROMBANK]
	push af
	ld a, BANK(\1)
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	call \1
	pop af
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
ENDM

farcall EQUS "callba"

; far-call dest  
callba: MACRO
	ld b, BANK(\1)
	ld hl, \1
	call Bankswitch
ENDM

callab: MACRO
	ld hl, \1
	ld b, BANK(\1)
	call Bankswitch
ENDM

; far jump
jpba: MACRO
	ld b, BANK(\1)
	ld hl, \1
	jp Bankswitch
ENDM

; far jump
jpab: MACRO
	ld hl, \1
	ld b, BANK(\1)
	jp Bankswitch
ENDM

validateCoords: MACRO
	IF \1 >= SCREEN_WIDTH
		fail "x coord out of range"
	ENDC
	IF \2 >= SCREEN_HEIGHT
		fail "y coord out of range"
	ENDC
ENDM

; レジスタに指定したタイルマップの(X, Y)地点のアドレスを格納する  
; - \1 = r レジスタ  
; - \2 = X タイル(8*8)単位  
; - \3 = Y タイル単位  
; - \4 = どのタイルマップを使うか(指定しない場合はwTileMapという画面のバッファを使う)
coord: MACRO
	validateCoords \2, \3
	IF _NARG >= 4
		ld \1, \4 + SCREEN_WIDTH * \3 + \2
	ELSE
		ld \1, wTileMap + SCREEN_WIDTH * \3 + \2
	ENDC
ENDM

; Aレジスタに指定したタイルマップの(X, Y)地点のアドレスを格納する
; - \1 = X タイル(8*8)単位 
; - \2 = Y タイル単位
; - \3 = どのタイルマップを使うか(指定しない場合はwTileMapという画面のバッファを使う)
aCoord: MACRO
	validateCoords \1, \2
	IF _NARG >= 3
		ld a, [\3 + SCREEN_WIDTH * \2 + \1]
	ELSE
		ld a, [wTileMap + SCREEN_WIDTH * \2 + \1]
	ENDC
ENDM

;\1 = X
;\2 = Y
;\3 = which tilemap (optional)
Coorda: MACRO
	validateCoords \1, \2
	IF _NARG >= 3
		ld [\3 + SCREEN_WIDTH * \2 + \1], a
	ELSE
		ld [wTileMap + SCREEN_WIDTH * \2 + \1], a
	ENDC
ENDM

;\1 = X
;\2 = Y
;\3 = which tilemap (optional)
dwCoord: MACRO
	validateCoords \1, \2
	IF _NARG >= 3
		dw \3 + SCREEN_WIDTH * \2 + \1
	ELSE
		dw wTileMap + SCREEN_WIDTH * \2 + \1
	ENDC
ENDM

;\1 = r
;\2 = X
;\3 = Y
;\4 = map width
overworldMapCoord: MACRO
	ld \1, wOverworldMap + ((\2) + 3) + (((\3) + 3) * ((\4) + (3 * 2)))
ENDM

; macro for two nibbles  
; dn nibble0 nibble1 -> db nibble0 << 4 | nibble1  
dn: MACRO
	db (\1 << 4 | \2)
ENDM

; db \1 した後で dw \2 する
dbw: MACRO
	db \1
	dw \2
ENDM

dba: MACRO
	dbw BANK(\1), \1
ENDM

dwb: MACRO
	dw \1
	db \2
ENDM

dab: MACRO
	dwb \1, BANK(\1)
ENDM

dbbw: MACRO
	db \1, \2
	dw \3
ENDM

; Predef macro.
predef_const: MACRO
	const \1PredefID
ENDM

; バンク番号とアドレスをPredefテーブルに追加する
add_predef: MACRO
\1Predef::
	db BANK(\1)
	dw \1
ENDM

; Aレジスタに指定したpredef-routineのIDを格納
predef_id: MACRO
	ld a, (\1Predef - PredefPointers) / 3
ENDM

; 引数で指定したpredef-routineを呼び出す  
; \1: predefマクロで呼び出すpredef-routine
predef: MACRO
	predef_id \1
	call Predef
ENDM

predef_jump: MACRO
	predef_id \1
	jp Predef
ENDM

tx_pre_const: MACRO
	const \1_id
ENDM

add_tx_pre: MACRO
\1_id:: dw \1
ENDM

db_tx_pre: MACRO
	db (\1_id - TextPredefs) / 2 + 1
ENDM

; 引数で指定したテキストのTextPredefsでのオフセットをaに格納
tx_pre_id: MACRO
	ld a, (\1_id - TextPredefs) / 2 + 1
ENDM

tx_pre: MACRO
	tx_pre_id \1
	call PrintPredefTextID
ENDM

; 引数で指定したPredefTextを表示する
tx_pre_jump: MACRO
	tx_pre_id \1
	jp PrintPredefTextID
ENDM

ldPal: MACRO
	ld \1, \2 << 6 | \3 << 4 | \4 << 2 | \5
ENDM
