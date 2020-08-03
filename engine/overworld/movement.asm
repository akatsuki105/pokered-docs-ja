; マップ上にテキストボックスが存在するとき、
; マップが表示されているのは Y <= $60つまり上から96pxまでであることを示している
MAP_TILESET_SIZE EQU $60

; **UpdatePlayerSprite**  
; プレイヤーの方向転換やアニメーション画像の変化を実行する関数
UpdatePlayerSprite:
	ld a, [wSpriteStateData2]
	and a
	jr z, .checkIfTextBoxInFrontOfSprite
	cp $ff
	jr z, .disableSprite
	dec a
	ld [wSpriteStateData2], a
	jr .disableSprite
; プレイヤーが立っている左下の背景タイルが$5F($5Fより大きいとテキストボックスに隠れる)より大きいかどうかを確認して、
; テキストボックスがスプライトの前にあるかどうかをチェック
.checkIfTextBoxInFrontOfSprite
	aCoord 8, 9						; a = プレイヤーがいる位置(基本的にプレイヤーは画面真ん中(64px, 72px)にいる)
	ld [hTilePlayerStandingOn], a
	cp MAP_TILESET_SIZE
	jr c, .lowerLeftTileIsMapTile
; プレイヤーを非表示
.disableSprite
	ld a, $ff
	ld [wSpriteStateData1 + 2], a
	ret
.lowerLeftTileIsMapTile
	; TODO: ???
	call DetectCollisionBetweenSprites
	ld h, wSpriteStateData1 / $100

	; wWalkCounter > 0 なら.movingへ
	ld a, [wWalkCounter]
	and a
	jr nz, .moving

	ld a, [wPlayerMovingDirection]
; check if down
	bit PLAYER_DIR_BIT_DOWN, a
	jr z, .checkIfUp
	xor a ; ld a, SPRITE_FACING_DOWN (SPRITE_FACING_DOWNは0なので)
	jr .next
.checkIfUp
	bit PLAYER_DIR_BIT_UP, a
	jr z, .checkIfLeft
	ld a, SPRITE_FACING_UP
	jr .next
.checkIfLeft
	bit PLAYER_DIR_BIT_LEFT, a
	jr z, .checkIfRight
	ld a, SPRITE_FACING_LEFT
	jr .next
.checkIfRight
	bit PLAYER_DIR_BIT_RIGHT, a
	jr z, .notMoving
	ld a, SPRITE_FACING_RIGHT
	jr .next
.notMoving
	; animation countersを0クリア
	xor a
	ld [wSpriteStateData1 + 7], a
	ld [wSpriteStateData1 + 8], a
	jr .calcImageIndex
.next
	ld [wSpriteStateData1 + 9], a	; 向いている方向を変更

	; フォントがロードされているので歩行できない
	ld a, [wFontLoaded]
	bit 0, a
	jr nz, .notMoving
.moving
	; プレイヤーがスピンタイルに乗ってスピンしている
	ld a, [wd736]
	bit 7, a
	jr nz, .skipSpriteAnim

	; intra-animation-frame counterをインクリメント
	ld a, [H_CURRENTSPRITEOFFSET]
	add $7
	ld l, a
	ld a, [hl]
	inc a
	ld [hl], a

	; intra-animation-frame counterが4ではない
	cp 4
	jr nz, .calcImageIndex

	; intra-animation-frame counterが4なので0にリセット
	; プレイヤーのanimation frame counterをインクリメント
	xor a
	ld [hl], a
	inc hl
	ld a, [hl]
	inc a
	and $3
	ld [hl], a
.calcImageIndex
	; $c1x2 = c1x8 + c1x9
	ld a, [wSpriteStateData1 + 8]
	ld b, a
	ld a, [wSpriteStateData1 + 9]
	add b
	ld [wSpriteStateData1 + 2], a

; 草むらにいるか判定してc2X7に結果を入れる
.skipSpriteAnim
	; プレイヤーが草むらにいるときにはプレイヤーのスプライトの描画優先度を背景より低くすることで草むら内にいることを表現する
	; スプライトの下半分のみが、後のロジックで優先ビットを設定できる
	ld a, [hTilePlayerStandingOn]
	ld c, a
	ld a, [wGrassTile]
	cp c
	ld a, $0		; 草むらにいない
	jr nz, .next2
	ld a, $80		; 草むらにいる
.next2
	ld [wSpriteStateData2 + 7], a
	ret

; 未使用  
UnusedReadSpriteDataFunction:
	push bc
	push af
	ld a, [H_CURRENTSPRITEOFFSET]
	ld c, a
	pop af
	add c
	ld l, a
	pop bc
	ret

; **UpdateNPCSprite**  
; NPCの移動を実行するスクリプト  
; - - -  
; NPCの移動 = wSpriteStateData1 と wSpriteStateData2 を更新すること  
; こうしておくことで VBlank中に OAMに状態が反映されて移動処理が実現する  
UpdateNPCSprite:
	; a = 処理中のスプライト番号 
	ld a, [H_CURRENTSPRITEOFFSET]
	swap a				; H_CURRENTSPRITEOFFSETは$10倍した値なので

	; hl = [movement byte 2, テキストID]
	dec a
	add a				; wMapSpriteDataは各2バイトなので2倍
	ld hl, wMapSpriteData
	add l
	ld l, a

	; wCurSpriteMovement2を現在処理中のスプライトの"movement byte 2"に更新
	ld a, [hl]        ; a = "movement byte 2"
	ld [wCurSpriteMovement2], a

	; a = 現在のスプライトの動作状況(c1X1)
	ld h, $c1
	ld a, [H_CURRENTSPRITEOFFSET]
	ld l, a
	inc l
	ld a, [hl]        ; c1x1
	; 未初期化なら初期化
	and a
	jp z, InitializeSpriteStatus

	; スプライトがテキストボックスに隠れていて非表示か、または草むらにいる、もしくは主人公が歩きモーション中か確認してそうなら戻る
	call CheckSpriteAvailability
	ret c             ; if sprite is invisible, on tile >=MAP_TILESET_SIZE, in grass or player is currently walking

	; a = c1x1 = スプライトの状態
	ld h, $c1
	ld a, [H_CURRENTSPRITEOFFSET]
	ld l, a
	inc l
	ld a, [hl]        ; c1x1

	; NPCがプレイヤーの方向を向いていないなら向かせる
	bit 7, a ; is the face player flag set?
	jp nz, MakeNPCFacePlayer

	; b = c1x1
	ld b, a

	; 会話の準備
	ld a, [wFontLoaded]
	bit 0, a
	jp nz, notYetMoving

	; スプライトがクールタイム中か、歩行中か
	ld a, b
	cp $2
	jp z, UpdateSpriteMovementDelay  ; c1x1 == 2
	cp $3
	jp z, UpdateSpriteInWalkingAnimation  ; c1x1 == 3

	; プレイヤーが歩きモーション中なら返る
	; すでにCheckSpriteAvailabilityで確認しているので余計なコード
	ld a, [wWalkCounter]
	and a
	ret nz

	; スプライトのXY座標を計算
	call InitializeSpriteScreenPosition

	; c2x6 = "movement byte 1"が$FEか$FFならランダムウォーク
	ld h, $c2
	ld a, [H_CURRENTSPRITEOFFSET]
	add $6
	ld l, a
	ld a, [hl]       ; c2x6: movement byte 1
	inc a
	jr z, .randomMovement  ; value $FF
	inc a
	jr z, .randomMovement  ; value $FE

	; 以後はscripted NPCの動作(.randomMovementまで)
	
	; [c2x6] + 2 - 1 = [c2X6] + 1
	dec a
	ld [hl], a       ; increment movement byte 1 (movement data index)
	; [c2x6] + 2 - 1 - 1 = [c2x6] 
	dec a
	push hl	; hl(c2x6)を退避

	; wNPCNumScriptedStepsを減らす
	ld hl, wNPCNumScriptedSteps
	dec [hl]         ; decrement wNPCNumScriptedSteps

	; a = [wNPCMovementDirections + "movement byte 1"] = 次のscripted NPCの動作
	pop hl
	ld de, wNPCMovementDirections
	call LoadDEPlusA

	; aを方向転換させるか
	cp $e0
	jp z, ChangeFacingDirection
	; またはaをその場にとどまらせ"ない"か
	cp STAY
	jr nz, .next

	; STAYのとき ここでscripted NPCの動作は終了
	ld [hl], a	; "movement byte 1"に$ffを設定して動作終了
	ld hl, wd730
	res 0, [hl]
	xor a
	ld [wSimulatedJoypadStatesIndex], a
	ld [wWastedByteCD3A], a
	ret
.next
	; "movement byte 1" != WALK($fe)
	cp WALK
	jr nz, .determineDirection

	; TODO: 何してるか不明
	; "movement byte 1" == WALK($fe). this seems buggy
	ld [hl], $1     ; "movement byte 1" = $1
	ld de, wNPCMovementDirections
	call LoadDEPlusA ; a = [wNPCMovementDirections + $fe] (?)
	jr .determineDirection
.randomMovement
	call GetTileSpriteStandsOn
	call Random

.determineDirection
	ld b, a				; aをbに退避

	; movement byte 2の方向データが優先される
	ld a, [wCurSpriteMovement2]
	cp $d0
	jr z, .moveDown    	; movement byte 2 = $d0 forces down
	cp $d1
	jr z, .moveUp      	; movement byte 2 = $d1 forces up
	cp $d2
	jr z, .moveLeft    	; movement byte 2 = $d2 forces left
	cp $d3
	jr z, .moveRight   	; movement byte 2 = $d3 forces right

	ld a, b				; bに退避しておいたaを復帰

	; a < $40: down (or left)
	cp $40             	
	jr nc, .notDown

	; movement byte 2 = $2 only allows left or right
	ld a, [wCurSpriteMovement2]
	cp $2
	jr z, .moveLeft

; 各方向に移動
.moveDown
	ld de, 2*SCREEN_WIDTH
	add hl, de         				; タイルポインタを画面2行(1行=8px)分下に
	lb de, 1, 0						; (x, y) = (0, +1)
	lb bc, 4, SPRITE_FACING_DOWN	
	jr TryWalking
.notDown
	cp $80             ; $40 <= a < $80: up (or right)
	jr nc, .notUp
	ld a, [wCurSpriteMovement2]
	cp $2
	jr z, .moveRight   ; movement byte 2 = $2 only allows left or right
.moveUp
	ld de, -2*SCREEN_WIDTH
	add hl, de         ; move tile pointer two rows up
	lb de, -1, 0
	lb bc, 8, SPRITE_FACING_UP
	jr TryWalking
.notUp
	cp $c0             ; $80 <= a < $c0: left (or up)
	jr nc, .notLeft
	ld a, [wCurSpriteMovement2]
	cp $1
	jr z, .moveUp      ; movement byte 2 = $1 only allows up or down
.moveLeft
	dec hl
	dec hl             ; move tile pointer two columns left
	lb de, 0, -1
	lb bc, 2, SPRITE_FACING_LEFT
	jr TryWalking
.notLeft              ; $c0 <= a: right (or down)
	ld a, [wCurSpriteMovement2]
	cp $1
	jr z, .moveDown    ; movement byte 2 = $1 only allows up or down
.moveRight
	inc hl
	inc hl             ; move tile pointer two columns right
	lb de, 0, 1
	lb bc, 1, SPRITE_FACING_RIGHT
	jr TryWalking

; 移動量を0にすることで向きの変更だけを行うようにし、そのまま下のTryWalkingへ
ChangeFacingDirection:
	ld de, $0
	; そのまま下の処理に(TryWalking)

; 止まっている状態から歩行を始める関数  
; - b: 方向(1, 2, 4, 8)
; - c: 新しく向く方向(0, 4, 8, $c)
; - d: Y移動量
; - e: X移動量
; - hl: スプライトが歩く先にあるスプライトのタイルへのポインタ
; 
; 成功時にはCフラグがクリア、失敗時にはセットされる
TryWalking:
	push hl

	; [c1x9] = c つまりスプライトの方向を更新
	ld h, $c1
	ld a, [H_CURRENTSPRITEOFFSET]
	add $9
	ld l, a
	ld [hl], c          ; c1x9 (update facing direction)

	; スプライトの座標を更新
	ld a, [H_CURRENTSPRITEOFFSET]
	add $3
	ld l, a
	ld [hl], d          ; c1x3 (update Y movement delta)
	inc l
	inc l
	ld [hl], e          ; c1x5 (update X movement delta)

	pop hl

	; スプライトが先のタイルマスに進行可能でないなら返る
	push de
	ld c, [hl]          ; read tile to walk onto
	call CanWalkOntoTile
	pop de
	ret c               ; cannot walk there (reinitialization of delay values already done)

	; c2x4, c2x5を更新
	ld h, $c2
	ld a, [H_CURRENTSPRITEOFFSET]
	add $4
	ld l, a
	ld a, [hl]          ; c2x4: Y position
	add d
	ld [hli], a         ; update Y position
	ld a, [hl]          ; c2x5: X position
	add e
	ld [hl], a          ; update X position

	; 歩きモーションカウンタを$10にセットする
	ld a, [H_CURRENTSPRITEOFFSET]
	ld l, a
	ld [hl], $10        ; c2x0=16: walk animation counter

	; スプライトの状態を歩きモーション中に
	dec h
	inc l
	ld [hl], $3         ; c1x1: set movement status to walking

	; 画像を歩きモーションの画像で更新
	jp UpdateSpriteImage

; update the walking animation parameters for a sprite that is currently walking
UpdateSpriteInWalkingAnimation:
	ld a, [H_CURRENTSPRITEOFFSET]
	add $7
	ld l, a
	ld a, [hl]                       ; c1x7 (counter until next walk animation frame)
	inc a
	ld [hl], a                       ; c1x7 += 1
	cp $4
	jr nz, .noNextAnimationFrame
	xor a
	ld [hl], a                       ; c1x7 = 0
	inc l
	ld a, [hl]                       ; c1x8 (walk animation frame)
	inc a
	and $3
	ld [hl], a                       ; advance to next animation frame every 4 ticks (16 ticks total for one step)
.noNextAnimationFrame
	ld a, [H_CURRENTSPRITEOFFSET]
	add $3
	ld l, a
	ld a, [hli]                      ; c1x3 (movement Y delta)
	ld b, a
	ld a, [hl]                       ; c1x4 (screen Y position)
	add b
	ld [hli], a                      ; update screen Y position
	ld a, [hli]                      ; c1x5 (movement X delta)
	ld b, a
	ld a, [hl]                       ; c1x6 (screen X position)
	add b
	ld [hl], a                       ; update screen X position
	ld a, [H_CURRENTSPRITEOFFSET]
	ld l, a
	inc h
	ld a, [hl]                       ; c2x0 (walk animation counter)
	dec a
	ld [hl], a                       ; update walk animation counter
	ret nz
	ld a, $6                         ; walking finished, update state
	add l
	ld l, a
	ld a, [hl]                       ; c2x6 (movement byte 1)
	cp $fe
	jr nc, .initNextMovementCounter  ; values $fe and $ff
	ld a, [H_CURRENTSPRITEOFFSET]
	inc a
	ld l, a
	dec h
	ld [hl], $1                      ; c1x1 = 1 (movement status ready)
	ret
.initNextMovementCounter
	call Random
	ld a, [H_CURRENTSPRITEOFFSET]
	add $8
	ld l, a
	ld a, [hRandomAdd]
	and $7f
	ld [hl], a                       ; c2x8: set next movement delay to a random value in [0,$7f]
	dec h                            ;       note that value 0 actually makes the delay $100 (bug?)
	ld a, [H_CURRENTSPRITEOFFSET]
	inc a
	ld l, a
	ld [hl], $2                      ; c1x1 = 2 (movement status)
	inc l
	inc l
	xor a
	ld b, [hl]                       ; c1x3 (movement Y delta)
	ld [hli], a                      ; reset movement Y delta
	inc l
	ld c, [hl]                       ; c1x5 (movement X delta)
	ld [hl], a                       ; reset movement X delta
	ret

; update delay value (c2x8) for sprites in the delayed state (c1x1)
UpdateSpriteMovementDelay:
	ld h, $c2
	ld a, [H_CURRENTSPRITEOFFSET]
	add $6
	ld l, a
	ld a, [hl]              ; c2x6: movement byte 1
	inc l
	inc l
	cp $fe
	jr nc, .tickMoveCounter ; values $fe or $ff
	ld [hl], $0
	jr .moving
.tickMoveCounter
	dec [hl]                ; c2x8: frame counter until next movement
	jr nz, notYetMoving
.moving
	dec h
	ld a, [H_CURRENTSPRITEOFFSET]
	inc a
	ld l, a
	ld [hl], $1             ; c1x1 = 1 (mark as ready to move)
notYetMoving:
	ld h, wSpriteStateData1 / $100
	ld a, [H_CURRENTSPRITEOFFSET]
	add $8
	ld l, a
	ld [hl], $0             ; c1x8 = 0 (walk animation frame)
	jp UpdateSpriteImage

; プレイヤーに話しかけられたときにNPCにプレイヤーの方向を向かせる関数
MakeNPCFacePlayer:
; プレイヤーに話しかけられたときに方向が変わらないNPCもいるのでそれの確認を行う  
; これはサントアンヌ号の船長の背後から話しかけたときのみ起こる
	ld a, [wd72d]
	bit 5, a
	jr nz, notYetMoving
	res 7, [hl]
	ld a, [wPlayerDirection]
	bit PLAYER_DIR_BIT_UP, a
	jr z, .notFacingDown
	ld c, SPRITE_FACING_DOWN
	jr .facingDirectionDetermined
.notFacingDown
	bit PLAYER_DIR_BIT_DOWN, a
	jr z, .notFacingUp
	ld c, SPRITE_FACING_UP
	jr .facingDirectionDetermined
.notFacingUp
	bit PLAYER_DIR_BIT_LEFT, a
	jr z, .notFacingRight
	ld c, SPRITE_FACING_RIGHT
	jr .facingDirectionDetermined
.notFacingRight
	ld c, SPRITE_FACING_LEFT
.facingDirectionDetermined
	ld a, [H_CURRENTSPRITEOFFSET]
	add $9
	ld l, a
	ld [hl], c              ; c1x9: set facing direction
	jr notYetMoving

InitializeSpriteStatus:
	ld [hl], $1   ; $c1x1: set movement status to ready
	inc l
	ld [hl], $ff  ; $c1x2: set sprite image to $ff (invisible/off screen)
	inc h
	ld a, [H_CURRENTSPRITEOFFSET]
	add $2
	ld l, a
	ld a, $8
	ld [hli], a   ; $c2x2: set Y displacement to 8
	ld [hl], a    ; $c2x3: set X displacement to 8
	ret

; マップの位置とプレーヤーの位置からスプライトの画面位置を計算
InitializeSpriteScreenPosition:
	; hl = c2X4
	ld h, wSpriteStateData2 / $100
	ld a, [H_CURRENTSPRITEOFFSET]
	add $4
	ld l, a

	; b = プレイヤーのY座標(16*16pxのタイルブロック単位)
	ld a, [wYCoord]
	ld b, a

	; スプライトのプレイヤー相対Y座標を計算
	ld a, [hl]      ; c2x4 (Y position + 4)
	sub b           ; relative to player position
	swap a          ; a *= 16 タイルブロック単位 => ピクセル単位
	sub $4          ; - 4
	; 計算したY座標をc1x4に格納
	dec h
	ld [hli], a     ; c1x4 (screen Y position)
	inc h

	; b = プレイヤーのX座標(16*16pxのタイルブロック単位)
	ld a, [wXCoord]
	ld b, a

	; スプライトのプレイヤー相対X座標を計算
	ld a, [hli]     ; c2x6 (X position + 4)
	sub b           ; relative to player position
	swap a          ; * 16
	; 計算したX座標をc1x6に格納
	dec h
	ld [hl], a      ; c1x6 (screen X position)
	ret

; スプライトが非表示か、何もできない状態であるか確認する
; 何もできない状態 = 主人公が歩きモーション中のときとかが該当する
CheckSpriteAvailability:
	; スプライトが非表示状態か確認
	predef IsObjectHidden
	ld a, [$ffe5]
	and a
	jp nz, .spriteInvisible			; スプライトは非表示

	; a = [$c2X6] = "movement byte 1" ($ff:動かない, $fe:ランダムに歩く, それ以外は未使用) 
	ld h, wSpriteStateData2 / $100	; h = $c2
	ld a, [H_CURRENTSPRITEOFFSET]
	add $6
	ld l, a
	ld a, [hl]

	cp $fe
	jr c, .skipXVisibilityTest ; "movement byte 1" < $fe (スプライトの動きがプログラム化されているときなど)

	; b = [$c2X4] = スプライトのY座標
	ld a, [H_CURRENTSPRITEOFFSET]
	add $4
	ld l, a
	ld b, [hl]

	ld a, [wYCoord]
	cp b
	jr z, .skipYVisibilityTest	; プレイヤーとスプライトのY座標が一致
	jr nc, .spriteInvisible ; スプライトがプレイヤーより画面上で上にいる
	add $8                  ; screen is 9 tiles high
	cp b
	jr c, .spriteInvisible  ; スプライトがプレイヤーより画面上で下にいる
.skipYVisibilityTest
	inc l
	ld b, [hl]      ; c2x5: X pos (+4)
	ld a, [wXCoord]
	cp b
	jr z, .skipXVisibilityTest	; プレイヤーとスプライトのX座標が一致
	jr nc, .spriteInvisible ; スプライトがプレイヤーより画面上で左にいる
	add $9                  ; screen is 10 tiles wide
	cp b
	jr c, .spriteInvisible  ; スプライトがプレイヤーより画面上で右にいる

; テキストボックスで隠れるときにスプライトを非表示にする  
; $5F is the maximum number for map tiles
.skipXVisibilityTest
	call GetTileSpriteStandsOn
	ld d, MAP_TILESET_SIZE
	ld a, [hli]
	cp d
	jr nc, .spriteInvisible ; スプライトがいるグリッド(16*16px)の左下のタイル(8*8px)がテキストボックスに隠れている
	ld a, [hld]
	cp d
	jr nc, .spriteInvisible ; スプライトがいるグリッド(16*16px)の右下のタイル(8*8px)がテキストボックスに隠れている

	; 1行分(20 = 160/8)上に戻る
	ld bc, -20
	add hl, bc              ; go back one row of tiles

	ld a, [hli]
	cp d
	jr nc, .spriteInvisible ; スプライトがいるグリッド(16*16px)の右上のタイル(8*8px)がテキストボックスに隠れている
	ld a, [hl]
	cp d
	jr c, .spriteVisible    ; スプライトがいるグリッド(16*16px)の右上のタイル(8*8px)がテキストボックスに隠れてい"ない"

; スプライトを画面非表示にする
.spriteInvisible
	; a = c1X2 = スプライトのイメージ番号($ffなら画面非表示)
	ld h, wSpriteStateData1 / $100
	ld a, [H_CURRENTSPRITEOFFSET]
	add $2
	ld l, a
	; c1X2 = $ff
	ld [hl], $ff       ; c1x2
	scf
	jr .done
; スプライトを画面に表示する
.spriteVisible
	ld c, a

	; a = wWalkCounter = 0 つまりプレイヤーが現在歩きモーション中でないことを確認
	ld a, [wWalkCounter]
	and a
	jr nz, .done           ; if player is currently walking, we're done

	call UpdateSpriteImage ; c1X2を更新

	; hl = c2X7
	inc h
	ld a, [H_CURRENTSPRITEOFFSET]
	add $7
	ld l, a

	; スプライトが草むらにいるか確認
	ld a, [wGrassTile]
	cp c
	ld a, $0		; 草むらにいない c2X7 = $00
	jr nz, .notInGrass

	ld a, $80		; 草むらにいる c2X7 = $80
.notInGrass
	ld [hl], a       ; c2x7
	and a
.done
	ret

; $c1X2を更新する
UpdateSpriteImage:
	; hl = $c1X8
	ld h, $c1
	ld a, [H_CURRENTSPRITEOFFSET]
	add $8
	ld l, a

	; a = スプライトの方向
	; b = 歩きモーションカウンタ
	ld a, [hli]        ; c1x8: walk animation frame
	ld b, a
	ld a, [hl]         ; c1x9: facing direction
	; b = a + b
	add b
	ld b, a

	ld a, [$ff93]  ; current sprite offset (VRAMオフセット)
	add b
	ld b, a

	; hl = $c1X2 = スプライトのイメージ番号
	ld a, [H_CURRENTSPRITEOFFSET]
	add $2
	ld l, a

	ld [hl], b         ; c1x2: sprite to display
	ret

; スプライトが指定した方向に進行可能かチェック  
; INPUT:
; - b = 方向 (1,2,4 or 8)
; - c = ID of tile the sprite would walk onto
; - c = スプライトが進行する先のタイルID
; - d = Y変化量 (-1, 0 or 1)
; - e = X変化量 (-1, 0 or 1)
; 
; 進行できないならCフラグがセット、進行可能ならCフラグがクリア
CanWalkOntoTile:
	ld h, wSpriteStateData2 / $100
	ld a, [H_CURRENTSPRITEOFFSET]
	add $6
	ld l, a
	ld a, [hl]         ; c2x6 (movement byte 1)
	cp $fe
	jr nc, .notScripted    ; values $fe and $ff
; always allow walking if the movement is scripted
	and a
	ret
.notScripted
	ld a, [wTilesetCollisionPtr]
	ld l, a
	ld a, [wTilesetCollisionPtr+1]
	ld h, a
.tilePassableLoop
	ld a, [hli]
	cp $ff
	jr z, .impassable
	cp c
	jr nz, .tilePassableLoop
	ld h, $c2
	ld a, [H_CURRENTSPRITEOFFSET]
	add $6
	ld l, a
	ld a, [hl]         ; $c2x6 (movement byte 1)
	inc a
	jr z, .impassable  ; if $ff, no movement allowed (however, changing direction is)
	ld h, wSpriteStateData1 / $100
	ld a, [H_CURRENTSPRITEOFFSET]
	add $4
	ld l, a
	ld a, [hli]        ; c1x4 (screen Y pos)
	add $4             ; align to blocks (Y pos is always 4 pixels off)
	add d              ; add Y delta
	cp $80             ; if value is >$80, the destination is off screen (either $81 or $FF underflow)
	jr nc, .impassable ; don't walk off screen
	inc l
	ld a, [hl]         ; c1x6 (screen X pos)
	add e              ; add X delta
	cp $90             ; if value is >$90, the destination is off screen (either $91 or $FF underflow)
	jr nc, .impassable ; don't walk off screen
	push de
	push bc
	call DetectCollisionBetweenSprites
	pop bc
	pop de
	ld h, wSpriteStateData1 / $100
	ld a, [H_CURRENTSPRITEOFFSET]
	add $c
	ld l, a
	ld a, [hl]         ; c1xc (directions in which sprite collision would occur)
	and b              ; check against chosen direction (1,2,4 or 8)
	jr nz, .impassable ; collision between sprites, don't go there
	ld h, wSpriteStateData2 / $100
	ld a, [H_CURRENTSPRITEOFFSET]
	add $2
	ld l, a
	ld a, [hli]        ; c2x2 (sprite Y displacement, initialized at $8, keep track of where a sprite did go)
	bit 7, d           ; check if going upwards (d=$ff)
	jr nz, .upwards
	add d
	cp $5
	jr c, .impassable  ; if c2x2+d < 5, don't go ;bug: this tests probably were supposed to prevent sprites
	jr .checkHorizontal                          ; from walking out too far, but this line makes sprites get stuck
.upwards                                         ; whenever they walked upwards 5 steps
	sub $1                                       ; on the other hand, the amount a sprite can walk out to the
	jr c, .impassable  ; if d2x2 == 0, don't go  ; right of bottom is not limited (until the counter overflows)
.checkHorizontal
	ld d, a
	ld a, [hl]         ; c2x3 (sprite X displacement, initialized at $8, keep track of where a sprite did go)
	bit 7, e           ; check if going left (e=$ff)
	jr nz, .left
	add e
	cp $5              ; compare, but no conditional jump like in the vertical check above (bug?)
	jr .passable
.left
	sub $1
	jr c, .impassable  ; if d2x3 == 0, don't go
.passable
	ld [hld], a        ; update c2x3
	ld [hl], d         ; update c2x2
	and a              ; clear carry (marking success)
	ret
.impassable
	ld h, $c1
	ld a, [H_CURRENTSPRITEOFFSET]
	inc a
	ld l, a
	ld [hl], $2        ; c1x1 = 2 (set movement status to delayed)
	inc l
	inc l
	xor a
	ld [hli], a        ; c1x3 = 0 (clear Y movement delta)
	inc l
	ld [hl], a         ; c1x5 = 0 (clear X movement delta)
	inc h
	ld a, [H_CURRENTSPRITEOFFSET]
	add $8
	ld l, a
	call Random
	ld a, [hRandomAdd]
	and $7f
	ld [hl], a         ; c2x8: set next movement delay to a random value in [0,$7f] (again with delay $100 if value is 0)
	scf                ; set carry (marking failure to walk)
	ret

; 現在のスプライトが表示されている場所のアドレスのポインタを計算する  
; これは常に、すべてのスプライトがスナップされる2x2タイルブロック(16*16)の左下のタイルとなる  
; hlに結果(ポインタ)が格納されて返る
; 
; 例:  
; 例えばスクリーン左上から見て左3タイル目、上から4タイル目( (x, y)=(3,4) )の位置にスプライトが立っているなら、
; wTileMap + 20*(4 + 1) + 3のアドレスがhlに格納されて返る(yが+1されているのはコードを参照)
GetTileSpriteStandsOn:
	; a = c1x4 = スプライトのY座標
	ld h, wSpriteStateData1 / $100
	ld a, [H_CURRENTSPRITEOFFSET]
	add $4
	ld l, a
	ld a, [hli]

	add $4          ; タイルブロックに合わせる(Y座標は常に4px分加算されているので+4して+8にしてタイルに合わせる)
	and $f0         ; TODO: in case object is currently moving
	srl a           ; screen Y tile * 4
	ld c, a
	ld b, $0

	; a = c1X6 = スプライトのX座標
	inc l
	ld a, [hl]      ; c1x6: screen X position
	srl a
	srl a
	srl a            ; screen X tile
	add SCREEN_WIDTH ; screen X tile + 20
	ld d, $0
	ld e, a

	; hl = wTileMapの始点
	coord hl, 0, 0

	; wTileMap + 20*(screen Y tile + 1) + screen X tile
	; hlに現在処理中のスプライトが存在している画面のバッファアドレスが入る
	add hl, bc
	add hl, bc
	add hl, bc
	add hl, bc
	add hl, bc
	add hl, de     ; hl = 5*bc + de
	ret

; loads [de+a] into a
LoadDEPlusA:
	add e
	ld e, a
	jr nc, .noCarry
	inc d
.noCarry
	ld a, [de]
	ret

; **DoScriptedNPCMovement**  
; - NPCの動きをプログラムするメソッドの代替品  
; - ゲーム内でも数回しか利用されていない  
; - NPCとプレイヤーが同時に動く場合(例えば強制的な連行イベント)に使われる 
; - 他のメソッドでNPCをプレイヤーと同じタイミングで動かすことはできない
DoScriptedNPCMovement:
	; wd730[7]が0なら何もしない
	ld a, [wd730]
	bit 7, a
	ret z

	; InitScriptedNPCMovementが必ず行われている状態にする
	ld hl, wd72e
	bit 7, [hl]
	set 7, [hl]
	jp z, InitScriptedNPCMovement	; まだ行われていないなら実行(wd72e[7]を見て判断)

	; hl = wNPCMovementDirections2 + [wNPCMovementDirections2Index]
	ld hl, wNPCMovementDirections2
	ld a, [wNPCMovementDirections2Index]
	add l						
	ld l, a
	jr nc, .noCarry
	inc h				; キャリーがあった場合は帳尻を合わせる
.noCarry
	ld a, [hl]
	
	; NPCが上に動いているかチェック
	cp NPC_MOVEMENT_UP
	jr nz, .checkIfMovingDown		; そうでないなら次は下に動いているか
	; NPCが上に動いている場合
	call GetSpriteScreenYPointer
	ld c, SPRITE_FACING_UP
	ld a, -2
	jr .move
.checkIfMovingDown	; 下
	cp NPC_MOVEMENT_DOWN
	jr nz, .checkIfMovingLeft
	call GetSpriteScreenYPointer
	ld c, SPRITE_FACING_DOWN
	ld a, 2
	jr .move
.checkIfMovingLeft	; 左
	cp NPC_MOVEMENT_LEFT
	jr nz, .checkIfMovingRight
	call GetSpriteScreenXPointer
	ld c, SPRITE_FACING_LEFT
	ld a, -2
	jr .move
.checkIfMovingRight	; 右
	cp NPC_MOVEMENT_RIGHT
	jr nz, .noMatch
	call GetSpriteScreenXPointer
	ld c, SPRITE_FACING_RIGHT
	ld a, 2
	jr .move
.noMatch
	cp $ff
	ret
; スプライトを移動させる、つまり座標などの位置データを変更する  
; a = 移動量  
; c = 移動方向  
; l = 元のXまたはY座標のポインタ
.move
	; 座標に移動量を加える
	ld b, a
	ld a, [hl]
	add b
	ld [hl], a		; [hl] += a

	; hl = スプライトの方向のポインタ
	ld a, [H_CURRENTSPRITEOFFSET]
	add $9
	ld l, a							; hは上でc1がセットされたままなので

	; 方向を設定
	ld a, c
	ld [hl], a ; facing direction

	call AnimScriptedNPCMovement	; スプライトのアニメーションを更新
	
	; wScriptedNPCWalkCounter(8から減っていく)を減らす
	ld hl, wScriptedNPCWalkCounter
	dec [hl]
	ret nz
	; wScriptedNPCWalkCounterが0になった
	ld a, 8
	ld [wScriptedNPCWalkCounter], a
	ld hl, wNPCMovementDirections2Index
	inc [hl]
	ret

InitScriptedNPCMovement:
	xor a
	ld [wNPCMovementDirections2Index], a
	ld a, 8
	ld [wScriptedNPCWalkCounter], a
	jp AnimScriptedNPCMovement

; 現在処理中のスプライトのY座標を返す
GetSpriteScreenYPointer:
	ld a, $4			; GetSpriteScreenXYPointerCommonでc1X4とするため
	ld b, a
	jr GetSpriteScreenXYPointerCommon

; 現在処理中のスプライトのX座標を返す
GetSpriteScreenXPointer:
	ld a, $6			; GetSpriteScreenXYPointerCommonでc1X6とするため
	ld b, a

; 現在処理中のスプライトのXまたはY座標を返す  
; bに x座標が欲しいなら$6,  y座標が欲しいなら$4を入れる  
; lに座標のポインタが入って帰ってくる
GetSpriteScreenXYPointerCommon:
	ld hl, wSpriteStateData1
	ld a, [H_CURRENTSPRITEOFFSET]
	add l
	add b		; a = wSpriteStateData1 + [H_CURRENTSPRITEOFFSET] + b
	ld l, a
	ret

AnimScriptedNPCMovement:
	; [hl] = スプライトのイメージデータ(2bppデータ?)があるアドレス
	ld hl, wSpriteStateData2
	ld a, [H_CURRENTSPRITEOFFSET]
	add $e
	ld l, a
	
	; TODO
	; b = VRAMスロット
	ld a, [hl] 	; VRAM slot
	dec a
	swap a		; AAAABBBB -> BBBBAAAA
	ld b, a
	
	; a = スプライトの移動方向
	ld hl, wSpriteStateData1
	ld a, [H_CURRENTSPRITEOFFSET]
	add $9
	ld l, a
	ld a, [hl] ; facing direction

	cp SPRITE_FACING_DOWN
	jr z, .anim
	cp SPRITE_FACING_UP
	jr z, .anim
	cp SPRITE_FACING_LEFT
	jr z, .anim
	cp SPRITE_FACING_RIGHT
	jr z, .anim
	ret
; a = スプライトの方向 0x00 or 0x04 or 0x08 or 0x0c 
; b = VRAMスロット
.anim
	; hSpriteVRAMSlotAndFacing を現在の方向に更新
	add b
	ld b, a
	ld [hSpriteVRAMSlotAndFacing], a
	
	; アニメーションフレームを更新
	call AdvanceScriptedNPCAnimFrameCounter
	
	; [hl] = c1X2
	ld hl, wSpriteStateData1
	ld a, [H_CURRENTSPRITEOFFSET]
	add $2
	ld l, a

	; c1X2 = [hSpriteVRAMSlotAndFacing] + [hSpriteAnimFrameCounter]
	; つまりスプライトのイメージ番号を更新
	ld a, [hSpriteVRAMSlotAndFacing]
	ld b, a
	ld a, [hSpriteAnimFrameCounter]
	add b
	ld [hl], a
	ret

; プログラムされたNPCのフレームカウンタ(c1X7)を進める関数  
; フレームカウンタが4になっていたら0にリセットしてアニメーションカウンタ(c1X8)をインクリメント
AdvanceScriptedNPCAnimFrameCounter:
	; フレームカウンタ(c1X7)をインクリメント
	ld a, [H_CURRENTSPRITEOFFSET]
	add $7
	ld l, a
	ld a, [hl]
	inc a
	ld [hl], a

	; フレームカウンタが4になっていたら0にリセット
	cp 4
	ret nz
	xor a
	ld [hl], a ; reset intra-animation frame counter

	; アニメーションカウンタ(c1X8)をインクリメント
	inc l
	ld a, [hl] ; animation frame counter
	inc a
	and $3			; c1X8が4になったら0に戻す
	ld [hl], a
	ld [hSpriteAnimFrameCounter], a
	ret
