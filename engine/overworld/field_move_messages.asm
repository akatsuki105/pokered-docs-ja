; CanMoveBouldersText を表示する
PrintStrengthTxt:
	ld hl, wd728
	set 0, [hl]
	ld hl, UsedStrengthText
	call PrintText
	ld hl, CanMoveBouldersText
	jp PrintText

; 『かいりき』を使った時のテキストスクリプト
UsedStrengthText:
	TX_FAR _UsedStrengthText
	TX_ASM
	ld a, [wcf91]
	call PlayCry
	call Delay3
	jp TextScriptEnd

; 『${pokemon} can move boulders.』
CanMoveBouldersText:
	TX_FAR _CanMoveBouldersText
	db "@"

; **IsSurfingAllowed**  
; 『なみのり』ができる状態かを判定するフラグをwd728[1]にセットして返す  
; - - - 
; 『なみのり』ができない状態とはサイクリングロードや、潮流が岩でせき止められてゆっくりになる前のふたごじまのことを指す
IsSurfingAllowed:
	; wd728[1] = 1
	ld hl, wd728
	set 1, [hl]

	; サイクリングロード -> .forcedToRideBike
	ld a, [wd732]
	bit 5, a
	jr nz, .forcedToRideBike

	; ふたごじまでないなら波乗りはOK
	ld a, [wCurMap]
	cp SEAFOAM_ISLANDS_B4F
	ret nz

	; 潮流がせき止められているならOK
	CheckBothEventsSet EVENT_SEAFOAM4_BOULDER1_DOWN_HOLE, EVENT_SEAFOAM4_BOULDER2_DOWN_HOLE
	ret z
	
	; 潮流が急だとしても、急なところに向かって波乗りしようとしていないならOK
	ld hl, CoordsData_cdf7
	call ArePlayerCoordsInArray
	ret nc

	; 潮流が急なので波乗りできない
	ld hl, wd728
	res 1, [hl]
	ld hl, CurrentTooFastText
	jp PrintText
	
	; サイクリングロードのときは波乗りできない
.forcedToRideBike
	; wd728[1] = 0
	ld hl, wd728
	res 1, [hl]
	ld hl, CyclingIsFunText
	jp PrintText

CoordsData_cdf7:
	db $0B,$07,$FF

; "The current is much too fast!"
CurrentTooFastText:
	TX_FAR _CurrentTooFastText
	db "@"

; "Cycling is fun! Forget SURFing!"
CyclingIsFunText:
	TX_FAR _CyclingIsFunText
	db "@"
