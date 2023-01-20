; **_GetSpritePosition1**  
; $ffeb-$ffee にスプライトの位置データを格納する  
; - - -  
; OUTPUT:  
; [$ffeb] = [c1x4] (screen Y pos)  
; [$ffec] = [c1x6] (screen X pos)  
; [$ffed] = [c2x4] (map Y pos)  
; [$ffee] = [c2x5] (map X pos)  
_GetSpritePosition1:
	; hl = c1x4
	ld hl, wSpriteStateData1
	ld de, $4
	ld a, [wSpriteIndex]
	ld [H_SPRITEINDEX], a
	call GetSpriteDataPointer

	ld a, [hli] ; [$ffeb] = c1x4 (screen Y pos)
	ld [$ffeb], a

	inc hl

	ld a, [hl] ; [$ffec] = c1x6 (screen X pos)
	ld [$ffec], a

	ld de, (wSpriteStateData2 + $4) - (wSpriteStateData1 + $6)
	add hl, de

	ld a, [hli] 
	ld [$ffed], a ; [$ffed] = c2x4 (map Y pos)

	ld a, [hl] 
	ld [$ffee], a ; [$ffee] = c2x5 (map X pos)

	ret

; **_GetSpritePosition2**  
; wSavedSpriteXXXX にスプライトの位置データを格納する  
; - - -  
; OUTPUT:  
; [wSavedSpriteScreenY] = [c1x4] (screen Y pos)  
; [wSavedSpriteScreenX] = [c1x6] (screen X pos)  
; [wSavedSpriteMapY] = [c2x4] (map Y pos)  
; [wSavedSpriteMapX] = [c2x5] (map X pos) 
_GetSpritePosition2:
	; hl = c1x4
	ld hl, wSpriteStateData1
	ld de, $4
	ld a, [wSpriteIndex]
	ld [H_SPRITEINDEX], a
	call GetSpriteDataPointer

	ld a, [hli] ; c1x4 (screen Y pos)
	ld [wSavedSpriteScreenY], a
	inc hl

	ld a, [hl] ; c1x6 (screen X pos)
	ld [wSavedSpriteScreenX], a

	ld de, (wSpriteStateData2 + $4) - (wSpriteStateData1 + $6)
	add hl, de

	ld a, [hli] ; c2x4 (map Y pos)
	ld [wSavedSpriteMapY], a

	ld a, [hl] ; c2x5 (map X pos)
	ld [wSavedSpriteMapX], a
	ret

; **_SetSpritePosition1**  
; スプライトスロット(C1XX, C2XX) に _GetSpritePosition1 で取得したスプライトの位置データを格納する  
; - - -  
; OUTPUT:  
; [c1x4] = [$ffeb] (screen Y pos)  
; [c1x6] = [$ffec] (screen X pos)  
; [c2x4] = [$ffed] (map Y pos)  
; [c2x5] = [$ffee] (map X pos)  
_SetSpritePosition1:
	ld hl, wSpriteStateData1
	ld de, $4
	ld a, [wSpriteIndex]
	ld [H_SPRITEINDEX], a
	call GetSpriteDataPointer
	ld a, [$ffeb] ; c1x4 (screen Y pos)
	ld [hli], a
	inc hl
	ld a, [$ffec] ; c1x6 (screen X pos)
	ld [hl], a
	ld de, (wSpriteStateData2 + $4) - (wSpriteStateData1 + $6)
	add hl, de
	ld a, [$ffed] ; c2x4 (map Y pos)
	ld [hli], a
	ld a, [$ffee] ; c2x5 (map X pos)
	ld [hl], a
	ret

; **_SetSpritePosition2**  
; スプライトスロット(C1XX, C2XX) に _GetSpritePosition2 で取得したスプライトの位置データを格納する  
; - - -  
; OUTPUT:  
; [c1x4] = [wSavedSpriteScreenY] (screen Y pos)  
; [c1x6] = [wSavedSpriteScreenX] (screen X pos)  
; [c2x4] = [wSavedSpriteMapY] (map Y pos)  
; [c2x5] = [wSavedSpriteMapX] (map X pos)  
_SetSpritePosition2:
	ld hl, wSpriteStateData1
	ld de, 4
	ld a, [wSpriteIndex]
	ld [H_SPRITEINDEX], a
	call GetSpriteDataPointer
	ld a, [wSavedSpriteScreenY]
	ld [hli], a ; c1x4 (screen Y pos)
	inc hl
	ld a, [wSavedSpriteScreenX]
	ld [hl], a ; c1x6 (screen X pos)
	ld de, (wSpriteStateData2 + $4) - (wSpriteStateData1 + $6)
	add hl, de
	ld a, [wSavedSpriteMapY]
	ld [hli], a ; c2x4 (map Y pos)
	ld a, [wSavedSpriteMapX]
	ld [hl], a ; c2x5 (map X pos)
	ret

; **TrainerWalkUpToPlayer**  
; トレーナーが主人公を見つけたときに、トレーナーを主人公の方に歩かせる処理  
; - - -  
; INPUT: [wSpriteIndex] = 処理対象のトレーナースプライトのオフセット  
TrainerWalkUpToPlayer:
	; トレーナーの 画面上の Y座標 と X座標 を wTrainerScreenX(Y) にロード
	ld a, [wSpriteIndex]
	swap a
	ld [wTrainerSpriteOffset], a
	call ReadTrainerScreenPosition

	ld a, [wTrainerFacingDirection]

	; トレーナーの向いている方向で分岐
	and a ; cp SPRITE_FACING_DOWN
	jr z, .facingDown	; 下
	cp SPRITE_FACING_UP
	jr z, .facingUp		; 上
	cp SPRITE_FACING_LEFT
	jr z, .facingLeft	; 左
	jr .facingRight		; 右

; トレーナーが下を向いている時
.facingDown
	; 主人公とトレーナーの距離(Y軸、 pixel単位)を計算
	ld a, [wTrainerScreenY]
	ld b, a					; b = トレーナーのY座標
	ld a, $3c				; a = 主人公のY座標
	call CalcDifference

	; トレーナーが主人公の1マス上にいるときは歩かせる必要がないので return
	cp $10	; 16px = 1マス
	ret z

	; a = 歩かせる方向, bc = 歩くマス数
	swap a
	dec a
	ld c, a             
	xor a
	ld b, a           

	jr .writeWalkScript

; トレーナーが上を向いている時
.facingUp
	; 主人公とトレーナーの距離(Y軸、 pixel単位)を計算
	ld a, [wTrainerScreenY]
	ld b, a
	ld a, $3c           
	call CalcDifference

	; トレーナーが主人公の1マス下にいるときは歩かせる必要がないので return
	cp $10              
	ret z

	; a = 歩かせる方向, bc = 歩くマス数
	swap a
	dec a
	ld c, a             
	ld b, $0
	ld a, $40           

	jr .writeWalkScript

; トレーナーが右を向いている時
.facingRight
	; 主人公とトレーナーの距離(X軸、 pixel単位)を計算
	ld a, [wTrainerScreenX]
	ld b, a
	ld a, $40
	call CalcDifference

	; トレーナーが主人公の1マス左にいるときは歩かせる必要がないので return
	cp $10
	ret z

	; a = 歩かせる方向, bc = 歩くマス数
	swap a
	dec a
	ld c, a
	ld b, $0
	ld a, $c0

	jr .writeWalkScript

; トレーナーが左を向いている時
.facingLeft
	; 主人公とトレーナーの距離(X軸、 pixel単位)を計算
	ld a, [wTrainerScreenX]
	ld b, a
	ld a, $40
	call CalcDifference

	; トレーナーが主人公の1マス右にいるときは歩かせる必要がないので return
	cp $10
	ret z

	; a = 歩かせる方向, bc = 歩くマス数
	swap a
	dec a
	ld c, a
	ld b, $0
	ld a, $80

.writeWalkScript
	; この時点で a = 歩かせる方向、 bc = 歩かせるマス数

	; wNPCMovementDirections2 から bcバイトだけ、歩かせる方向を書き込むことで scripted NPC にプレイヤーの方に歩かせるように
	ld hl, wNPCMovementDirections2
	ld de, wNPCMovementDirections2
	call FillMemory
	ld [hl], $ff	; wNPCMovementDirections2 の終端記号

	ld a, [wSpriteIndex]
	ld [H_SPRITEINDEX], a
	jp MoveSprite_	; このとき de = wNPCMovementDirections2

; **GetSpriteDataPointer**  
; 取得したいスプライトデータのポインタ(C1XY)を入手する  
; - - -  
; INPUT:  
; de = 0xC1XY の Y (C1X0 から取得したいデータのオフセット)  
; hl = 0xC100(wSpriteStateData1)  
; [H_SPRITEINDEX] = スプライトのオフセット (C1X0 の X)  
; 
; OUTPUT: hl = 取得したいスプライトデータのポインタ(C1XY)  
GetSpriteDataPointer:
	; hl = 0xC10Y (Y = de)
	push de
	add hl, de

	; de = 0x00X0 (X = スプライトのオフセット)
	ld a, [H_SPRITEINDEX]
	swap a
	ld d, $0
	ld e, a

	; hl = 0xC1XY
	add hl, de
	pop de
	ret

; **TrainerEngage**  
; トレーナーに発見されたか判定して発見されたならエンカウント処理を行う  
; - - -  
; エンカウント処理: [wEngagedTrainerClass] と [wEngagedTrainerSet] に trainer class と trainer number をセット
; 
; OUTPUT:  
; [wTrainerSpriteOffset] = 0xff(発見された) or 0x00(されなかった)  
; [wEngagedTrainerClass] = trainer class  
; [wEngagedTrainerSet] = trainer number  
TrainerEngage:
	push hl
	push de

	; a = sprite image index (c1X2)
	ld a, [wTrainerSpriteOffset]
	add $2
	ld d, $0
	ld e, a
	ld hl, wSpriteStateData1
	add hl, de				; hl = c1X2
	ld a, [hl]

	; [c1X2] == 0xff ならスプライトは非表示状態なので -> .noEngage
	sub $ff
	jr nz, .spriteOnScreen
	jp .noEngage

.spriteOnScreen

	; [wTrainerFacingDirection] = トレーナーの向いている方向
	ld a, [wTrainerSpriteOffset]
	add $9
	ld d, $0
	ld e, a
	ld hl, wSpriteStateData1
	add hl, de				; hl = c1X9
	ld a, [hl]
	ld [wTrainerFacingDirection], a

	call ReadTrainerScreenPosition

	; [wTrainerScreenY] == 0x3c つまり プレイヤーと同じX軸にいる -> .linedUpY
	ld a, [wTrainerScreenY]
	ld b, a
	ld a, $3c
	cp b
	jr z, .linedUpY

	; [wTrainerScreenX] == 0x40 つまり プレイヤーと同じY軸にいる -> .linedUpX
	ld a, [wTrainerScreenX]
	ld b, a
	ld a, $40
	cp b
	jr z, .linedUpX

	; プレイヤーとXY軸が被っていない -> .noEngage
	xor a
	jp .noEngage

	; プレイヤーと同じX軸にいるとき
.linedUpY
	; トレーナーのX座標 == プレイヤーのX座標 つまりトレーナーとプレイヤーの座標が完全に重なっている -> .noEngage
	ld a, [wTrainerScreenX]
	ld b, a
	ld a, $40
	call CalcDifference
	jr z, .noEngage

	; トレーナーの視界の中に、プレイヤーが入りうる -> .engage
	call CheckSpriteCanSeePlayer
	jr c, .engage
	xor a
	jr .noEngage

	; プレイヤーと同じY軸にいる 
.linedUpX
	; トレーナーのX座標 == プレイヤーのX座標 つまりトレーナーとプレイヤーの座標が完全に重なっている -> .noEngage
	ld a, [wTrainerScreenY]
	ld b, a
	ld a, $3c
	call CalcDifference
	jr z, .noEngage

	; トレーナーの視界の中に、プレイヤーが入りうる -> .engage
	call CheckSpriteCanSeePlayer
	jr c, .engage
	xor a
	jp .noEngage

.engage
	; トレーナーがプレイヤーの方を向いている
	call CheckPlayerIsInFrontOfSprite

	; トレーナーの方を向いていない -> .noEngage
	ld a, [wTrainerSpriteOffset]
	and a
	jr z, .noEngage

	; トレーナーに発見されたので、フラグを立てる
	; CheckSpriteCanSeePlayer のとき(.engageの時点で成立) に トレーナーがプレイヤーの方を向いている なら、トレーナーに発見
	ld hl, wFlags_0xcd60
	set 0, [hl]
	call EngageMapTrainer	; エンカウントしたトレーナーのデータをロードし、エンカウントBGMを流す
	ld a, $ff

.noEngage
	ld [wTrainerSpriteOffset], a
	pop de
	pop hl
	ret

; **ReadTrainerScreenPosition**  
; トレーナーの 画面上の Y座標 と X座標 を wTrainerScreenX(Y) にロードする  
; - - -  
; INPUT: [wTrainerSpriteOffset] = 対象のトレーナーのスプライトオフセット  
; 
; OUTPUT:  
; [wTrainerScreenX] = [c1X6]  
; [wTrainerScreenY] = [c1X4]  
ReadTrainerScreenPosition:
	ld a, [wTrainerSpriteOffset]
	add $4
	ld d, $0
	ld e, a
	ld hl, wSpriteStateData1
	add hl, de
	ld a, [hl] ; c1x4 (sprite Y pos)
	ld [wTrainerScreenY], a
	ld a, [wTrainerSpriteOffset]
	add $6
	ld d, $0
	ld e, a
	ld hl, wSpriteStateData1
	add hl, de
	ld a, [hl] ; c1x6 (sprite X pos)
	ld [wTrainerScreenX], a
	ret

; **CheckSpriteCanSeePlayer**  
; トレーナーの視界の中に、プレイヤーが入りうるか判定する  
; - - -  
; まず処理対象のトレーナーの視界の中にプレイヤーがいるかと2者間の距離をチェックし、トレーナーがプレイヤーのほうを向いたら発見したことになるかを判定する  
; 
; INPUT: a = プレイヤーとトレーナー間の距離(16pxのマス目単位)  
; OUTPUT: carry = 1(トレーナーがプレイヤーのほうを向いたら発見したことになる) or 0(そうでない)  
CheckSpriteCanSeePlayer:
	; トレーナーの視界より遠くにプレイヤーがいる -> .notInLine
	ld b, a							; プレイヤーとトレーナー間の距離
	ld a, [wTrainerEngageDistance] 	; トレーナーの視界の範囲
	cp b
	jr nc, .checkIfLinedUp
	jr .notInLine         ; プレイヤーが遠すぎる

	; トレーナーとプレイヤーが直線上にいるかチェックする(直線上: 2点を結ぶ直線がマス目のグリッドに添う)
.checkIfLinedUp
	ld a, [wTrainerFacingDirection] ; a = トレーナーの方向 

	; トレーナーの向いている方向が上下なら X軸距離 が 0 つまり Y軸 が一致することをチェック
	cp SPRITE_FACING_DOWN
	jr z, .checkXCoord
	cp SPRITE_FACING_UP
	jr z, .checkXCoord

	; トレーナーの向いている方向が左右なら Y軸距離 が 0 つまり X軸 が一致することをチェック
	cp SPRITE_FACING_LEFT
	jr z, .checkYCoord
	cp SPRITE_FACING_RIGHT
	jr z, .checkYCoord

	jr .notInLine

.checkXCoord
	; Y軸 が一致 -> .inLine 不一致 -> .notInLine
	ld a, [wTrainerScreenX]         ; sprite screen X position
	ld b, a
	cp $40
	jr z, .inLine
	jr .notInLine

.checkYCoord
	; X軸 が一致 -> .inLine 不一致 -> .notInLine
	ld a, [wTrainerScreenY]         ; sprite screen Y position
	ld b, a
	cp $3c
	jr nz, .notInLine

.inLine
	scf		; set carry
	ret
.notInLine
	and a	; clear carry
	ret

; **CheckPlayerIsInFrontOfSprite**  
; トレーナーがプレイヤーの方を向いているかチェックする  
; - - -  
; OUTPUT: [wTrainerSpriteOffset] = 0xff(向いている) or 0x00(背を向けている)
CheckPlayerIsInFrontOfSprite:
	; マップが無人発電所　-> .engage
	ld a, [wCurMap]
	cp POWER_PLANT
	jp z, .engage       ; bypass this for power plant to get voltorb fake items to work

	; [wTrainerScreenY] = [c1X4] = トレーナーの画面内のY座標
	ld a, [wTrainerSpriteOffset]
	add $4
	ld d, $0
	ld e, a
	ld hl, wSpriteStateData1
	add hl, de			; hl = c1X4
	ld a, [hl]
	cp $fc				; 0xff-4(グリッド補正の分)
	jr nz, .notOnTopmostTile ; special case if sprite is on topmost tile (Y = $fc (-4)), make it come down a block
	ld a, $c
.notOnTopmostTile
	ld [wTrainerScreenY], a

	; [wTrainerScreenX] = [c1X6] = トレーナーの画面内のX座標
	ld a, [wTrainerSpriteOffset]
	add $6
	ld d, $0
	ld e, a
	ld hl, wSpriteStateData1
	add hl, de			; hl = c1X6
	ld a, [hl]
	ld [wTrainerScreenX], a

	ld a, [wTrainerFacingDirection]  ; a = トレーナーが下を向いていない

	cp SPRITE_FACING_DOWN
	jr nz, .notFacingDown	; トレーナーが下を向いていない -> .notFacingDown

; .facingDown
	ld a, [wTrainerScreenY]       ; sprite screen Y pos
	cp $3c
	jr c, .engage       ; sprite above player
	jr .noEngage        ; sprite below player

.notFacingDown
	cp SPRITE_FACING_UP
	jr nz, .notFacingUp

; .facingUp
	ld a, [wTrainerScreenY]
	cp $3c
	jr nc, .engage      ; プレイヤーの方をみている
	jr .noEngage        ; プレイヤーに背を向けている

.notFacingUp
	cp SPRITE_FACING_LEFT
	jr nz, .notFacingLeft

; .facingLeft
	ld a, [wTrainerScreenX]
	cp $40
	jr nc, .engage      ; プレイヤーの方をみている
	jr .noEngage        ; プレイヤーに背を向けている

.notFacingLeft	; .facingRight
	ld a, [wTrainerScreenX]
	cp $40
	jr nc, .noEngage    ; プレイヤーに背を向けている

.engage
	ld a, $ff
	jr .done
.noEngage
	xor a

.done
	ld [wTrainerSpriteOffset], a
	ret
