; **LoadSAV**  
; セーブデータを SRAM から WRAM にロードする処理
; - - -  
; まず SRAM のデータのチェックサムをとって、データが破損していないかチェック  
; 破損していなかったら、WRAM にロードしていく
; 
; OUTPUT:  
; [wSaveFileStatus] = ロード成功(2) or ロード失敗(1) 
LoadSAV:
	call ClearScreen
	call LoadFontTilePatterns
	call LoadTextBoxTilePatterns
	
	; セーブデータをロード
	; 失敗したときはキャリーが立っているので -> .badsum
	call LoadSAV0
	jr c, .badsum

	; いらない処理?
	; 失敗したときはキャリーが立っているので -> .badsum
	call LoadSAV1
	jr c, .badsum

	; 手持ちやポケモン図鑑のセーブデータをロード
	; 失敗したときはキャリーが立っているので -> .badsum
	call LoadSAV2
	jr c, .badsum
	
	ld a, $2 ; [wSaveFileStatus] = 2
	jr .goodsum

.badsum
	; "The file data is destroyed!"
	ld hl, wd730
	push hl
	set 6, [hl] ; テキストに遅延
	ld hl, FileDataDestroyedText
	call PrintText

	ld c, 100
	call DelayFrames
	pop hl
	res 6, [hl]	; 遅延状態を戻す

	ld a, $1 ; [wSaveFileStatus] = 1

.goodsum
	ld [wSaveFileStatus], a
	ret

; "The file data is  
; "destroyed!"
FileDataDestroyedText:
	TX_FAR _FileDataDestroyedText
	db "@"

LoadSAV0:
	; SRAMを有効化
	ld a, SRAM_ENABLE
	ld [MBC1SRamEnable], a
	; SRAMをバンク1にスイッチ
	ld a, $1
	ld [MBC1SRamBankingMode], a
	ld [MBC1SRamBank], a

	; 保存していたチェックサムとセーブデータから再度導いたチェックサムが一致する -> .checkSumsMatched
	ld hl, sPlayerName ; hl = 主人公の名前
	ld bc, sMainDataCheckSum - sPlayerName ; but here checks the full SAV
	call SAVCheckSum
	ld c, a
	ld a, [sMainDataCheckSum] ; SAV's checksum
	cp c
	jp z, .checkSumsMatched

	; チェックサムが一致しなかったときはもう一度検証する
	; これで一致しなかったら SAVBadCheckSumへ
	ld hl, sPlayerName
	ld bc, sMainDataCheckSum - sPlayerName
	call SAVCheckSum
	ld c, a
	ld a, [sMainDataCheckSum] ; SAV's checksum
	cp c
	jp nz, SAVBadCheckSum ; キャリーを立てて return

; チェックサムが一致したとき  
; SRAM に保存されたセーブデータを WRAMなどにコピーしていく  
.checkSumsMatched
	; wPlayerName に プレイヤー名をコピー
	ld hl, sPlayerName
	ld de, wPlayerName
	ld bc, NAME_LENGTH
	call CopyData
	
	; 保存したゲームデータを WRAMにコピー
	ld hl, sMainData
	ld de, wMainDataStart
	ld bc, wMainDataEnd - wMainDataStart
	call CopyData

	; ???
	ld hl, wCurMapTileset
	set 7, [hl]

	; OAM を WRAMにコピー
	ld hl, sSpriteData
	ld de, wSpriteDataStart
	ld bc, wSpriteDataEnd - wSpriteDataStart
	call CopyData

	; tilesetのtypeをコピー
	ld a, [sTilesetType]
	ld [hTilesetType], a

	; ボックスのポケモンデータをコピー
	ld hl, sCurBoxData
	ld de, wBoxDataStart
	ld bc, wBoxDataEnd - wBoxDataStart
	call CopyData

	; キャリーをクリアして SAVGoodChecksum
	and a ; CopyData終了時点で a = 0
	jp SAVGoodChecksum

; チェックサムの確認を 1度だけ行い、一致したら ボックスのポケモンデータをコピー(LoadSAV0でもやっているため無駄？)
LoadSAV1:
	ld a, SRAM_ENABLE
	ld [MBC1SRamEnable], a
	ld a, $1
	ld [MBC1SRamBankingMode], a
	ld [MBC1SRamBank], a
	ld hl, sPlayerName ; hero name located in SRAM
	ld bc, sMainDataCheckSum - sPlayerName  ; but here checks the full SAV
	call SAVCheckSum
	ld c, a
	ld a, [sMainDataCheckSum] ; SAV's checksum
	cp c
	jr nz, SAVBadCheckSum
	ld hl, sCurBoxData
	ld de, wBoxDataStart
	ld bc, wBoxDataEnd - wBoxDataStart
	call CopyData
	and a
	jp SAVGoodChecksum

LoadSAV2:
	; SRAM を有効化
	ld a, SRAM_ENABLE
	ld [MBC1SRamEnable], a

	; SRAMをバンク1にスイッチ
	ld a, $1
	ld [MBC1SRamBankingMode], a
	ld [MBC1SRamBank], a

	; チェックサムが一致するか確認　一致しない -> SAVBadCheckSum
	ld hl, sPlayerName ; hero name located in SRAM
	ld bc, sMainDataCheckSum - sPlayerName  ; but here checks the full SAV
	call SAVCheckSum
	ld c, a
	ld a, [sMainDataCheckSum] ; SAV's checksum
	cp c
	jp nz, SAVBadCheckSum

	; チェックサムが一致したとき

	; 手持ちのポケモンのデータをコピー
	ld hl, sPartyData
	ld de, wPartyDataStart
	ld bc, wPartyDataEnd - wPartyDataStart
	call CopyData

	; ポケモン図鑑のデータをコピー
	ld hl, sMainData
	ld de, wPokedexOwned
	ld bc, wPokedexSeenEnd - wPokedexOwned
	call CopyData

	; キャリーをクリアして return
	and a
	jp SAVGoodChecksum ; return

; キャリーを立てて SRAMのバンク番号を 0に戻して return
SAVBadCheckSum:
	scf

; SRAMのバンク番号を 0に戻して return
SAVGoodChecksum:
	ld a, $0
	ld [MBC1SRamBankingMode], a
	ld [MBC1SRamEnable], a
	ret

; 未使用  
; チェックサムが壊れていても強引にセーブデータをロードする  
LoadSAVIgnoreBadCheckSum:
	call LoadSAV0
	call LoadSAV1
	jp LoadSAV2

SaveSAV:
	callba PrintSaveScreenText

	; "Would you like to SAVE the game?" という確認のテキストを描画して、 Yes/Noメニューを描画
	ld hl, WouldYouLikeToSaveText
	call SaveSAVConfirm

	; Noなら終了
	and a   ;|0 = Yes|1 = No|
	ret nz

	; 既存のセーブデータが存在しない or 破損している場合はすぐにセーブ処理に移行
	ld a, [wSaveFileStatus]
	dec a
	jr z, .save

	; すでにセーブデータが存在している場合は　上書きしていいかの Yes/Noメニュー
	call SAVCheckRandomID
	jr z, .save
	ld hl, OlderFileWillBeErasedText	; "The older file will be erased to save. Okay?"
	call SaveSAVConfirm
	and a
	ret nz ; Noなら終了

	; Yes を押したとき セーブ処理を行う
.save
	call SaveSAVtoSRAM ; ここでセーブを行っている

	; 下のテキストボックスをクリア
	coord hl, 1, 13
	lb bc, 4, 18 				; 18(width) 4(height) 
	call ClearScreenArea

	; "Now saving...@"
	coord hl, 1, 14
	ld de, NowSavingString
	call PlaceString

	; "Now saving...@" と表示して2秒待機
	ld c, 120
	call DelayFrames

	; "<PLAYER> saved the game!"
	ld hl, GameSavedText
	call PrintText

	; セーブ完了のサウンドを鳴らして終了
	ld a, SFX_SAVE
	call PlaySoundWaitForCurrent
	call WaitForSoundToFinish
	ld c, 30
	jp DelayFrames	; return

NowSavingString:
	db "Now saving...@"

; "Would you like to SAVE the game?" という確認のテキストを描画して、 Yes/Noメニューをだし結果を Aレジスタに入れて返す  
; OUTPUT:  a = 0(Yes) or 1(No)
SaveSAVConfirm:
	; "Would you like to SAVE the game?"
	call PrintText

	; yes/no menu
	coord hl, 0, 7
	lb bc, 8, 1
	ld a, TWO_OPTION_MENU
	ld [wTextBoxID], a
	call DisplayTextBoxID 

	ld a, [wCurrentMenuItem]
	ret

; "Would you like to SAVE the game?"
WouldYouLikeToSaveText:
	TX_FAR _WouldYouLikeToSaveText
	db "@"

; "<PLAYER> saved the game!"
GameSavedText:
	TX_FAR _GameSavedText
	db "@"

; "The older file will be erased to save. Okay?"
OlderFileWillBeErasedText:
	TX_FAR _OlderFileWillBeErasedText
	db "@"

; WRAMに格納されているゲームの進行データを SRAMにコピーしていくことでセーブを行う
SaveSAVtoSRAM0:
	; SRAM を有効化
	ld a, SRAM_ENABLE
	ld [MBC1SRamEnable], a

	; SRAMをバンク1にスイッチ
	ld a, $1
	ld [MBC1SRamBankingMode], a
	ld [MBC1SRamBank], a
	
	; 名前を WRAM -> SRAM
	ld hl, wPlayerName
	ld de, sPlayerName
	ld bc, NAME_LENGTH
	call CopyData

	; セーブデータを WRAM -> SRAM
	ld hl, wMainDataStart
	ld de, sMainData
	ld bc, wMainDataEnd - wMainDataStart
	call CopyData

	; OAMデータを WRAM -> SRAM
	ld hl, wSpriteDataStart
	ld de, sSpriteData
	ld bc, wSpriteDataEnd - wSpriteDataStart
	call CopyData

	; ボックスのポケモンデータを WRAM -> SRAM
	ld hl, wBoxDataStart
	ld de, sCurBoxData
	ld bc, wBoxDataEnd - wBoxDataStart
	call CopyData

	; tilesetのtypeを WRAM -> SRAM
	ld a, [hTilesetType]
	ld [sTilesetType], a

	; チェックサムを計算して SRAM に保存(ロード時のチェックに使う)
	ld hl, sPlayerName
	ld bc, sMainDataCheckSum - sPlayerName
	call SAVCheckSum
	ld [sMainDataCheckSum], a

	; SRAM を バンク0に戻す
	xor a
	ld [MBC1SRamBankingMode], a
	ld [MBC1SRamEnable], a
	ret

; SaveSAVtoSRAM0 と処理が完全にかぶっている
; 無駄なコード?
SaveSAVtoSRAM1:
	; SRAM を有効化
	ld a, SRAM_ENABLE
	ld [MBC1SRamEnable], a

	; SRAMをバンク1にスイッチ
	ld a, $1
	ld [MBC1SRamBankingMode], a
	ld [MBC1SRamBank], a

	; ボックスのポケモンデータをコピー
	ld hl, wBoxDataStart
	ld de, sCurBoxData
	ld bc, wBoxDataEnd - wBoxDataStart
	call CopyData
	ld hl, sPlayerName
	ld bc, sMainDataCheckSum - sPlayerName
	call SAVCheckSum
	ld [sMainDataCheckSum], a
	xor a
	ld [MBC1SRamBankingMode], a
	ld [MBC1SRamEnable], a
	ret

SaveSAVtoSRAM2:
	; SRAM を有効化
	ld a, SRAM_ENABLE
	ld [MBC1SRamEnable], a

	; SRAMをバンク1にスイッチ
	ld a, $1
	ld [MBC1SRamBankingMode], a
	ld [MBC1SRamBank], a

	; 手持ちのポケモンのデータをコピー
	ld hl, wPartyDataStart
	ld de, sPartyData
	ld bc, wPartyDataEnd - wPartyDataStart
	call CopyData

	; ポケモン図鑑のデータをコピー
	ld hl, wPokedexOwned ; pokÃ©dex only
	ld de, sMainData
	ld bc, wPokedexSeenEnd - wPokedexOwned
	call CopyData

	; チェックサムを計算して SRAM に保存(ロード時のチェックに使う)
	ld hl, sPlayerName
	ld bc, sMainDataCheckSum - sPlayerName
	call SAVCheckSum
	ld [sMainDataCheckSum], a
	
	; SRAM を バンク0に戻す
	xor a
	ld [MBC1SRamBankingMode], a
	ld [MBC1SRamEnable], a
	ret

; **SaveSAVtoSRAM**  
; 実際のセーブ処理を行う関数  
; - - -  
; WRAM のゲーム進行状況を SRAM にコピー(保存)する  
; チェックサムも計算して保存しておく  
SaveSAVtoSRAM:
	ld a, $2
	ld [wSaveFileStatus], a
	call SaveSAVtoSRAM0
	call SaveSAVtoSRAM1
	jp SaveSAVtoSRAM2

; セーブデータのチェックサム(1 byte)を計算 Aレジスタに入れて返す
SAVCheckSum:
	ld d, 0
.loop
	ld a, [hli]
	add d
	ld d, a
	dec bc
	ld a, b
	or c
	jr nz, .loop
	ld a, d
	cpl
	ret

CalcIndividualBoxCheckSums:
	ld hl, sBox1 ; sBox7
	ld de, sBank2IndividualBoxChecksums ; sBank3IndividualBoxChecksums
	ld b, NUM_BOXES / 2
.loop
	push bc
	push de
	ld bc, wBoxDataEnd - wBoxDataStart
	call SAVCheckSum
	pop de
	ld [de], a
	inc de
	pop bc
	dec b
	jr nz, .loop
	ret

GetBoxSRAMLocation:
; in: a = box num
; out: b = box SRAM bank, hl = pointer to start of box
	ld hl, BoxSRAMPointerTable
	ld a, [wCurrentBoxNum]
	and $7f
	cp NUM_BOXES / 2
	ld b, 2
	jr c, .next
	inc b
	sub NUM_BOXES / 2
.next
	ld e, a
	ld d, 0
	add hl, de
	add hl, de
	inline "hl = [hl]"
	ret

BoxSRAMPointerTable:
	dw sBox1 ; sBox7
	dw sBox2 ; sBox8
	dw sBox3 ; sBox9
	dw sBox4 ; sBox10
	dw sBox5 ; sBox11
	dw sBox6 ; sBox12

ChangeBox::
	ld hl, WhenYouChangeBoxText
	call PrintText
	call YesNoChoice
	ld a, [wCurrentMenuItem]
	and a
	ret nz ; return if No was chosen
	ld hl, wCurrentBoxNum
	bit 7, [hl] ; is it the first time player is changing the box?
	call z, EmptyAllSRAMBoxes ; if so, empty all boxes in SRAM
	call DisplayChangeBoxMenu
	call UpdateSprites
	ld hl, hFlags_0xFFF6
	set 1, [hl]
	call HandleMenuInput
	ld hl, hFlags_0xFFF6
	res 1, [hl]
	bit 1, a ; pressed b
	ret nz
	call GetBoxSRAMLocation
	ld e, l
	ld d, h
	ld hl, wBoxDataStart
	call CopyBoxToOrFromSRAM ; copy old box from WRAM to SRAM
	ld a, [wCurrentMenuItem]
	set 7, a
	ld [wCurrentBoxNum], a
	call GetBoxSRAMLocation
	ld de, wBoxDataStart
	call CopyBoxToOrFromSRAM ; copy new box from SRAM to WRAM
	ld hl, wMapTextPtr
	ld de, wChangeBoxSavedMapTextPointer
	inline "[de++] = [hl++]"
	ld a, [hl]
	ld [de], a
	call RestoreMapTextPointer
	call SaveSAVtoSRAM
	ld hl, wChangeBoxSavedMapTextPointer
	call SetMapTextPointer
	ld a, SFX_SAVE
	call PlaySoundWaitForCurrent
	call WaitForSoundToFinish
	ret

WhenYouChangeBoxText:
	TX_FAR _WhenYouChangeBoxText
	db "@"

CopyBoxToOrFromSRAM:
; copy an entire box from hl to de with b as the SRAM bank
	push hl
	ld a, SRAM_ENABLE
	ld [MBC1SRamEnable], a
	ld a, $1
	ld [MBC1SRamBankingMode], a
	ld a, b
	ld [MBC1SRamBank], a
	ld bc, wBoxDataEnd - wBoxDataStart
	call CopyData
	pop hl

; mark the memory that the box was copied from as am empty box
	xor a
	ld [hli], a
	dec a
	ld [hl], a

	ld hl, sBox1 ; sBox7
	ld bc, sBank2AllBoxesChecksum - sBox1
	call SAVCheckSum
	ld [sBank2AllBoxesChecksum], a ; sBank3AllBoxesChecksum
	call CalcIndividualBoxCheckSums
	xor a
	ld [MBC1SRamBankingMode], a
	ld [MBC1SRamEnable], a
	ret

DisplayChangeBoxMenu:
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a
	ld a, A_BUTTON | B_BUTTON
	ld [wMenuWatchedKeys], a
	ld a, 11
	ld [wMaxMenuItem], a
	ld a, 1
	ld [wTopMenuItemY], a
	ld a, 12
	ld [wTopMenuItemX], a
	xor a
	ld [wMenuWatchMovingOutOfBounds], a
	ld a, [wCurrentBoxNum]
	and $7f
	ld [wCurrentMenuItem], a
	ld [wLastMenuItem], a
	coord hl, 0, 0
	ld b, 2
	ld c, 9
	call TextBoxBorder
	ld hl, ChooseABoxText
	call PrintText
	coord hl, 11, 0
	ld b, 12
	ld c, 7
	call TextBoxBorder
	ld hl, hFlags_0xFFF6
	set 2, [hl]
	ld de, BoxNames
	coord hl, 13, 1
	call PlaceString
	ld hl, hFlags_0xFFF6
	res 2, [hl]
	ld a, [wCurrentBoxNum]
	and $7f
	cp 9
	jr c, .singleDigitBoxNum
	sub 9
	coord hl, 8, 2
	ld [hl], "1"
	add "0"
	jr .next
.singleDigitBoxNum
	add "1"
.next
	Coorda 9, 2
	coord hl, 1, 2
	ld de, BoxNoText
	call PlaceString
	call GetMonCountsForAllBoxes
	coord hl, 18, 1
	ld de, wBoxMonCounts
	ld bc, SCREEN_WIDTH
	ld a, $c
.loop
	push af
	ld a, [de]
	and a ; is the box empty?
	jr z, .skipPlacingPokeball
	ld [hl], $78 ; place pokeball tile next to box name if box not empty
.skipPlacingPokeball
	add hl, bc
	inc de
	pop af
	dec a
	jr nz, .loop
	ld a, 1
	ld [H_AUTOBGTRANSFERENABLED], a
	ret

ChooseABoxText:
	TX_FAR _ChooseABoxText
	db "@"

BoxNames:
	db   "BOX 1"
	next "BOX 2"
	next "BOX 3"
	next "BOX 4"
	next "BOX 5"
	next "BOX 6"
	next "BOX 7"
	next "BOX 8"
	next "BOX 9"
	next "BOX10"
	next "BOX11"
	next "BOX12@"

BoxNoText:
	db "BOX No.@"

EmptyAllSRAMBoxes:
; marks all boxes in SRAM as empty (initialisation for the first time the
; player changes the box)
	ld a, SRAM_ENABLE
	ld [MBC1SRamEnable], a
	ld a, $1
	ld [MBC1SRamBankingMode], a
	ld a, 2
	ld [MBC1SRamBank], a
	call EmptySRAMBoxesInBank
	ld a, 3
	ld [MBC1SRamBank], a
	call EmptySRAMBoxesInBank
	xor a
	ld [MBC1SRamBankingMode], a
	ld [MBC1SRamEnable], a
	ret

EmptySRAMBoxesInBank:
; marks every box in the current SRAM bank as empty
	ld hl, sBox1 ; sBox7
	call EmptySRAMBox
	ld hl, sBox2 ; sBox8
	call EmptySRAMBox
	ld hl, sBox3 ; sBox9
	call EmptySRAMBox
	ld hl, sBox4 ; sBox10
	call EmptySRAMBox
	ld hl, sBox5 ; sBox11
	call EmptySRAMBox
	ld hl, sBox6 ; sBox12
	call EmptySRAMBox
	ld hl, sBox1 ; sBox7
	ld bc, sBank2AllBoxesChecksum - sBox1
	call SAVCheckSum
	ld [sBank2AllBoxesChecksum], a ; sBank3AllBoxesChecksum
	call CalcIndividualBoxCheckSums
	ret

EmptySRAMBox:
	xor a
	ld [hli], a
	dec a
	ld [hl], a
	ret

GetMonCountsForAllBoxes:
	ld hl, wBoxMonCounts
	push hl
	ld a, SRAM_ENABLE
	ld [MBC1SRamEnable], a
	ld a, $1
	ld [MBC1SRamBankingMode], a
	ld a, $2
	ld [MBC1SRamBank], a
	call GetMonCountsForBoxesInBank
	ld a, $3
	ld [MBC1SRamBank], a
	call GetMonCountsForBoxesInBank
	xor a
	ld [MBC1SRamBankingMode], a
	ld [MBC1SRamEnable], a
	pop hl

; copy the count for the current box from WRAM
	ld a, [wCurrentBoxNum]
	and $7f
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [wNumInBox]
	ld [hl], a

	ret

GetMonCountsForBoxesInBank:
	ld a, [sBox1] ; sBox7
	ld [hli], a
	ld a, [sBox2] ; sBox8
	ld [hli], a
	ld a, [sBox3] ; sBox9
	ld [hli], a
	ld a, [sBox4] ; sBox10
	ld [hli], a
	ld a, [sBox5] ; sBox11
	ld [hli], a
	ld a, [sBox6] ; sBox12
	ld [hli], a
	ret

SAVCheckRandomID:
;checks if Sav file is the same by checking player's name 1st letter ($a598)
; and the two random numbers generated at game beginning
;(which are stored at wPlayerID)s
	ld a, $0a
	ld [MBC1SRamEnable], a
	ld a, $01
	ld [MBC1SRamBankingMode], a
	ld [MBC1SRamBank], a
	ld a, [sPlayerName]
	and a
	jr z, .next
	ld hl, sPlayerName
	ld bc, sMainDataCheckSum - sPlayerName
	call SAVCheckSum
	ld c, a
	ld a, [sMainDataCheckSum]
	cp c
	jr nz, .next
	ld hl, sMainData + (wPlayerID - wMainDataStart) ; player ID
	inline "hl = [hl]"
	ld a, [wPlayerID]
	cp l
	jr nz, .next
	ld a, [wPlayerID + 1]
	cp h
.next
	ld a, $00
	ld [MBC1SRamBankingMode], a
	ld [MBC1SRamEnable], a
	ret

SaveHallOfFameTeams:
	ld a, [wNumHoFTeams]
	dec a
	cp HOF_TEAM_CAPACITY
	jr nc, .shiftHOFTeams
	ld hl, sHallOfFame
	ld bc, HOF_TEAM
	call AddNTimes
	ld e, l
	ld d, h
	ld hl, wHallOfFame
	ld bc, HOF_TEAM
	jr HallOfFame_Copy

.shiftHOFTeams
; if the space designated for HOF teams is full, then shift all HOF teams to the next slot, making space for the new HOF team
; this deletes the last HOF team though
	ld hl, sHallOfFame + HOF_TEAM
	ld de, sHallOfFame
	ld bc, HOF_TEAM * (HOF_TEAM_CAPACITY - 1)
	call HallOfFame_Copy
	ld hl, wHallOfFame
	ld de, sHallOfFame + HOF_TEAM * (HOF_TEAM_CAPACITY - 1)
	ld bc, HOF_TEAM
	jr HallOfFame_Copy

; **LoadHallOfFameTeams**  
; [wHoFTeamIndex]回目の殿堂入りデータを wHallOfFame にロード
; - - -  
LoadHallOfFameTeams:
	; hl = sHallOfFame[wHoFTeamIndex]
	ld hl, sHallOfFame
	ld bc, HOF_TEAM
	ld a, [wHoFTeamIndex]
	call AddNTimes

	; CopyData の変数
	ld de, wHallOfFame
	ld bc, HOF_TEAM
	; fallthrough

HallOfFame_Copy:
	; SRAM を有効化
	ld a, SRAM_ENABLE
	ld [MBC1SRamEnable], a

	; SRAMをバンク0にスイッチ
	ld a, $1
	ld [MBC1SRamBankingMode], a
	xor a
	ld [MBC1SRamBank], a

	call CopyData

	; SRAM を戻す
	xor a
	ld [MBC1SRamBankingMode], a
	ld [MBC1SRamEnable], a
	ret

ClearSAV:
	ld a, SRAM_ENABLE
	ld [MBC1SRamEnable], a
	ld a, $1
	ld [MBC1SRamBankingMode], a
	xor a
	call PadSRAM_FF
	ld a, $1
	call PadSRAM_FF
	ld a, $2
	call PadSRAM_FF
	ld a, $3
	call PadSRAM_FF
	xor a
	ld [MBC1SRamBankingMode], a
	ld [MBC1SRamEnable], a
	ret

PadSRAM_FF:
	ld [MBC1SRamBank], a
	ld hl, $a000
	ld bc, $2000
	ld a, $ff
	jp FillMemory
