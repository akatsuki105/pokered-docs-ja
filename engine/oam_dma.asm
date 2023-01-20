; 下で定義した関数 DMARoutine をHRAMにコピーする関数  
; OAMDMA中はほかのメモリ領域にはアクセス不可能  
WriteDMACodeToHRAM:
	ld c, $ff80 % $100
	ld b, DMARoutineEnd - DMARoutine
	ld hl, DMARoutine
.copy
	; hlからbバイトを $ff80 にコピー
	ld a, [hli]
	ld [$ff00+c], a
	inc c
	dec b
	jr nz, .copy
	ret

; OAMDMA転送を行う関数 (ROM/RAM -> OAM memory)  
; [wOAMBuffer:wOAMBuffer+160]までをOAMに転送  
; WriteDMACodeToHRAM によって $ff80 に配置されている
DMARoutine:
	; DMAを開始
	ld a, wOAMBuffer / $100
	ld [rDMA], a

	; DMAが終わるまで待機する
	ld a, $28
.wait
	dec a
	jr nz, .wait
	ret
DMARoutineEnd:
