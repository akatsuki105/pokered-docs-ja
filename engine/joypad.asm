; ジョイパッドの状態を記録する変数を更新:  
; - hJoyReleased: (hJoyLast ^ hJoyInput) & hJoyLast  
; - hJoyPressed:  (hJoyLast ^ hJoyInput) & hJoyInput  
; - hJoyLast:     hJoyInput
_Joypad::
	ld a, [hJoyInput]	; [↓, ↑, ←, →, Start, Select, B, A] 押されているときにbitが立つ

	; A,B,Start,Select を同時に押されたときゲームをリセット(タイトル画面に戻る)
	cp A_BUTTON + B_BUTTON + SELECT + START ; soft reset
	jp z, TrySoftReset

	; b = hJoyInput
	; d = (hJoyLast ^ hJoyInput)
	; e = hJoyLast
	ld b, a
	ld a, [hJoyLast]
	ld e, a
	xor b
	ld d, a

	; hJoyReleased = (hJoyLast ^ hJoyInput) & hJoyLast
	and e
	ld [hJoyReleased], a

	; hJoyPressed =  (hJoyLast ^ hJoyInput) & hJoyInput 
	ld a, d
	and b
	ld [hJoyPressed], a

	; hJoyLast = hJoyInput
	ld a, b
	ld [hJoyLast], a

	ld a, [wd730]
	bit 5, a
	jr nz, DiscardButtonPresses

	ld a, [hJoyLast]
	ld [hJoyHeld], a

	ld a, [wJoyIgnore]
	and a
	ret z

	cpl
	ld b, a
	ld a, [hJoyHeld]
	and b
	ld [hJoyHeld], a
	ld a, [hJoyPressed]
	and b
	ld [hJoyPressed], a
	ret

DiscardButtonPresses:
	xor a
	ld [hJoyHeld], a
	ld [hJoyPressed], a
	ld [hJoyReleased], a
	ret

TrySoftReset:
	call DelayFrame

	; deselect (redundant)
	ld a, $30
	ld [rJOYP], a

	ld hl, hSoftReset
	dec [hl]
	jp z, SoftReset

	jp Joypad
