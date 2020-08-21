DisplayPokemartDialogue_:
	; wListScrollOffsetを退避
	ld a, [wListScrollOffset]
	ld [wSavedListScrollOffset], a

	call UpdateSprites
	xor a
	ld [wBoughtOrSoldItemInMart], a
.loop
	; メニュー選択に関する変数を0クリア
	xor a
	ld [wListScrollOffset], a
	ld [wCurrentMenuItem], a
	ld [wPlayerMonNumber], a
	
	; [wPrintItemPrices] = 1
	inc a
	ld [wPrintItemPrices], a
	
	; 所持金を表示するテキストボックスを表示
	ld a, MONEY_BOX
	ld [wTextBoxID], a
	call DisplayTextBoxID
	
	; Buy/Sellの2択メニュー用のテキストボックスを表示
	ld a, BUY_SELL_QUIT_MENU
	ld [wTextBoxID], a
	call DisplayTextBoxID

	; pokemartの商品リストのアドレスをhlに格納しているがそのアドレスは結局使われることはない
	ld hl, wItemListPointer
	ld a, [hli]
	ld l, [hl]
	ld h, a

	; a = メニューで何を押したか
	ld a, [wMenuExitMethod]

	; quitのときは終了
	cp CANCELLED_MENU
	jp z, .done

	; プレイヤーがbuy/sell/quitのどれを選んだかで分岐
	ld a, [wChosenMenuItem]
	and a ; buying?
	jp z, .buyMenu
	dec a ; selling?
	jp z, .sellMenu
	dec a ; quitting?
	jp z, .done

	; sellを選んだ時
.sellMenu
	; 同じ変数が下でセットされているのでこの処理は特に効果がない
	xor a
	ld [wPrintItemPrices], a
	ld a, INIT_BAG_ITEM_LIST
	ld [wInitListType], a
	callab InitList

	; プレイヤーのかばんの中身が空なら返る
	ld a, [wNumBagItems]
	and a
	jp z, .bagEmpty
	
	; 『What would you like to sell?』
	ld hl, PokemonSellingGreetingText
	call PrintText

	; この状態のBGマップをバックアップ
	call SaveScreenTilesToBuffer1 ; save screen

	; 売るアイテムを選択させる画面
.sellMenuLoop
	call LoadScreenTilesFromBuffer1 ; restore saved screen
	
	; 所持金を表示するテキストボックスを表示
	ld a, MONEY_BOX
	ld [wTextBoxID], a
	call DisplayTextBoxID ; draw money text box

	; wListPointerにwNumBagItemsを格納
	ld hl, wNumBagItems
	ld a, l
	ld [wListPointer], a
	ld a, h
	ld [wListPointer + 1], a

	; メニュー選択に関する変数を0クリア
	xor a
	ld [wPrintItemPrices], a
	ld [wCurrentMenuItem], a

	; アイテムリストメニューを表示
	ld a, ITEMLISTMENU
	ld [wListMenuID], a
	call DisplayListMenuID ; hl = wNumBagItems = かばんのアイテムエントリ数

	; プレイヤーがメニューを閉じたとき
	jp c, .returnToMainPokemartMenu

	; プレイヤーがかばんの特定のアイテムを売ろうとしたとき
.confirmItemSale
	; 売ろうとしたアイテムがたいせつなものかチェック　大切なものの場合は -> .unsellableItem
	call IsKeyItem
	ld a, [wIsKeyItem]
	and a
	jr nz, .unsellableItem

	; アイテムがひでんマシン -> .unsellableItem
	ld a, [wcf91]
	call IsItemHM
	jr c, .unsellableItem

	; 個数選択画面をプレイヤーに表示し入力(A/B)を待つ
	ld a, PRICEDITEMLISTMENU
	ld [wListMenuID], a
	ld [hHalveItemPrices], a ; halve prices when selling
	call DisplayChooseQuantityMenu

	; Bボタン -> .sellMenuLoop
	inc a
	jr z, .sellMenuLoop ; if the player closed the choose quantity menu with the B button

	; Aボタン -> アイテム売却を本当に行っていいか『はい/いいえ』の2択を表示
	; 店員の買取テキストを表示
	ld hl, PokemartTellSellPriceText
	lb bc, 14, 1 ; location that PrintText always prints to, this is useless
	call PrintText
	; 『はい/いいえ』の2択を表示
	coord hl, 14, 7
	lb bc, 8, 15
	ld a, TWO_OPTION_MENU
	ld [wTextBoxID], a
	call DisplayTextBoxID ; yes/no menu

	ld a, [wMenuExitMethod]

	; いいえ -> .sellMenuLoop
	cp CHOSE_SECOND_ITEM
	jr z, .sellMenuLoop ; if the player chose No or pressed the B button
	; 無駄なコード
	ld a, [wChosenMenuItem]
	dec a
	jr z, .sellMenuLoop

	; はい
.sellItem
	; [wBoughtOrSoldItemInMart] = 1
	ld a, [wBoughtOrSoldItemInMart]
	and a
	jr nz, .skipSettingFlag1
	inc a
	ld [wBoughtOrSoldItemInMart], a
.skipSettingFlag1

	; 売却処理(売却額だけ所持金を増やして、アイテムを減らす)
	call AddAmountSoldToMoney
	ld hl, wNumBagItems
	call RemoveItemFromInventory
	jp .sellMenuLoop	; 売り物選択に戻る

.unsellableItem
	; "I can't put a price on that."
	ld hl, PokemartUnsellableItemText
	call PrintText
	jp .returnToMainPokemartMenu

.bagEmpty
	; "You don't have anything to sell."
	ld hl, PokemartItemBagEmptyText
	call PrintText
	call SaveScreenTilesToBuffer1
	jp .returnToMainPokemartMenu

	; buyを選んだ時
.buyMenu
	; 変数を初期化しているが下で初期化の有無にかかわらずこれらの変数に値が設定されるのでこれは無駄な処理
	ld a, 1
	ld [wPrintItemPrices], a
	ld a, INIT_OTHER_ITEM_LIST
	ld [wInitListType], a
	callab InitList

	; buy選択時のテキストを表示
	ld hl, PokemartBuyingGreetingText
	call PrintText
	; .buyMenuLoopが処理の起点なのでスクリーン情報を退避
	call SaveScreenTilesToBuffer1
.buyMenuLoop
	call LoadScreenTilesFromBuffer1
	
	; 所持金を表示 
	ld a, MONEY_BOX
	ld [wTextBoxID], a
	call DisplayTextBoxID

	; wListPointerがwItemListを指すようにする
	ld hl, wItemList
	ld a, l
	ld [wListPointer], a
	ld a, h
	ld [wListPointer + 1], a

	; [wCurrentMenuItem] = 0
	xor a
	ld [wCurrentMenuItem], a
	; [wPrintItemPrices] = 1
	inc a
	ld [wPrintItemPrices], a

	; 店の売り物一覧メニューを表示する
	inc a ; a = 2 (PRICEDITEMLISTMENU)
	ld [wListMenuID], a
	call DisplayListMenuID

	jr c, .returnToMainPokemartMenu ; プレイヤーがメニューを閉じた

	; プレイヤーに個数選択メニューを表示して入力を待つ
	ld a, 99
	ld [wMaxItemQuantity], a
	xor a
	ld [hHalveItemPrices], a ; don't halve item prices when buying
	call DisplayChooseQuantityMenu

	; Bボタン -> .buyMenuLoop
	inc a
	jr z, .buyMenuLoop ; if the player closed the choose quantity menu with the B button

	; Aボタン
	
	; 購入確認のテキスト
	ld a, [wcf91] ; item ID
	ld [wd11e], a ; store item ID for GetItemName
	call GetItemName
	call CopyStringToCF4B ; [wcf4b] = アイテム名
	ld hl, PokemartTellBuyPriceText
	call PrintText

	; 『はい/いいえ』の2択を表示
	coord hl, 14, 7
	lb bc, 8, 15
	ld a, TWO_OPTION_MENU
	ld [wTextBoxID], a
	call DisplayTextBoxID ; yes/no menu
	; いいえ ->  .buyMenuLoop
	ld a, [wMenuExitMethod]
	cp CHOSE_SECOND_ITEM
	jp z, .buyMenuLoop
	; 無駄なコード
	ld a, [wChosenMenuItem]
	dec a
	jr z, .buyMenuLoop

	; はい -> アイテムの購入処理
.buyItem
	; 所持金が足りない
	call .isThereEnoughMoney
	jr c, .notEnoughMoney

	ld hl, wNumBagItems
	call AddItemToInventory
	jr nc, .bagFull
	call SubtractAmountPaidFromMoney
	ld a, [wBoughtOrSoldItemInMart]
	and a
	jr nz, .skipSettingFlag2
	ld a, 1
	ld [wBoughtOrSoldItemInMart], a
.skipSettingFlag2
	ld a, SFX_PURCHASE
	call PlaySoundWaitForCurrent
	call WaitForSoundToFinish
	ld hl, PokemartBoughtItemText
	call PrintText
	jp .buyMenuLoop
	
	; かいにきた/うりにきた/べつにいいです のメニューに戻る
.returnToMainPokemartMenu
	call LoadScreenTilesFromBuffer1
	ld a, MONEY_BOX
	ld [wTextBoxID], a
	call DisplayTextBoxID
	ld hl, PokemartAnythingElseText
	call PrintText
	jp .loop

.isThereEnoughMoney
	ld de, wPlayerMoney
	ld hl, hMoney
	ld c, 3 ; length of money in bytes
	jp StringCmp
	
.notEnoughMoney
	ld hl, PokemartNotEnoughMoneyText
	call PrintText
	jr .returnToMainPokemartMenu

.bagFull
	ld hl, PokemartItemBagFullText
	call PrintText
	jr .returnToMainPokemartMenu

.done
	; "ありがとう ございました"
	ld hl, PokemartThankYouText
	call PrintText

	ld a, 1
	ld [wUpdateSpritesEnabled], a
	call UpdateSprites
	ld a, [wSavedListScrollOffset]
	ld [wListScrollOffset], a
	ret

; "ゆっくり ごらんになって ください"
PokemartBuyingGreetingText:
	TX_FAR _PokemartBuyingGreetingText
	db "@"

; "<ITEM>ですね <PRICE>円に なりますが？"
PokemartTellBuyPriceText:
	TX_FAR _PokemartTellBuyPriceText
	db "@"

; "はい どうぞ まいど ありがとう ございます"
; "Here you are! Thank you!"
PokemartBoughtItemText:
	TX_FAR _PokemartBoughtItemText
	db "@"

PokemartNotEnoughMoneyText:
	TX_FAR _PokemartNotEnoughMoneyText
	db "@"

PokemartItemBagFullText:
	TX_FAR _PokemartItemBagFullText
	db "@"

PokemonSellingGreetingText:
	TX_FAR _PokemonSellingGreetingText
	db "@"

PokemartTellSellPriceText:
	TX_FAR _PokemartTellSellPriceText
	db "@"

; "You don't have anything to sell."
PokemartItemBagEmptyText:
	TX_FAR _PokemartItemBagEmptyText
	db "@"

; "I can't put a price on that."
PokemartUnsellableItemText:
	TX_FAR _PokemartUnsellableItemText
	db "@"

; "ありがとう ございました"
PokemartThankYouText:
	TX_FAR _PokemartThankYouText
	db "@"

; "そのほかに わたくしどもで おちからに なれることは？"
PokemartAnythingElseText:
	TX_FAR _PokemartAnythingElseText
	db "@"
