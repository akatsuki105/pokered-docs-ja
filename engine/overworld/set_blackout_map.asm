; **SetLastBlackoutMap**  
; 目の前が真っ暗になったり、『あなをほる』や『テレポート』で戻る先のマップを登録する処理  
; - - -  
; [wLastBlackoutMap] に　現在のマップID を入れることで登録処理を行う  
; サファリゾーンの建物は、戻り先として登録しない  
SetLastBlackoutMap:
	push hl

	ld hl, SafariZoneRestHouses
	ld a, [wCurMap]
	ld b, a

; [wCurMap] が SafariZoneRestHousesのどれかに該当するかみていく
.loop
; {
	ld a, [hli]

	cp -1
	jr z, .notresthouse

	cp b
	jr nz, .loop
; }

	; 該当するものがあった
	jr .done

.notresthouse
	; 該当するものがなかった  
	; [wLastBlackoutMap] = [wLastMap]
	ld a, [wLastMap]
	ld [wLastBlackoutMap], a

.done
	pop hl
	ret

SafariZoneRestHouses:
	db SAFARI_ZONE_WEST_REST_HOUSE
	db SAFARI_ZONE_EAST_REST_HOUSE
	db SAFARI_ZONE_NORTH_REST_HOUSE
	db -1
