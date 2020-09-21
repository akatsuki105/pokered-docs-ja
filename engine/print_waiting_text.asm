; 通信対戦で、相手のコマンド選択を待つ際にでる『Waiting...!』というテキストを表示する  
; 日本語ROMなら『つうしんたいきちゅう!』に該当
PrintWaitingText:
	coord hl, 3, 10
	ld b, $1
	ld c, $b

	; 戦闘中でない => .asm_4c17
	jrIfInField .asm_4c17

	call TextBoxBorder
	jr .asm_4c1a
.asm_4c17
	call CableClub_TextBoxBorder
.asm_4c1a
	coord hl, 4, 11
	ld de, WaitingText
	call PlaceString
	ld c, 50
	jp DelayFrames

WaitingText:
	db "Waiting...!@"
