GiveFossilToCinnabarLab:
	; テキスト表示に遅延を発生させる
	ld hl, wd730
	set 6, [hl]

	; [wCurrentMenuItem] = 0
	xor a
	ld [wCurrentMenuItem], a

	; ABボタン以外は押しても何もおきない
	ld a, A_BUTTON | B_BUTTON
	ld [wMenuWatchedKeys], a

	; [wMaxMenuItem] = アイテムの最大オフセット(0から始まる)
	ld a, [wFilteredBagItemsCount]
	dec a
	ld [wMaxMenuItem], a

	; 化石選択メニューのカーソル位置を設定 
	ld a, 2
	ld [wTopMenuItemY], a
	ld a, 1
	ld [wTopMenuItemX], a

	; hl = 3 + a*2 -1 = 2 + a*2 = (上下の枠線) + アイテム数
	ld a, [wFilteredBagItemsCount]
	dec a
	ld bc, 2
	ld hl, 3
	call AddNTimes
	dec l

	; テキストボックスを描画 
	ld b, l
	ld c, $d
	coord hl, 0, 0
	call TextBoxBorder

	call UpdateSprites
	call PrintFossilsInBag	; テキストボックス内に化石名一覧を表示

	; 遅延を無効化 
	ld hl, wd730
	res 6, [hl]
	
	; キー入力をチェック
	call HandleMenuInput
	
	; Bボタンが押されたら化石の受け渡しをキャンセル 
	bit 1, a ; pressed B?
	jr nz, .cancelledGivingFossil

	; hl = 化石一覧で現在選択中の化石のポインタ
	ld hl, wFilteredBagItems
	ld a, [wCurrentMenuItem]
	ld d, 0
	ld e, a
	add hl, de

	; a = アイテムID
	ld a, [hl]
	ld [$ffdb], a

	; 各化石ごとに分岐
	cp DOME_FOSSIL
	jr z, .choseDomeFossil
	cp HELIX_FOSSIL
	jr z, .choseHelixFossil
	ld b, AERODACTYL
	jr .fossilSelected
.choseHelixFossil
	ld b, OMANYTE
	jr .fossilSelected
.choseDomeFossil
	ld b, KABUTO
	; 化石が選択された後の処理  
	; b = 化石を復元してできるポケモンID
.fossilSelected
	; wFossilItem/wFossilMon に 化石のアイテムIDと復元されるポケモンのIDを格納
	ld [wFossilItem], a
	ld a, b
	ld [wFossilMon], a

	call LoadFossilItemAndMonName

	; 化石の名前を出して復元するか選択させる
	ld hl, LabFossil_610ae
	call PrintText
	call YesNoChoice

	; はい/いいえ
	ld a, [wCurrentMenuItem]
	and a
	jr nz, .cancelledGivingFossil

	; 『はい』を選択
	; 化石を渡してフラグを立てる
	ld hl, LabFossil_610b3
	call PrintText
	ld a, [wFossilItem]
	ld [hItemToRemoveID], a
	callba RemoveItemByID
	ld hl, LabFossil_610b8
	call PrintText
	SetEvents EVENT_GAVE_FOSSIL_TO_LAB, EVENT_LAB_STILL_REVIVING_FOSSIL
	ret

	; 『いいえ』を選択
.cancelledGivingFossil
	ld hl, LabFossil_610bd
	call PrintText
	ret

LabFossil_610ae:
	TX_FAR _Lab4Text_610ae
	db "@"

LabFossil_610b3:
	TX_FAR _Lab4Text_610b3
	db "@"

LabFossil_610b8:
	TX_FAR _Lab4Text_610b8
	db "@"

LabFossil_610bd:
	TX_FAR _Lab4Text_610bd
	db "@"

; プレイヤーの持っている化石をアイテム選択メニューに表示
PrintFossilsInBag:
	; ループの初期化処理
	ld hl, wFilteredBagItems
	xor a
	ld [hItemCounter], a
.loop
	; a = 現在処理中のアイテム
	ld a, [hli]

	; 表示する化石がこれ以上ないので終了
	cp $ff
	ret z
	
	; de = 化石名
	push hl
	ld [wd11e], a
	call GetItemName

	; hl = 描画先のタイルアドレス
	coord hl, 2, 2
	ld a, [hItemCounter]
	ld bc, SCREEN_WIDTH * 2
	call AddNTimes

	; 化石名をテキストボックスに配置
	ld de, wcd6d
	call PlaceString

	; アイテムカウンターを増やして次の化石を表示する
	ld hl, hItemCounter
	inc [hl]
	pop hl
	jr .loop

; 化石名と化石から復元されるポケモンの名前を取得する  
; INPUT:  
; - [wFossilMon] = 化石から復元されるポケモンのID
; - [wFossilItem] = 化石のアイテムID
; 
; OUTPUT: 
; - de = 化石名
; - [wcf4b] = 復元されるポケモン名
LoadFossilItemAndMonName:
	ld a, [wFossilMon]
	ld [wd11e], a
	call GetMonName
	call CopyStringToCF4B
	ld a, [wFossilItem]
	ld [wd11e], a
	call GetItemName
	ret
