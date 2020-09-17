; **HPBarLength**  
; HPバーのピクセル数を計算する  
; - - -  
; (現在HP*48)/(最大HP) = ピクセル数 が e に格納されて返る  
; HPバーは必ず 1px 存在する必要があるので e = 0 になったときは 1 を返す
; 
; INPUT:  
; bc = 現在HP  
; de = 最大HP  
; 
; OUTPUT:  
; e = ピクセル数  
HPBarLength:
	call GetPredefRegisters

; **GetHPBarLength**  
; HPバーのピクセル数を計算する  
; - - -  
; e = (現在HP*48)/(最大HP) = ピクセル数  
; HPバーは必ず 1px 存在する必要があるので e = 0 になったときは 1 を返す
; 
; INPUT:  
; bc = 現在HP  
; de = 最大HP  
; 
; OUTPUT:  
; e = ピクセル数  
GetHPBarLength:
	push hl
	
	; 48 * bc (HPバーは48ピクセルの長さなので)
	xor a
	ld hl, H_MULTIPLICAND
	ld [hli], a
	ld a, b
	ld [hli], a
	ld a, c
	ld [hli], a
	ld [hl], $30 ; 0x30 = 48
	call Multiply      ; 48 * bc (hp bar is 48 pixels long)

	; d == 0 -> .maxHPSmaller256
	ld a, d
	and a
	jr z, .maxHPSmaller256

	; 最大HP([H_DIVISOR])が256より多い時ここにくる
	; [H_DIVISOR]は1バイトである必要があるので、計算可能なように [H_MULTIPLICAND] /= 4, de /= 4 する

	; de /= 4
	srl d              ; make HP in de fit into 1 byte by dividing by 4
	rr e
	srl d
	rr e
	; [H_MULTIPLICAND] /= 4
	ld a, [H_MULTIPLICAND+1]
	ld b, a
	ld a, [H_MULTIPLICAND+2]
	srl b
	rr a
	srl b
	rr a
	ld [H_MULTIPLICAND+2], a
	ld a, b
	ld [H_MULTIPLICAND+1], a

.maxHPSmaller256
	; bc * 48 / de を計算
	ld a, e
	ld [H_DIVISOR], a
	ld b, $4
	call Divide

	; e = bc * 48 / de (num of pixels of HP bar)
	ld a, [H_MULTIPLICAND+2]
	ld e, a     

	pop hl
	; 結果が 0のときは1にする
	and a
	ret nz
	ld e, $1           ; make result at least 1
	ret

; **UpdateHPBar**  
; HPバー更新処理  
; - - -  
; predef $48
UpdateHPBar:
; **UpdateHPBar2**  
; HPバー更新処理  
; - - -  
; predef $48
UpdateHPBar2:
	push hl
	ld hl, wHPBarOldHP
	ld a, [hli]
	ld c, a      ; old HP into bc
	ld a, [hli]
	ld b, a
	ld a, [hli]
	ld e, a      ; new HP into de
	ld d, [hl]
	pop hl
	push de
	push bc
	call UpdateHPBar_CalcHPDifference
	ld a, e
	ld [wHPBarHPDifference+1], a
	ld a, d
	ld [wHPBarHPDifference], a
	pop bc
	pop de
	call UpdateHPBar_CompareNewHPToOldHP
	ret z
	ld a, $ff
	jr c, .HPdecrease
	ld a, $1
.HPdecrease
	ld [wHPBarDelta], a
	call GetPredefRegisters
	ld a, [wHPBarNewHP]
	ld e, a
	ld a, [wHPBarNewHP+1]
	ld d, a
.animateHPBarLoop
	push de
	ld a, [wHPBarOldHP]
	ld c, a
	ld a, [wHPBarOldHP+1]
	ld b, a
	call UpdateHPBar_CompareNewHPToOldHP
	jr z, .animateHPBarDone
	jr nc, .HPIncrease
; HP decrease
	dec bc        ; subtract 1 HP
	ld a, c
	ld [wHPBarNewHP], a
	ld a, b
	ld [wHPBarNewHP+1], a
	call UpdateHPBar_CalcOldNewHPBarPixels
	ld a, e
	sub d         ; calc pixel difference
	jr .ok
.HPIncrease
	inc bc        ; add 1 HP
	ld a, c
	ld [wHPBarNewHP], a
	ld a, b
	ld [wHPBarNewHP+1], a
	call UpdateHPBar_CalcOldNewHPBarPixels
	ld a, d
	sub e         ; calc pixel difference
.ok
	call UpdateHPBar_PrintHPNumber
	and a
	jr z, .noPixelDifference
	call UpdateHPBar_AnimateHPBar
.noPixelDifference
	ld a, [wHPBarNewHP]
	ld [wHPBarOldHP], a
	ld a, [wHPBarNewHP+1]
	ld [wHPBarOldHP+1], a
	pop de
	jr .animateHPBarLoop
.animateHPBarDone
	pop de
	ld a, e
	ld [wHPBarOldHP], a
	ld a, d
	ld [wHPBarOldHP+1], a
	or e
	jr z, .monFainted
	call UpdateHPBar_CalcOldNewHPBarPixels
	ld d, e
.monFainted
	call UpdateHPBar_PrintHPNumber
	ld a, $1
	call UpdateHPBar_AnimateHPBar
	jp Delay3

; animates the HP bar going up or down for (a) ticks (two waiting frames each)
; stops prematurely if bar is filled up
; e: current health (in pixels) to start with
UpdateHPBar_AnimateHPBar:
	push hl
.barAnimationLoop
	push af
	push de
	ld d, $6
	call DrawHPBar
	ld c, 2
	call DelayFrames
	pop de
	ld a, [wHPBarDelta] ; +1 or -1
	add e
	cp $31
	jr nc, .barFilledUp
	ld e, a
	pop af
	dec a
	jr nz, .barAnimationLoop
	pop hl
	ret
.barFilledUp
	pop af
	pop hl
	ret

; compares old HP and new HP and sets c and z flags accordingly
UpdateHPBar_CompareNewHPToOldHP:
	ld a, d
	sub b
	ret nz
	ld a, e
	sub c
	ret

; calcs HP difference between bc and de (into de)
UpdateHPBar_CalcHPDifference:
	ld a, d
	sub b
	jr c, .oldHPGreater
	jr z, .testLowerByte
.newHPGreater
	ld a, e
	sub c
	ld e, a
	ld a, d
	sbc b
	ld d, a
	ret
.oldHPGreater
	ld a, c
	sub e
	ld e, a
	ld a, b
	sbc d
	ld d, a
	ret
.testLowerByte
	ld a, e
	sub c
	jr c, .oldHPGreater
	jr nz, .newHPGreater
	ld de, $0
	ret

UpdateHPBar_PrintHPNumber:
	push af
	push de
	ld a, [wHPBarType]
	and a
	jr z, .done ; don't print number in enemy HUD
; convert from little-endian to big-endian for PrintNumber
	ld a, [wHPBarOldHP]
	ld [wHPBarTempHP + 1], a
	ld a, [wHPBarOldHP + 1]
	ld [wHPBarTempHP], a
	push hl
	ld a, [hFlags_0xFFF6]
	bit 0, a
	jr z, .asm_fb15
	ld de, $9
	jr .next
.asm_fb15
	ld de, $15
.next
	add hl, de
	push hl
	ld a, " "
	ld [hli], a
	ld [hli], a
	ld [hli], a
	pop hl
	ld de, wHPBarTempHP
	lb bc, 2, 3
	call PrintNumber
	call DelayFrame
	pop hl
.done
	pop de
	pop af
	ret

; calcs number of HP bar pixels for old and new HP value
; d: new pixels
; e: old pixels
UpdateHPBar_CalcOldNewHPBarPixels:
	push hl
	ld hl, wHPBarMaxHP
	ld a, [hli]  ; max HP into de
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hli]  ; old HP into bc
	ld c, a
	ld a, [hli]
	ld b, a
	ld a, [hli]  ; new HP into hl
	ld h, [hl]
	ld l, a
	push hl
	push de
	call GetHPBarLength ; calc num pixels for old HP
	ld a, e
	pop de
	pop bc
	push af
	call GetHPBarLength ; calc num pixels for new HP
	pop af
	ld d, e
	ld e, a
	pop hl
	ret
