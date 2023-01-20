; **DoClearSaveDialogue**  
; タイトル画面でセーブデータ完全消去のダイアログを出して、プレイヤーに選択させる  
; - - -  
; Yesを選んだらセーブデータを消去して Initへジャンプ  
; Noなら何もせず Initへジャンプ  
DoClearSaveDialogue:
	; VRAMにデータを準備
	call ClearScreen
	call RunDefaultPaletteCommand
	call LoadFontTilePatterns
	call LoadTextBoxTilePatterns

	; "Clear all saved data?"
	ld hl, ClearSaveDataText
	call PrintText

	; No/Yes の 2択Menu を表示し、プレイヤーの選択を待つ
	coord hl, 14, 7
	lb bc, 8, 15
	ld a, NO_YES_MENU
	ld [wTwoOptionMenuID], a
	ld a, TWO_OPTION_MENU
	ld [wTextBoxID], a
	call DisplayTextBoxID

	; No を選んだ
	ld a, [wCurrentMenuItem]
	and a
	jp z, Init

	; Yesを選んだ
	callba ClearSAV
	jp Init

; "Clear all saved data?"
ClearSaveDataText:
	TX_FAR _ClearSaveDataText
	db "@"
