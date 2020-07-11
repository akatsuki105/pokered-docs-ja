; **InitPlayerData**  
; ゲームを『はじめから』始めたときにプレイヤーデータを初期化する  
; - - -  
; - IDをランダムに決定
; - 手持ち、PCBoxのポケモンとバッグ、PCBoxのアイテムをまっさらに
; - 所持金を3000に
; - バッジ個数を0に初期化
; - ゲームコインを0に初期化
; - ゲーム進行フラグをすべて0に初期化
; - MissableObjectsフラグを初期化
InitPlayerData:
; InitPlayerDataと同じ
InitPlayerData2:

	; IDをランダムに決定する
	call Random
	ld a, [hRandomSub]
	ld [wPlayerID], a
	call Random
	ld a, [hRandomAdd]
	ld [wPlayerID + 1], a

	ld a, $ff
	ld [wUnusedD71B], a

	; 手持ち、PCBoxのポケモンとバッグ、PCBoxのアイテムをまっさらに
	ld hl, wPartyCount
	call InitializeEmptyList
	ld hl, wNumInBox
	call InitializeEmptyList
	ld hl, wNumBagItems
	call InitializeEmptyList
	ld hl, wNumBoxItems
	call InitializeEmptyList

	; 所持金を3000に設定
START_MONEY EQU $3000
	ld hl, wPlayerMoney + 1
	ld a, START_MONEY / $100
	ld [hld], a ; xx30xx
	xor a
	ld [hli], a ; xxxx00
	inc hl
	ld [hl], a ; 00xxxx => 003000

	; TODO: ???
	ld [wMonDataLocation], a

	; バッジ個数を0に初期化
	ld hl, wObtainedBadges
	ld [hli], a ; flag_array = 0
	ld [hl], a
	
	; ゲームコインを0に初期化
	ld hl, wPlayerCoins
	ld [hli], a
	ld [hl], a

	; ゲーム進行フラグをすべて0に初期化
	ld hl, wGameProgressFlags
	ld bc, wGameProgressFlagsEnd - wGameProgressFlags
	call FillMemory

	; MissableObjectsフラグを初期化
	jp InitializeMissableObjectsFlags

; listは 最初のバイトが要素数、最後のバイトが終端記号なので、最初と最後のバイトを0にすることでlistを初期化する
InitializeEmptyList:
	xor a ; count
	ld [hli], a
	dec a ; terminator
	ld [hl], a
	ret
