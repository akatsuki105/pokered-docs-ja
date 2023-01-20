; **RemoveGuardDrink**  
; 
; ヤマブキシティのゲートの"のどが渇いた警備員"にドリンクを渡す関数
RemoveGuardDrink:
	ld hl, GuardDrinksList
.drinkLoop
	; a = ドリンク
	ld a, [hli]
	ld [hItemToRemoveID], a ; RemoveItemByIDのために

	; ループの終わり
	and a
	ret z

	; ドリンクがあるか確認
	push hl
	ld b, a
	call IsItemInBag
	pop hl

	; ないなら次のドリンク
	jr z, .drinkLoop
	; ドリンクを1個減らす
	jpba RemoveItemByID

; これらのアイテムのどれかを持っていればいい
GuardDrinksList:
	db FRESH_WATER, SODA_POP, LEMONADE, $00
