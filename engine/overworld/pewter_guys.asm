; **PewterGuys**  
; ニビシティの強制連行イベントのトリガーとなるマスにプレイヤーがいるか判定し、いるならsimulated joypadのキー入力を与える  
; pewter guyとsimulated joypadについてはドキュメント参照  
PewterGuys:
	ld hl, wSimulatedJoypadStatesEnd

	; [wSimulatedJoypadStatesIndex]--
	ld a, [wSimulatedJoypadStatesIndex]
	dec a ; this decrement causes it to overwrite the last byte before $FF in the list
	ld [wSimulatedJoypadStatesIndex], a
	
	; de = wSimulatedJoypadStatesEnd + [wSimulatedJoypadStatesIndex]
	ld d, 0
	ld e, a
	add hl, de
	ld d, h
	ld e, l

	; hl = PewterMuseumGuyCoords([wWhichPewterGuy] = 0) or PewterGymGuyCoords([wWhichPewterGuy] = 1)
	ld hl, PointerTable_37ce6
	ld a, [wWhichPewterGuy]
	add a
	ld b, 0
	ld c, a
	add hl, bc

	; 最初のエントリのcoord (findMatchingCoordsLoopのinit処理)
	ld a, [hli]
	ld h, [hl]
	ld l, a
	
	; bc = プレイヤーのcoord
	ld a, [wYCoord]
	ld b, a
	ld a, [wXCoord]
	ld c, a

	; イベントcoordのリストからプレイヤーのcoordと一致するものを探索
.findMatchingCoordsLoop
	; 検討中のイベントcoordと一致しないなら次のエントリ
	ld a, [hli]
	cp b
	jr nz, .nextEntry1
	ld a, [hli]
	cp c
	jr nz, .nextEntry2

	; プレイヤーがイベントマスにいる
	ld a, [hli]
	ld h, [hl]
	ld l, a

	; イベントcoordのsimulated joypad(e.g. .down, .one)の入力を(wSimulatedJoypadStatesEnd + [wSimulatedJoypadStatesIndex])にコピーしていく  
	; simulated joypadについてはドキュメント参照
.copyMovementDataLoop
	; a = 現在のループでのmovement data
	ld a, [hli]
	; movement dataが終了(ループが終了)
	cp $ff
	ret z

	; wSimulatedJoypadStatesEnd + [wSimulatedJoypadStatesIndex] = movement data
	ld [de], a
	inc de

	; [wSimulatedJoypadStatesIndex]++
	ld a, [wSimulatedJoypadStatesIndex]
	inc a
	ld [wSimulatedJoypadStatesIndex], a
	
	; 次のループ
	jr .copyMovementDataLoop
.nextEntry1
	inc hl
.nextEntry2
	inc hl
	inc hl
	jr .findMatchingCoordsLoop

PointerTable_37ce6:
	dw PewterMuseumGuyCoords
	dw PewterGymGuyCoords

; these are the four coordinates of the spaces below, above, to the left and
; to the right of the museum guy, and pointers to different movements for
; the player to make to get positioned before the main movement.
; 
; 『ニビ科学博物館』のスプライトの上下左右のcoordsのテーブル  
PewterMuseumGuyCoords:
	db 18, 27
	dw .down
	db 16, 27
	dw .up
	db 17, 26
	dw .left
	db 17, 28
	dw .right

.down
	db D_UP, D_UP, $ff
.up
	db D_RIGHT, D_LEFT, $ff
.left
	db D_UP, D_RIGHT, $ff
.right
	db D_UP, D_LEFT, $ff

; these are the five coordinates which trigger the gym guy and pointers to
; different movements for the player to make to get positioned before the
; main movement
; $00 is a pause
; gym guyによる連行イベントのトリガーとなる5個のcoordsと ???  
PewterGymGuyCoords:
	db 16, 34
	dw .one
	db 17, 35
	dw .two
	db 18, 37
	dw .three
	db 19, 37
	dw .four
	db 17, 36
	dw .five

.one
	db D_LEFT, D_DOWN, D_DOWN, D_RIGHT, $ff
.two
	db D_LEFT, D_DOWN, D_RIGHT, D_LEFT, $ff
.three
	db D_LEFT, D_LEFT, D_LEFT, $00, $00, $00, $00, $00, $00, $00, $00, $ff
.four
	db D_LEFT, D_LEFT, D_UP, D_LEFT, $ff
.five
	db D_LEFT, D_DOWN, D_LEFT, $00, $00, $00, $00, $00, $00, $00, $00, $ff
