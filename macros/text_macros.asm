
; text macros
text   EQUS "db $00," ; ここからテキストの描画を開始
next   EQUS "db $4e," ; テキスト配置場所を次の行に(単純な改行文字みたいなもの)
line   EQUS "db $4f," ; テキストを (1, 16) から配置 (テキストボックス用の改行文字みたいなもの)
para   EQUS "db $51," ; 次のパラグラフ(セリフの区切り)を開始する
cont   EQUS "db $55," ; 次の行にテキストボックスをスクロールさせる
done   EQUS "db $57"  ; テキストボックスを終了させる。(イベントなし)
prompt EQUS "db $58"  ; テキストボックスを終了させる。(この後ほかのイベントが開始する)

page   EQUS "db $49,"     ; Start a new Pokedex page.
dex    EQUS "db $5f, $50" ; End a Pokedex entry.

; **TX_RAM**  
; $argアドレスの中の文字列を表示する  
; - - -  
; db $1, dw $arg  
TX_RAM: MACRO
	db $1
	dw \1
ENDM

; **SWITCH**  
; SWITCH $XX, addr  
; - - -  
; a == $XX のとき jp addr
SWITCH: macro
if \1 == 0
	and a
else
	cp \1
endc
	jp z, \2
endm

; **SWITCH_CP**  
; SWITCH_CP $XX, addr  
; - - -  
; a == $XX のとき jp addr
SWITCH_CP: macro
	cp \1
	jp z, \2
endm

; **SWITCH_JR**  
; SWITCH_JR $XX, addr  
; - - -  
; a == $XX のとき jr addr
SWITCH_JR: macro
	cp \1
	jr z, \2
endm

; **TX_BCD**  
; BCD数値を表示する  
; - - -  
; db $arg0, $arg1  
; $arg0 = RAM address to read from  
; $arg1 = number of bytes + print flags  
; 
; TextCommand02 に対応  
TX_BCD: MACRO
	db $2
	dw \1
	db \2
ENDM

; **TX_LINE**  
; (1, 16)にテキスト描画先を変更する  
TX_LINE    EQUS "db $05"

; **TX_BLINK**  
; ▼ を点滅させ、A/Bボタンの入力を待つ  
TX_BLINK   EQUS "db $06"

;TX_SCROLL EQUS "db $07"

; **TX_ASM**  
; このマクロ以降のバイト列をMLとしてCPUに実行させる  
TX_ASM     EQUS "db $08"

TX_NUM: MACRO
; print a big-endian decimal number.
; \1: address to read from
; \2: number of bytes to read
; \3: number of digits to display
	db $09
	dw \1
	db \2 << 4 | \3
ENDM

TX_DELAY              EQUS "db $0a"
TX_SFX_ITEM_1         EQUS "db $0b"
TX_SFX_LEVEL_UP       EQUS "db $0b"
;TX_ELLIPSES          EQUS "db $0c"
TX_WAIT               EQUS "db $0d"
;TX_SFX_DEX_RATING    EQUS "db $0e"
TX_SFX_ITEM_2         EQUS "db $10"
TX_SFX_KEY_ITEM       EQUS "db $11"
TX_SFX_CAUGHT_MON     EQUS "db $12"
TX_SFX_DEX_PAGE_ADDED EQUS "db $13"
TX_CRY_NIDORINA       EQUS "db $14"
TX_CRY_PIDGEOT        EQUS "db $15"
;TX_CRY_DEWGONG       EQUS "db $16"

; **TX_FAR**  
; db $17, dw $arg, db BANK($arg)  
; - - -  
; 違うバンクにあるテキストの表示  
TX_FAR: MACRO
	db $17
	dw \1
	db BANK(\1)		; BANK(section_name) => section_nameが配置されるバンクを表すマクロ
ENDM

TX_VENDING_MACHINE         EQUS "db $f5"
TX_CABLE_CLUB_RECEPTIONIST EQUS "db $f6"
TX_PRIZE_VENDOR            EQUS "db $f7"
TX_POKECENTER_PC           EQUS "db $f9"
TX_PLAYERS_PC              EQUS "db $fc"
TX_BILLS_PC                EQUS "db $fd"

TX_MART: MACRO
	db $FE, _NARG
	REPT _NARG
	db \1
	SHIFT
	ENDR
	db $FF
ENDM

TX_POKECENTER_NURSE        EQUS "db $ff"
