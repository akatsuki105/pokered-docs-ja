; **AddItemToInventory_**  
; アイテムをプレイヤーのインベントリに追加する関数(個数は問わない)  
; - - - 
; AddItemToInventory の内部でのみ呼び出される処理
; 成功したときにはcarryをセット、失敗したときにはcarryをクリアする  
; INPUT:  
; - hl = インベントリのアドレス (wNumBagItems  or wNumBoxItems)  
; - [wcf91] = アイテムID  
; - [wItemQuantity] = アイテムの個数  
AddItemToInventory_:
	ld a, [wItemQuantity] ; a = item quantity
	push af
	push bc
	push de
	push hl
	push hl
	ld d, PC_ITEM_CAPACITY ; how many items the PC can hold
	
	; PCbox ->  .checkIfInventoryFull
	ld a, wNumBagItems & $FF
	cp l
	jr nz, .checkIfInventoryFull
	ld a, wNumBagItems >> 8
	cp h
	jr nz, .checkIfInventoryFull

	; かばん
	ld d, BAG_ITEM_CAPACITY ; how many items the bag can hold

; インベントリが満タンか調べる  
; INPUT:  
; - a = アイテムの個数
; - d = インベントリが持てるアイテムの最大種類数
; - hl = wNumBagItems
.checkIfInventoryFull
	; d = [wNumBagItems] - (インベントリが持てるアイテムの最大種類数)
	ld a, [hl]
	sub d
	ld d, a
	; [wNumBagItems] = 0 = インベントリが空 -> .addNewItem
	ld a, [hli]	; a = wNumBagItems hl = wBagItems
	and a
	jr z, .addNewItem

	; 同じアイテムがすでにインベントリにあるかチェック
.loop
	; インベントリに同じアイテムがすでにある -> .increaseItemQuantity
	ld a, [hli]
	ld b, a			; b = インベントリで現在探索中のアイテムのID
	ld a, [wcf91] 	; a = 追加したいアイテムのID
	cp b
	jp z, .increaseItemQuantity
	; 次のエントリ
	inc hl
	ld a, [hl]
	cp $ff ; is it the end of the table?
	jr nz, .loop

	; インベントリに同じ名前のアイテムがないとき  
	; INPUT:  
	; - a = wNumBagItems
.addNewItem
	pop hl ; hl = wNumBagItems

	; インベントリが満タン -> .done
	ld a, d
	and a ; is there room for a new item slot?
	jr z, .done

	; インベントリに空きがある

	; [wNumBagItems]++
	inc [hl]
	
	; a = [wBagItems]の空きエントリのインデックス
	ld a, [hl]
	add a
	dec a

	; hl = [wBagItems]の空きエントリのアドレス
	ld c, a
	ld b, 0
	add hl, bc
	
	; インベントリにアイテムを追加(アイテムID, 個数, $ff)
	ld a, [wcf91]
	ld [hli], a ; store item ID
	ld a, [wItemQuantity]
	ld [hli], a ; store item quantity
	ld [hl], $ff ; store terminator

	jp .success

	; インベントリに同じ名前のアイテムが既にあるときはその個数を増やす  
	; INPUT:  
	; [hl] = 対象のアイテムのインベントリでの個数 
	; d = [wNumBagItems] - (インベントリが持てるアイテムの最大種類数)
.increaseItemQuantity
	; a = インベントリの個数 + 新たに追加するアイテム数
	ld a, [wItemQuantity]
	ld b, a ; b = quantity to add
	ld a, [hl] ; a = existing item quantity
	add b ; a = new item quantity

	; 追加後の個数が100未満 -> .storeNewQuantity
	cp 100
	jp c, .storeNewQuantity

	; 追加後の個数が100個以上になる場合
	; 現在のアイテムスロットには99個入れ、新しいスロットに残りの個数を入れる

	; [wItemQuantity] = a - 99 = 新しいアイテムスロットに入るアイテムの数
	sub 99
	ld [wItemQuantity], a

	; アイテムスロットに空きがないなら失敗 -> .increaseItemQuantityFailed
	ld a, d
	and a
	jr z, .increaseItemQuantityFailed

	; 現在のアイテムスロットの個数を99個として、loopでアイテムスロットを探索する処理を次のアイテムスロットから再開する(新しい空きスロットに残りが入ることになる)
	ld a, 99
	ld [hli], a
	jp .loop

.increaseItemQuantityFailed
	pop hl
	and a	; キャリーをクリア
	jr .done
	
.storeNewQuantity
	ld [hl], a ; アイテムの個数 = 新しいアイテムの個数
	pop hl
.success
	scf ; キャリーをセット
.done
	pop hl
	pop de
	pop bc
	pop bc
	ld a, b
	ld [wItemQuantity], a ; [wItemQuantity]を関数が呼ばれたときの値に戻す
	ret

; function to remove an item (in varying quantities) from the player's bag or PC box  
; INPUT:  
; - hl = address of inventory (either wNumBagItems or wNumBoxItems)  
; - [wWhichPokemon] = index (within the inventory) of the item to remove  
; - [wItemQuantity] = quantity to remove  
RemoveItemFromInventory_:
	push hl
	inc hl
	ld a, [wWhichPokemon] ; index (within the inventory) of the item being removed
	sla a
	add l
	ld l, a
	jr nc, .noCarry
	inc h
.noCarry
	inc hl
	ld a, [wItemQuantity] ; quantity being removed
	ld e, a
	ld a, [hl] ; a = current quantity
	sub e
	ld [hld], a ; store new quantity
	ld [wMaxItemQuantity], a
	and a
	jr nz, .skipMovingUpSlots
; if the remaining quantity is 0,
; remove the emptied item slot and move up all the following item slots
.moveSlotsUp
	ld e, l
	ld d, h
	inc de
	inc de ; de = address of the slot following the emptied one
.loop ; loop to move up the following slots
	ld a, [de]
	inc de
	ld [hli], a
	cp $ff
	jr nz, .loop
; update menu info
	xor a
	ld [wListScrollOffset], a
	ld [wCurrentMenuItem], a
	ld [wBagSavedMenuItem], a
	ld [wSavedListScrollOffset], a
	pop hl
	ld a, [hl] ; a = number of items in inventory
	dec a ; decrement the number of items
	ld [hl], a ; store new number of items
	ld [wListCount], a
	cp 2
	jr c, .done
	ld [wMaxMenuItem], a
	jr .done
.skipMovingUpSlots
	pop hl
.done
	ret
