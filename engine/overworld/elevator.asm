; **ShakeElevator**  
;
; エレベータを揺らす処理
ShakeElevator:
	ld de, -$20
	call ShakeElevatorRedrawRow
	ld de, SCREEN_HEIGHT * $20
	call ShakeElevatorRedrawRow
	call Delay3

	; BGMをいったん消す
	ld a, $ff
	call PlaySound

	; d = スクロールY座標
	ld a, [hSCY]
	ld d, a

	ld e, $1	; 振動具合
	ld b, 100	; 振動する長さ

.shakeLoop
	; 背景を上下にスクロールさせて振動しているように見せたり、振動中のサウンドを鳴らしたりする

	; hSCYを変えて上下振動
	ld a, e
	xor $fe
	ld e, a
	add d
	ld [hSCY], a

	; 移動中の振動音を再生
	push bc
	ld c, BANK(SFX_Collision_1)
	ld a, SFX_COLLISION
	call PlayMusic
	pop bc

	; 少し待機
	ld c, 2
	call DelayFrames

	; まだ振動時間が残っている
	dec b
	jr nz, .shakeLoop

	; 振動終了(一瞬BGMを止めてそのあとピンポーンというサウンドを鳴らす)
	ld a, d
	ld [hSCY], a
	ld a, $ff
	call PlaySound
	ld c, BANK(SFX_Safari_Zone_PA)
	ld a, SFX_SAFARI_ZONE_PA
	call PlayMusic
.musicLoop
	ld a, [wChannelSoundIDs + Ch5]
	cp SFX_SAFARI_ZONE_PA
	jr z, .musicLoop		; ピンポーンという音楽を流し終えた
	; 通常のマップモードにもどる
	call UpdateSprites
	jp PlayDefaultMusic

; この関数は画面の特定の部分を再描画するために使われるものだが、視覚的効果をもたらしている様子はない  
; 結果として無駄なものである
; 
; INPUT:  
; de = ???
ShakeElevatorRedrawRow:
	; [wMapViewVRAMPointer], [wMapViewVRAMPointer + 1]を退避
	ld hl, wMapViewVRAMPointer + 1
	ld a, [hld]
	push af
	ld a, [hl]
	push af

	push hl		; hl = wMapViewVRAMPointer
	push hl
	ld a, [hli] ; a = [wMapViewVRAMPointer];
	ld h, [hl]  ; h = [wMapViewVRAMPointer + 1];
	ld l, a		; hl = ((wMapViewVRAMPointer + 1) << 8) | wMapViewVRAMPointer
	add hl, de
	ld a, h
	and $3
	or vBGMap0 / $100
	ld d, a
	ld a, l
	pop hl
	ld [hli], a
	ld [hl], d
	call ScheduleNorthRowRedraw
	pop hl
	pop af
	ld [hli], a
	pop af
	ld [hl], a
	jp Delay3
