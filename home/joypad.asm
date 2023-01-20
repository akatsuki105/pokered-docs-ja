; **ReadJoypad**  
; キー入力を読み取る  
;  
; OUTPUT: [hJoyInput] = [↓, ↑, ←, →, Start, Select, B, A]  
; 本来GameBoyではボタンが押されているときはbitがクリアされるが、ここではボタンが押されているときにbitが立つようにする 
ReadJoypad::
	; 方向キー入力を受け付ける
	ld a, 1 << 5
	ld c, 0
	ld [rJOYP], a	; [rJOYP] = %00100000

	; キー入力がしっかり読み込めるように何回か読み取りを繰り返している(最初のキー入力読み込みは遅延処理のために使うことでキー入力を安定させている)
	rept 6
	ld a, [rJOYP]
	endr
	
	; b[7-4] = [↓, ↑, ←, →]
	cpl
	and %1111
	swap a
	ld b, a

	; a = [↓, ↑, ←, →, Start, Select, B, A]
	ld a, 1 << 4
	ld [rJOYP], a
	rept 10
	ld a, [rJOYP]
	endr
	cpl
	and %1111
	or b

	; hJoyInputに反映
	ld [hJoyInput], a

	; rJOYPをリセットする
	ld a, 1 << 4 + 1 << 5	; %00110000
	ld [rJOYP], a
	ret

; ジョイパッドの状態を記録する変数を更新: 
; 
; OUTPUT:  
; - [hJoyReleased]  今回の_Joypad処理でONからOFFに変わったボタン 
; - [hJoyPressed]   今回の_Joypad処理でOFFからONに変わったボタン 
; - [hJoyHeld] 		現在押されているボタン	[↓, ↑, ←, →, Start, Select, B, A]で押されているボタンはビットが立つ
Joypad::
	homecall _Joypad
	ret
