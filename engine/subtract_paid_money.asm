; **SubtractAmountPaidFromMoney_**  
; プレイヤーの支払った額をプレイヤーの所持金から引く処理  
; OUTPUT: carry = 0(お金が足りた) or 1(お金が足りない)  
SubtractAmountPaidFromMoney_:
	ld de, wPlayerMoney ; 所持金
	ld hl, hMoney ; 支払額
	ld c, 3 ; お金は3ByteのBCD数値

	; 所持金が足りない -> 終了(carry = 1) 
	call StringCmp
	ret c

	; 所持金から支払額を引く
	ld de, wPlayerMoney + 2
	ld hl, hMoney + 2
	ld c, 3
	predef SubBCDPredef

	; 所持金のテキストを再描画
	ld a, MONEY_BOX
	ld [wTextBoxID], a
	call DisplayTextBoxID

	and a ; carry = 0
	ret
