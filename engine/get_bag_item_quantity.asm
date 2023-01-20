; **GetQuantityOfItemInBag**  
; 引数で指定したアイテムがかばんにいくつ入っているかを取得する  
; - - -
; INPUT: b = 対象のアイテムID  
; OUTPUT: b = かばんに対象のアイテムがいくつ入っているか  
GetQuantityOfItemInBag:
	call GetPredefRegisters
	ld hl, wNumBagItems
.loop
	inc hl
	ld a, [hli]
	cp $ff
	jr z, .notInBag
	cp b
	jr nz, .loop
	ld a, [hl]
	ld b, a
	ret
.notInBag
	ld b, 0
	ret
