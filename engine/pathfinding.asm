; **FindPathToPlayer**  
; NPCがプレイヤーのところに歩いてくるときに道順(Path)を決定するための関数  
; - - -  
; 
; INPUT:  
; [hNPCPlayerXDistance] = NPCとPlayerのX距離(歩数単位)  
; [hNPCPlayerYDistance] = NPCとPlayerのY距離(歩数単位)  
FindPathToPlayer:
	xor a
	
	; Pathに関する変数をクリア
	ld hl, hFindPathNumSteps
	ld [hli], a ; hFindPathNumSteps
	ld [hli], a ; hFindPathFlags
	ld [hli], a ; hFindPathYProgress
	ld [hl], a  ; hFindPathXProgress

	ld hl, wNPCMovementDirections2
	ld de, $0
.loop
	; a,d = abs([hNPCPlayerYDistance] - [hFindPathYProgress])
	ld a, [hFindPathYProgress]
	ld b, a
	ld a, [hNPCPlayerYDistance] ; Y distance in steps
	call CalcDifference
	ld d, a

	; a == 0 => hFindPathFlagsのbit0をセット
	and a
	jr nz, .asm_f8da
	ld a, [hFindPathFlags]
	set 0, a ; current end of path matches the player's Y coordinate
	ld [hFindPathFlags], a

.asm_f8da
	; a,e = abs([hNPCPlayerXDistance] - [hFindPathXProgress])
	ld a, [hFindPathXProgress]
	ld b, a
	ld a, [hNPCPlayerXDistance] ; X distance in steps
	call CalcDifference
	ld e, a

	; a == 0 => hFindPathFlagsのbit1をセット
	and a
	jr nz, .asm_f8ec
	ld a, [hFindPathFlags]
	set 1, a ; current end of path matches the player's X coordinate
	ld [hFindPathFlags], a

.asm_f8ec
	; hFindPathFlagsの bit0と bit1 がセットされている つまり Pathが見つかった -> .done
	ld a, [hFindPathFlags]
	cp $3
	jr z, .done

; プレーヤーと現在のPath間のX距離が大きいか、Y距離が大きいかを比較し、どちらか大きい方を減らす

	; Y距離の方がおおきい -> .yDistanceGreater
	ld a, e
	cp d
	jr c, .yDistanceGreater
	
	; X距離の方がおおきい(このとき少なくともプレイヤーとNPCはX座標が異なる)
	
	; d = NPC_MOVEMENT_LEFT(プレイヤーがNPCより左にいるとき) or NPC_MOVEMENT_RIGHT(プレイヤーがNPCより右にいるとき)
	ld a, [hNPCPlayerRelativePosFlags]
	bit 1, a
	jr nz, .playerIsLeftOfNPC
	ld d, NPC_MOVEMENT_RIGHT
	jr .next1
.playerIsLeftOfNPC
	ld d, NPC_MOVEMENT_LEFT

.next1
	; [hFindPathXProgress]++
	ld a, [hFindPathXProgress]
	add 1
	ld [hFindPathXProgress], a
	jr .storeDirection

	; Y距離の方がおおきい(このとき少なくともプレイヤーとNPCはY座標が異なる)
.yDistanceGreater
	; d = NPC_MOVEMENT_UP(プレイヤーがNPCより上) or NPC_MOVEMENT_DOWN(プレイヤーがNPCより下)
	ld a, [hNPCPlayerRelativePosFlags]
	bit 0, a
	jr nz, .playerIsAboveNPC
	ld d, NPC_MOVEMENT_DOWN
	jr .next2
.playerIsAboveNPC
	ld d, NPC_MOVEMENT_UP

.next2
	; [hFindPathYProgress]++
	ld a, [hFindPathYProgress]
	add 1
	ld [hFindPathYProgress], a

; この時点でNPCの次の進行方向が d に入っている その進行をPathに加えて次のループに
.storeDirection
	; a = [wNPCMovementDirections2] = NPCの次の進行方向
	ld a, d
	ld [hli], a

	; [hFindPathNumSteps]++
	ld a, [hFindPathNumSteps]
	inc a
	ld [hFindPathNumSteps], a

	jp .loop

	; このとき、NPC-Playerの道筋が形成されている
.done
	ld [hl], $ff
	ret

; **CalcPositionOfPlayerRelativeToNPC**  
; プレイヤーが特定のNPCに対してどこにいるかを計算する
; - - -  
; OUTPUT: 
; - [hNPCPlayerXDistance], [hNPCPlayerYDistance] = プレイヤーとスプライトの距離(歩数単位)
; - [hNPCPlayerRelativePosFlags] = プレイヤーとNPCの位置関係 (hNPCPlayerRelativePosPerspective に注意)
CalcPositionOfPlayerRelativeToNPC:
	; [hNPCPlayerRelativePosFlags] = 0
	xor a
	ld [hNPCPlayerRelativePosFlags], a

	; de = プレイヤーの座標(ピクセル単位)
	ld a, [wSpriteStateData1 + 4] ; player's sprite screen Y position in pixels
	ld d, a
	ld a, [wSpriteStateData1 + 6] ; player's sprite screen X position in pixels
	ld e, a

	; hl = $c1x4 (x: 対象のスプライトオフセット)
	ld hl, wSpriteStateData1
	ld a, [hNPCSpriteOffset]
	add l
	add $4
	ld l, a
	jr nc, .noCarry
	inc h

.noCarry
	; a = スプライトのY座標
	; b = プレイヤーのY座標
	ld a, d
	ld b, a
	ld a, [hli] ; hl = $c1x5

	; スプライトのY座標 <= プレイヤーのY座標 -> .NPCSouthOfOrAlignedWithPlayer
	call CalcDifference ; a = スプライトとプレイヤーのY距離
	jr nc, .NPCSouthOfOrAlignedWithPlayer

	; スプライトがプレイヤーより上にいるとき
.NPCNorthOfPlayer
	push hl

	; hNPCPlayerRelativePosFlags の bit0 = 1
	ld hl, hNPCPlayerRelativePosFlags
	bit 0, [hl]
	set 0, [hl]

	pop hl
	jr .divideYDistance

	; スプライトがプレイヤーと同じY座標かプレイヤーより下にいるとき
.NPCSouthOfOrAlignedWithPlayer
	push hl
	
	; hNPCPlayerRelativePosFlags の bit0 = 0
	ld hl, hNPCPlayerRelativePosFlags
	bit 0, [hl]
	res 0, [hl]

	pop hl

	; INPUT:  
	; a = プレイヤーとスプライトのY距離(ピクセル単位)
.divideYDistance
	push hl

	; [hNPCPlayerYDistance] = プレイヤーとスプライトのY距離(歩数単位)
	ld hl, hDividend2
	ld [hli], a ; [hDividend2] = プレイヤーとスプライトのY距離(ピクセル単位), hl = hDivisor2
	ld a, 16
	ld [hli], a ; [hDivisor2] = 16, hl = hQuotient2
	call DivideBytes
	ld a, [hl]
	ld [hNPCPlayerYDistance], a

	pop hl
	
	; a = スプライトのX座標
	; b = プレイヤーのX座標
	inc hl
	ld b, e
	ld a, [hl]

	; スプライトのX座標 <= プレイヤーのX座標 -> .NPCEastOfOrAlignedWithPlayer
	call CalcDifference
	jr nc, .NPCEastOfOrAlignedWithPlayer

	; スプライトがプレイヤーより右にいるとき
.NPCWestOfPlayer
	push hl

	; hNPCPlayerRelativePosFlags の bit1 = 1
	ld hl, hNPCPlayerRelativePosFlags
	bit 1, [hl]
	set 1, [hl]
	pop hl
	jr .divideXDistance

	; スプライトがプレイヤーと同じX座標かプレイヤーより左にいるとき
.NPCEastOfOrAlignedWithPlayer
	push hl

	; hNPCPlayerRelativePosFlags の bit1 = 0
	ld hl, hNPCPlayerRelativePosFlags
	bit 1, [hl]
	res 1, [hl]

	pop hl

.divideXDistance
	; [hNPCPlayerXDistance] = プレイヤーとスプライトのX距離(歩数単位)
	ld [hDividend2], a
	ld a, 16
	ld [hDivisor2], a
	call DivideBytes
	ld a, [hQuotient2]
	ld [hNPCPlayerXDistance], a

	; プレイヤーから見たNPCの位置が欲しいときはそのまま終了
	ld a, [hNPCPlayerRelativePosPerspective]
	and a
	ret z

	; NPCから見たプレイヤーの位置が欲しいときは位置関係を反転させて終了
	ld a, [hNPCPlayerRelativePosFlags]
	cpl
	and $3
	ld [hNPCPlayerRelativePosFlags], a
	ret

ConvertNPCMovementDirectionsToJoypadMasks:
	ld a, [hNPCMovementDirections2Index]
	ld [wNPCMovementDirections2Index], a
	dec a
	ld de, wSimulatedJoypadStatesEnd
	ld hl, wNPCMovementDirections2
	add l
	ld l, a
	jr nc, .loop
	inc h
.loop
	ld a, [hld]
	call ConvertNPCMovementDirectionToJoypadMask
	ld [de], a
	inc de
	ld a, [hNPCMovementDirections2Index]
	dec a
	ld [hNPCMovementDirections2Index], a
	jr nz, .loop
	ret

ConvertNPCMovementDirectionToJoypadMask:
	push hl
	ld b, a
	ld hl, NPCMovementDirectionsToJoypadMasksTable
.loop
	ld a, [hli]
	cp $ff
	jr z, .done
	cp b
	jr z, .loadJoypadMask
	inc hl
	jr .loop
.loadJoypadMask
	ld a, [hl]
.done
	pop hl
	ret

NPCMovementDirectionsToJoypadMasksTable:
	db NPC_MOVEMENT_UP, D_UP
	db NPC_MOVEMENT_DOWN, D_DOWN
	db NPC_MOVEMENT_LEFT, D_LEFT
	db NPC_MOVEMENT_RIGHT, D_RIGHT
	db $ff

; unreferenced
	ret
