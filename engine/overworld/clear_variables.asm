; **ClearVariablesOnEnterMap**
; 
; マップが切り替わるときにマップにかかわる変数を初期化する処理
ClearVariablesOnEnterMap:
	; WY = 144
	ld a, SCREEN_HEIGHT_PIXELS
	ld [hWY], a
	ld [rWY], a

	; 各種変数を0クリア
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a
	ld [wStepCounter], a
	ld [wLoneAttackNo], a
	ld [hJoyPressed], a
	ld [hJoyReleased], a
	ld [hJoyHeld], a
	ld [wActionResultOrTookBattleTurn], a
	ld [wUnusedD5A3], a

	; TODO: カードキーに関する変数？を0クリア
	ld hl, wCardKeyDoorY
	ld [hli], a
	ld [hl], a

	; TODO: ???を0クリア
	ld hl, wWhichTrade
	ld bc, wStandingOnWarpPadOrHole - wWhichTrade
	call FillMemory
	ret
