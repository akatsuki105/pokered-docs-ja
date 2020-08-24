; **TryPushingBoulder**  
; かいりきの岩を押そうとしているか判定する  
; - - -  
; Map script(おそらくマップ上で定期的に走っている処理)  
; 
; OUTPUT: wFlags_0xcd60の bit1 = 1(押すことになった) or 0(ならなかった)  
TryPushingBoulder:
	; かいりき状態でない -> return
	ld a, [wd728]
	bit 0, a
	ret z

	; まだ前回のかいりきによる土埃アニメーションが再生中 -> return
	ld a, [wFlags_0xcd60]
	bit 1, a
	ret nz

	; a = プレイヤーの目の前のスプライトのスプライトオフセット
	xor a
	ld [hSpriteIndexOrTextID], a
	call IsSpriteInFrontOfPlayer
	ld a, [hSpriteIndexOrTextID]

	; 目の前にスプライト(この場合はかいりきの岩を想定)がなかった -> ResetBoulderPushFlags -> return
	ld [wBoulderSpriteIndex], a
	and a
	jp z, ResetBoulderPushFlags	; return

	; かいりき岩の $C1X1の 7bit目をクリア
	ld hl, wSpriteStateData1 + 1
	ld d, $0
	ld a, [hSpriteIndexOrTextID]
	swap a
	ld e, a
	add hl, de	; hl = $C1X1
	res 7, [hl]	; 7bit目 はスプライトがプレイヤーのほうを見ているときに立つbit

	; movement byte 2 == BOULDER_MOVEMENT_BYTE_2 を確認することで、プレイヤーの目の前のスプライトが かいりき岩であることを確認
	call GetSpriteMovementByte2Pointer
	ld a, [hl]
	cp BOULDER_MOVEMENT_BYTE_2
	jp nz, ResetBoulderPushFlags	; そうでないなら -> ResetBoulderPushFlags -> return

	; wFlags_0xcd60[6] = 1 またすでに 1がセットされていた時、つまり岩が動きだす前に、この処理が2回走ってしまった場合は return
	ld hl, wFlags_0xcd60
	bit 6, [hl]
	set 6, [hl] ; プレイヤーが岩を押そうとした状態であることを示す
	ret z

	; どの方向キーも押されていないときは return
	ld a, [hJoyHeld]
	and D_RIGHT | D_LEFT | D_UP | D_DOWN
	ret z

	; かいりきで岩を押した先に障害物がある場合 -> ResetBoulderPushFlags
	predef CheckForCollisionWhenPushingBoulder
	ld a, [wTileInFrontOfBoulderAndBoulderCollisionResult]
	and a
	jp nz, ResetBoulderPushFlags

	; b = 押されている状態のキー入力 [↓, ↑, ←, →, Start, Select, B, A]
	ld a, [hJoyHeld]
	ld b, a

; プレイヤーの向いている方向によって分岐
	ld a, [wSpriteStateData1 + 9] ; $C109 = プレイヤーの方向
	cp SPRITE_FACING_UP
	jr z, .pushBoulderUp
	cp SPRITE_FACING_LEFT
	jr z, .pushBoulderLeft
	cp SPRITE_FACING_RIGHT
	jr z, .pushBoulderRight

; プレイヤーの向いている方向にキーが押されていることをチェック(押されていないならreturn)  
; 押されているなら de = PushBoulder${Direction}MovementData して .doneへ  
.pushBoulderDown
	bit 7, b
	ret z
	ld de, PushBoulderDownMovementData
	jr .done
.pushBoulderUp
	bit 6, b
	ret z
	ld de, PushBoulderUpMovementData
	jr .done
.pushBoulderLeft
	bit 5, b
	ret z
	ld de, PushBoulderLeftMovementData
	jr .done
.pushBoulderRight
	bit 4, b
	ret z
	ld de, PushBoulderRightMovementData

; ここに来たら かいりきの岩を押しはじめたことが確定しているのでサウンドなどを流して return
.done
	call MoveSprite
	ld a, SFX_PUSH_BOULDER
	call PlaySound	; かいりきの押したときの音を再生
	ld hl, wFlags_0xcd60
	set 1, [hl]
	ret

PushBoulderUpMovementData:
	db NPC_MOVEMENT_UP,$FF

PushBoulderDownMovementData:
	db NPC_MOVEMENT_DOWN,$FF

PushBoulderLeftMovementData:
	db NPC_MOVEMENT_LEFT,$FF

PushBoulderRightMovementData:
	db NPC_MOVEMENT_RIGHT,$FF

; **DoBoulderDustAnimation**  
; かいりきのアニメーション処理  
; - - -  
; 土埃のアニメーション処理 + かいりきフラグのクリア + かいりきのサウンド再生  
DoBoulderDustAnimation:
	; NPCスプライトがスクリプトによって動かされている -> return
	ld a, [wd730]
	bit 0, a
	ret nz
	
	callab AnimateBoulderDust
	
	; wFlags_0xcd60 のかいりきフラグをクリアする  
	call DiscardButtonPresses
	ld [wJoyIgnore], a	; DiscardButtonPresses で a = 0になっている
	call ResetBoulderPushFlags
	set 7, [hl]			; wFlags_0xcd60[7] = 1 ???

	; かいりき岩のスプライトスロットの movement byte 2 に BOULDER_MOVEMENT_BYTE_2 をセット  
	ld a, [wBoulderSpriteIndex]
	ld [H_SPRITEINDEX], a
	call GetSpriteMovementByte2Pointer
	ld [hl], BOULDER_MOVEMENT_BYTE_2

	; かいりきのサウンドを再生
	ld a, SFX_CUT
	jp PlaySound	; return

; wFlags_0xcd60 のかいりきフラグをクリアする  
ResetBoulderPushFlags:
	ld hl, wFlags_0xcd60
	res 1, [hl]
	res 6, [hl]
	ret
