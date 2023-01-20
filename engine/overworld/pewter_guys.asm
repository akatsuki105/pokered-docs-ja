; **PewterGuys**  
; 強制連行イベントのトリガーとなるマスにプレイヤーがいるか判定しいるなら、連行データの初期位置まで動く movement data を wSimulatedJoypadStatesEnd に加える
; - - -  
; この関数が呼ばれた時点で、 wSimulatedJoypadStatesEnd には、初期位置からニビジム(or ニビ科学博物館)までの movement data が入っている  
; 
; ニビ科学博物館の場合は、museum guyの上のマスが、ニビジムの場合は 看板の右上のマスが初期位置
PewterGuys:
	ld hl, wSimulatedJoypadStatesEnd

	; [wSimulatedJoypadStatesIndex]-- (wSimulatedJoypadStatesEnd の最後の 0xff を消すために)
	ld a, [wSimulatedJoypadStatesIndex]
	dec a
	ld [wSimulatedJoypadStatesIndex], a
	
	; de = wSimulatedJoypadStatesEnd + [wSimulatedJoypadStatesIndex] (初期位置からの連行データ)
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

	; 最初のエントリのcoord (findMatchingCoordsLoop のinit処理)
	inline "hl = [hl]"
	
	; bc = プレイヤーのcoord
	ld a, [wYCoord]
	ld b, a
	ld a, [wXCoord]
	ld c, a

; イベントマス(hl の coord)のリストからプレイヤーの coord と一致するものがあるかみていく
.findMatchingCoordsLoop
	; 検討中のイベントcoordと一致しないなら次のエントリ
	ld a, [hli]
	cp b
	jr nz, .nextEntry1
	ld a, [hli]
	cp c
	jr nz, .nextEntry2

	; プレイヤーがイベントマスにいる
	inline "hl = [hl]"

; イベントマスに対応する movement data を wSimulatedJoypadStatesEnd に付け足していく
.copyMovementDataLoop
; {
	; a = movement data
	ld a, [hli]

	; 付け足し終えた -> return
	cp $ff
	ret z

	; 付け足し処理
	; wSimulatedJoypadStatesEnd + [wSimulatedJoypadStatesIndex] = movement data
	ld [de], a
	inc de

	; [wSimulatedJoypadStatesIndex]++
	ld a, [wSimulatedJoypadStatesIndex]
	inc a
	ld [wSimulatedJoypadStatesIndex], a
	
	; 次のループ(.copyMovementDataLoop)
	jr .copyMovementDataLoop
; }

; 次のループ(.findMatchingCoordsLoop)
.nextEntry1
	inc hl
.nextEntry2
	inc hl
	inc hl
	jr .findMatchingCoordsLoop

PointerTable_37ce6:
	dw PewterMuseumGuyCoords
	dw PewterGymGuyCoords

; 『ニビ科学博物館』の連行イベントのイベントマスとそれに対応する初期位置へのmovement dataのテーブル  
; 初期位置は pewter guy の1マス上  
PewterMuseumGuyCoords:
	db 18, 27
	dw .down
	db 16, 27
	dw .up
	db 17, 26
	dw .left
	db 17, 28
	dw .right

.down	; 主人公が museum guyの下から話しかけた時
	db D_UP, D_UP, $ff
.up		; 主人公が museum guyの上から話しかけた時
	db D_RIGHT, D_LEFT, $ff	; 左にどいて右に戻る
.left
	db D_UP, D_RIGHT, $ff
.right
	db D_UP, D_LEFT, $ff

; ニビジムの連行イベントのイベントマスとそれに対応する初期位置へのmovement dataのテーブル  
; 初期位置は看板の右上
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

.one 	; 主人公が gym guyの1マス左(←)
	db D_LEFT, D_DOWN, D_DOWN, D_RIGHT, $ff	; → ↓ ↓ ←
.two	; 主人公が gym guyの1マス下(↓)
	db D_LEFT, D_DOWN, D_RIGHT, D_LEFT, $ff	; ← → ↓ ↓
.three	; 主人公が gym guyの右下(↘︎)
	db D_LEFT, D_LEFT, D_LEFT, $00, $00, $00, $00, $00, $00, $00, $00, $ff ; . . . . . . . . ← ← ← (. = $00 はその場で止まる)
.four	; 主人公が gym guyの2マス右、1マス下(→→↓)
	db D_LEFT, D_LEFT, D_UP, D_LEFT, $ff ; ← ↑ ← ←
.five	; 主人公が gym guyの2マス下(↓↓)
	db D_LEFT, D_DOWN, D_LEFT, $00, $00, $00, $00, $00, $00, $00, $00, $ff ; . . . . . . . . ← ↓ ←
