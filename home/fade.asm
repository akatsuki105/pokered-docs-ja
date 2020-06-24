; **LoadGBPal**  
; パレットに FadePal4 をロードする  
; 
; 段階的にフェージング処理を行うために利用(徐々に画面をホワイトスクリーンにしていく?)  
; マップの出入口に入る時に利用されたりする
LoadGBPal::
	; a = FadePal4 - wMapPalOffset
	ld a, [wMapPalOffset] ;tells if wCurMap is dark (requires HM5_FLASH?)
	ld b, a
	ld hl, FadePal4
	ld a, l
	sub b
	ld l, a
	jr nc, .ok
	dec h
.ok
	; パレットに FadePal4 をロード
	ld a, [hli]
	ld [rBGP], a
	ld a, [hli]
	ld [rOBP0], a
	ld a, [hli]
	ld [rOBP1], a
	ret

; 画面を徐々に真っ黒にする  
GBFadeInFromBlack::
	ld hl, FadePal1
	ld b, 4
	jr GBFadeIncCommon

; 画面を徐々に真っ白にする  
GBFadeOutToWhite::
	ld hl, FadePal6
	ld b, 3

; **GBFadeIncCommon**  
; FadePalN の内容を パレットに適用する  
; - - -  
; INPUT:  
; - hl = FadePalN
; - b = ループ回数 (FadePalを連続で何個使用するか)
GBFadeIncCommon:
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
	ret

GBFadeOutToBlack::
	ld hl, FadePal4 + 2
	ld b, 4
	jr GBFadeDecCommon

GBFadeInFromWhite::
	ld hl, FadePal7 + 2
	ld b, 3

GBFadeDecCommon:
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
	ret

;                rBGP      rOBP0      rOBP1
FadePal1:: db %11111111, %11111111, %11111111
FadePal2:: db %11111110, %11111110, %11111000
FadePal3:: db %11111001, %11100100, %11100100
FadePal4:: db %11100100, %11010000, %11100000	; [p3, p2, p1, p0] => BGP:[3, 2, 1, 0] OBP0:[3, 1, 0, 0] OBP1:[3, 2, 0, 0]
FadePal5:: db %11100100, %11010000, %11100000
FadePal6:: db %10010000, %10000000, %10010000	; [p3, p2, p1, p0] => BGP:[2, 1, 0, 0] OBP0:[2, 0, 0, 0] OBP1:[2, 1, 0, 0]
FadePal7:: db %01000000, %01000000, %01000000
FadePal8:: db %00000000, %00000000, %00000000
