; **LoadGBPal**  
; パレットに FadePal${N} をロードする  
; - - -  
; 基準は ゲームの通常状態のパレット の FadePal4  
; マップの切り替え時に利用されたりする  
; 
; INPUT: [wMapPalOffset] = FadePal4 から差し引くオフセット  
; 
; 例えば 暗いマップでは [wMapPalOffset] = 6なので  
; `FadePal4 - 6 = FadePal2`  
; となり、画面が黒くなる  
LoadGBPal::

	; hl = FadePal4 - wMapPalOffset
	; 例えば 暗いマップでは [wMapPalOffset] = 6なので hl = FadePal4 - 6 = FadePal2 となり、画面が黒くなる 
	ld a, [wMapPalOffset] ; tells if wCurMap is dark (requires HM5_FLASH?)
	ld b, a
	ld hl, FadePal4
	ld a, l
	sub b
	ld l, a
	jr nc, .ok
	dec h
.ok

	; パレットに hl をロード
	ld a, [hli]
	ld [rBGP], a
	ld a, [hli]
	ld [rOBP0], a
	ld a, [hli]
	ld [rOBP1], a
	ret

; 真っ黒な画面から徐々に画面を戻す  
; 1:1 -> 2:1 -> 3:1 -> 4:3  (パレットの変化 N:M -> FadePal${N}のMバイト目)
GBFadeInFromBlack::
	ld hl, FadePal1
	ld b, 4
	jr GBFadeIncCommon

; 画面を徐々に真っ白にする  
; 6:1 -> 7:1 -> 8:3  
GBFadeOutToWhite::
	ld hl, FadePal6
	ld b, 3

; **GBFadeIncCommon**  
; FadePal${N} の内容を パレットに適用する  
; - - -  
; INPUT:  
; hl = FadePal${N}  
; b = ループ回数 (FadePalを連続で何個使用するか)  
; 
; FadePal${N}:1 -> FadePal${N+1}:1 -> FadePal${N+2}:1 -> ...
GBFadeIncCommon:
; {
	ld a, [hli]
	ld [rBGP], a
	ld a, [hli]
	ld [rOBP0], a
	ld a, [hli]
	ld [rOBP1], a
	ld c, 8
	call DelayFrames
	dec b
	jr nz, GBFadeIncCommon
; }
	ret


; 画面を徐々に真っ黒にする  
; 4:3 -> 3:3 -> 2:3 -> 1:1
GBFadeOutToBlack::
	ld hl, FadePal4 + 2
	ld b, 4
	jr GBFadeDecCommon

; 真っ白な画面から徐々に戻る  
; 7:3 -> 6:3 -> 5:3 -> 4:3
GBFadeInFromWhite::
	ld hl, FadePal7 + 2
	ld b, 3

; **GBFadeDecCommon**  
; FadePal${N} の内容を パレットに適用する  
; - - -  
; INPUT:  
; hl = FadePal${N}  
; b = ループ回数 (FadePalを連続で何個使用するか)  
; 
; FadePal${N}:3 -> FadePal${N-1}:3 -> FadePal${N-2}:3 -> ...  
GBFadeDecCommon:
; {
	ld a, [hld]
	ld [rOBP1], a
	ld a, [hld]
	ld [rOBP0], a
	ld a, [hld]
	ld [rBGP], a
	ld c, 8
	call DelayFrames
	dec b
	jr nz, GBFadeDecCommon
; }
	ret

; 1  -> ... ->  8
; 黒 -> ... -> 白
;                rBGP      rOBP0      rOBP1
FadePal1:: db %11111111, %11111111, %11111111	; 真っ黒
FadePal2:: db %11111110, %11111110, %11111000
FadePal3:: db %11111001, %11100100, %11100100
FadePal4:: db %11100100, %11010000, %11100000	; [p3, p2, p1, p0] => BGP:[3, 2, 1, 0] OBP0:[3, 1, 0, 0] OBP1:[3, 2, 0, 0]
FadePal5:: db %11100100, %11010000, %11100000
FadePal6:: db %10010000, %10000000, %10010000	; [p3, p2, p1, p0] => BGP:[2, 1, 0, 0] OBP0:[2, 0, 0, 0] OBP1:[2, 1, 0, 0]
FadePal7:: db %01000000, %01000000, %01000000
FadePal8:: db %00000000, %00000000, %00000000	; 真っ白
