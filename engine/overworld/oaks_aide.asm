; **OaksAideScript**  
; 関所にいるオーキド博士の助手との会話処理を行う関数  
; - - -  
; OUTPUT:  
; [hOaksAideResult] = 終了状態
; - $00: アイテムをもらおうとしたがバッグがいっぱい
; - $01: アイテムをもらった
; - $80: つかまえた数が足りない
; - $ff: つかまえた数のチェックで『いいえ』を選んだ
OaksAideScript:
	; 『図鑑のつかまえた数がN匹を超えているか』尋ねるテキストを表示
	ld hl, OaksAideHiText
	call PrintText

	; yse/no
	call YesNoChoice

	; no -> .choseNo
	ld a, [wCurrentMenuItem]
	and a
	jr nz, .choseNo
	
	; yes -> つかまえた数をチェック

	; b = [hOaksAideNumMonsOwned] = つかまえた数
	ld hl, wPokedexOwned
	ld b, wPokedexOwnedEnd - wPokedexOwned
	call CountSetBits
	ld a, [wNumSetBits]
	ld [hOaksAideNumMonsOwned], a
	ld b, a
	
	; つかまえた数が足りない -> .notEnoughOwnedMons
	ld a, [hOaksAideRequirement]
	cp b
	jr z, .giveItem
	jr nc, .notEnoughOwnedMons

	; つかまえた数が基準以上のとき
.giveItem
	; "Great! You have caught N kinds of pokemon! Congratulations! Here you go!"
	ld hl, OaksAideHereYouGoText
	call PrintText

	; アイテム([hOaksAideRewardItem]を渡す
	ld a, [hOaksAideRewardItem]
	ld b, a
	ld c, 1
	call GiveItem

	; 失敗=バッグがいっぱい -> .bagFull
	jr nc, .bagFull

	; a = $1 -> .done
	; "<PLAYER> got the <ITEM>!"
	ld hl, OaksAideGotItemText
	call PrintText
	ld a, $1
	jr .done

; a = $0 -> .done
.bagFull
	; "Oh! I see you don't have any room for the <ITEM>."
	ld hl, OaksAideNoRoomText
	call PrintText
	xor a
	jr .done

; a = $80 -> .done
.notEnoughOwnedMons
	; "Let's see... Uh-oh! You have caught only ..."
	ld hl, OaksAideUhOhText
	call PrintText
	ld a, $80
	jr .done

; a = $ff -> .done
.choseNo
	; "Oh. I see. When you get N kinds, come back for <ITEM>."
	ld hl, OaksAideComeBackText
	call PrintText
	ld a, $ff

.done
	ld [hOaksAideResult], a
	ret

; "Hi! Remember me? I'm PROF.OAK's AIDE!"  
; "If you caught N kinds of pokemon, "I'm supposed to give you an <ITEM>!"  
; "So, <PLAYER>! Have you caught at least N kinds of pokemon?"
OaksAideHiText:
	TX_FAR _OaksAideHiText
	db "@"

; "Let's see... Uh-oh! You have caught only ..."
OaksAideUhOhText:
	TX_FAR _OaksAideUhOhText
	db "@"

; "Oh. I see. When you get N kinds, come back for <ITEM>."
OaksAideComeBackText:
	TX_FAR _OaksAideComeBackText
	db "@"

; "Great! You have caught N kinds of pokemon! Congratulations! Here you go!"
OaksAideHereYouGoText:
	TX_FAR _OaksAideHereYouGoText
	db "@"

; "<PLAYER> got the <ITEM>!"  
OaksAideGotItemText:
	TX_FAR _OaksAideGotItemText
	TX_SFX_ITEM_1
	db "@"

; "Oh! I see you don't have any room for the <ITEM>."  
OaksAideNoRoomText:
	TX_FAR _OaksAideNoRoomText
	db "@"
