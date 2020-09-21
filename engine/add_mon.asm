; **_AddPartyMon**  
; 新しいポケモンを主人公かライバルの手持ちに加える  
; - - -  
; この関数では [wMonDataLocation] が通常とは異なる使われ方をすることに注意  
; 
; INPUT:  
; [wcf91] = 加える対象のポケモンID  
; 
; OUTPUT:  
; carry = 手持ちに加えることに成功したときにセットされる  
; wPartyMons(wEnemyMons) = 加えたポケモンのデータがセットされる  
_AddPartyMon:
	; de = wPartyCount(下位ニブルが0) or wEnemyPartyCount(0以外)
	ld de, wPartyCount
	ld a, [wMonDataLocation]
	and $f
	jr z, .next
	ld de, wEnemyPartyCount
.next
	; a = 加える前の手持ち数 + 1
	ld a, [de]
	inc a
	
	; 手持ちがいっぱいなら return
	cp PARTY_LENGTH + 1
	ret nc
	
	; 手持ちのポケモン数を1増やす
	ld [de], a
	ld a, [de]
	ld [hNewPartyLength], a
	
	; de = 新しいポケモン用の wPartySpecies のスロット(wPartyCountはlistの長さでもあることに注意)
	add e
	ld e, a
	jr nc, .noCarry
	inc d
.noCarry

	; wPartySpecies に新しいポケモンの内部IDをセット
	ld a, [wcf91]
	ld [de], a
	inc de
	ld a, $ff ; terminator
	ld [de], a

	; hl = wPartyMonOT or wEnemyMonOT
	ld hl, wPartyMonOT
	ld a, [wMonDataLocation]
	and $f
	jr z, .next2
	ld hl, wEnemyMonOT
.next2

	; wPartyMonOT(wEnemyMonOT)の新しいスロットに追加するポケモンの名前を格納
	ld a, [hNewPartyLength]
	dec a
	call SkipFixedLengthTextEntries
	ld d, h
	ld e, l
	ld hl, wPlayerName
	ld bc, NAME_LENGTH
	call CopyData

	; [wMonDataLocation]が 0 でないなら ニックネームは変更不可能
	ld a, [wMonDataLocation]
	and a
	jr nz, .skipNaming

	; ポケモンのニックネームを設定
	ld hl, wPartyMonNicks
	ld a, [hNewPartyLength]
	dec a
	call SkipFixedLengthTextEntries ; hl = wPartyMonNicksの新しいスロット
	ld a, NAME_MON_SCREEN
	ld [wNamingScreenType], a		; [wNamingScreenType] =  NAME_MON_SCREEN
	predef AskName

	; hl = wPartyMons or wEnemyMons
.skipNaming
	ld hl, wPartyMons
	ld a, [wMonDataLocation]
	and $f
	jr z, .next3
	ld hl, wEnemyMons

.next3
	; de = hl = wPartyMons(wEnemyMons)の新しいスロット
	ld a, [hNewPartyLength]
	dec a
	ld bc, wPartyMon2 - wPartyMon1
	call AddNTimes
	ld e, l
	ld d, h

	push hl

	ld a, [wcf91]
	ld [wd0b5], a
	call GetMonHeader
	ld hl, wMonHeader
	ld a, [hli]
	ld [de], a 	; wPartyMons に図鑑番号を格納
	inc de		; de = wPartyMons の HP数値 のアドレス

	pop hl
	push hl

	; ライバルの手持ちに加わるときは、個体値は平均値に固定され .next4へ
	ld a, [wMonDataLocation]
	and $f
	ld a, $98
	ld b, $88
	jr nz, .next4

	; ポケモンがプレイヤーの手持ちに加わる場合はポケモン図鑑を更新
	
	; a = [wd11e] = 図鑑番号
	ld a, [wcf91]
	ld [wd11e], a
	push de
	predef IndexToPokedex
	pop de
	ld a, [wd11e]

	; [wUnusedD153] = ポケモンをすでに捕まえているか (1なら捕まえてる)
	; 特に意味のないコードの模様
	dec a
	ld c, a
	ld b, FLAG_TEST
	ld hl, wPokedexOwned
	call FlagAction
	ld a, c ; whether the mon was already flagged as owned
	ld [wUnusedD153], a ; not read

	; ポケモンを 捕まえた & 見た フラグを立てる
	ld a, [wd11e]
	dec a
	ld c, a
	ld b, FLAG_SET
	push bc
	call FlagAction
	pop bc
	ld hl, wPokedexSeen
	call FlagAction

	pop hl
	push hl

	; 個体値の計算 (野生の場合) -> 野生のポケモンの個体値をコピーするために .copyEnemyMonData
	jrIfInBattle .copyEnemyMonData
	; 個体値の計算 (野生でない場合) -> ランダムに決定
	call Random
	ld b, a
	call Random

.next4
	; 個体値を書き込む
	push bc
	ld bc, wPartyMon1DVs - wPartyMon1
	add hl, bc	; hl = 新しいポケモンのwPartyMon1DVsのアドレス
	pop bc
	ld [hli], a
	ld [hl], b	; 決定した個体値(a, b)を書き込む

	; 新しいポケモンの HP を計算
	ld bc, (wPartyMon1HPExp - 1) - (wPartyMon1DVs + 1)
	add hl, bc
	ld a, 1
	ld c, a
	xor a
	ld b, a
	call CalcStat      ; calc HP stat (set cur Hp to max HP)

	; de、つまり wPartyMon${N}HP に 計算したHPを書き込む
	ld a, [H_MULTIPLICAND+1]
	ld [de], a
	inc de
	ld a, [H_MULTIPLICAND+2]
	ld [de], a
	inc de

	; その他の値を初期化して .copyMonTypesAndMoves
	xor a
	ld [de], a         ; wPartyMon${N}BoxLevel = 0
	inc de
	ld [de], a         ; wPartyMon${N}Status = 0
	inc de
	jr .copyMonTypesAndMoves

; 野生のポケモンの場合、ここで捕まえたポケモンの個体値データをコピーしている
.copyEnemyMonData
	ld bc, wEnemyMon1DVs - wEnemyMon1
	add hl, bc
	ld a, [wEnemyMonDVs] ; copy IVs from cur enemy mon
	ld [hli], a
	ld a, [wEnemyMonDVs + 1]
	ld [hl], a
	ld a, [wEnemyMonHP]    ; copy HP from cur enemy mon
	ld [de], a
	inc de
	ld a, [wEnemyMonHP+1]
	ld [de], a
	inc de
	xor a
	ld [de], a                ; box level
	inc de
	ld a, [wEnemyMonStatus]   ; copy status ailments from cur enemy mon
	ld [de], a
	inc de

.copyMonTypesAndMoves
	ld hl, wMonHTypes	; GetMonHeader で取得している 

	; wPartyMon${N}Type1 = wMonHTypes のタイプ1
	ld a, [hli]       ; type 1
	ld [de], a
	inc de
	; wPartyMon${N}Type2 = wMonHTypes のタイプ2
	ld a, [hli]       ; type 2
	ld [de], a
	inc de
	
	; wPartyMon${N}CatchRate
	ld a, [hli]       ; catch rate (held item in gen 2)
	ld [de], a

	ld hl, wMonHMoves
	ld a, [hli] ; a = 技数

	inc de		; de = wPartyMon${N}Moves
	push de

	; Move1
	ld [de], a

	; Move2
	ld a, [hli]
	inc de
	ld [de], a

	; Move3
	ld a, [hli]
	inc de
	ld [de], a

	; Move4
	ld a, [hli]
	inc de
	ld [de], a
	
	push de	; このとき de = wPartyMon${N}Moves + 3 = 4つめの技アドレス
	dec de
	dec de
	dec de
	xor a
	ld [wLearningMovesFromDayCare], a
	predef WriteMonMoves
	pop de

	; この時点で de = wPartyMon${N}Moves + 3 = 4つめの技アドレス

	; wPartyMon${N}OTID (2バイト)
	ld a, [wPlayerID]  ; set trainer ID to player ID
	inc de
	ld [de], a
	ld a, [wPlayerID + 1]
	inc de
	ld [de], a

	; 経験値量を計算
	push de
	ld a, [wCurEnemyLVL]
	ld d, a
	callab CalcExperience
	pop de
	
	; CalcExperience で計算された Exp([hExperience])を書き込む
	; wPartyMon${N}Exp (3バイト)
	inc de
	ld a, [hExperience] ; write experience
	ld [de], a
	inc de
	ld a, [hExperience + 1]
	ld [de], a
	inc de
	ld a, [hExperience + 2]
	ld [de], a

; 努力値を全て 0クリアする  
; この時点で de = wPartyMon${N}HPExp-1
	xor a
	ld b, NUM_STATS * 2
.writeEVsLoop
	inc de
	ld [de], a
	dec b
	jr nz, .writeEVsLoop

	; wPartyMon${N}DVs をスキップ
	inc de
	inc de
	; この時点で de = wPartyMon${N}PP-1

	pop hl ; hl = wPartyMon${N}Moves
	
	call AddPartyMon_WriteMovePP
	; この時点で de = wPartyMon${N}Level -1

	; wPartyMon${N}Level
	inc de
	ld a, [wCurEnemyLVL]
	ld [de], a

	inc de
	
	; 野生のポケモンではない -> .calcFreshStats
	jrNotIfInWildBattle .calcFreshStats

	; 野生のポケモン -> ステータスはすでに計算されているのでそれをコピー
	ld hl, wEnemyMonMaxHP
	ld bc, $a
	call CopyData          ; copy stats of cur enemy mon
	pop hl
	jr .done

	; 野生のポケモンのではない -> 種族値、努力値、個体値からステータスを計算してセット
.calcFreshStats
	pop hl
	ld bc, wPartyMon1HPExp - 1 - wPartyMon1
	add hl, bc
	ld b, $0
	call CalcStats         ; calculate fresh set of stats

.done
	scf	; キャリーを立てる
	ret

; **LoadMovePPs**
; de で示したアドレス以降に hl で指定した技のIDリストのPPを書き込んでいく  
; - - -  
; PP最大値増加アイテムの影響はここでは無視  
; 
; INPUT:  
; de = この次のアドレスからPPを格納していく(e.g. (wPartyMon1PP)-1)  
; hl = ここから技のIDが続く (e.g. wPartyMon1Moves)  
LoadMovePPs:
	call GetPredefRegisters
	; 下に続く

; **AddPartyMon_WriteMovePP**  
; de で示したアドレス以降に hl で指定した技のIDリストのPPを書き込んでいく  
; - - -  
; PP最大値増加アイテムの影響はここでは無視  
; 
; INPUT:  
; de = この次のアドレスからPPを格納していく(e.g. (wPartyMon1PP)-1)  
; hl = ここから技のIDが続く (e.g. wPartyMon1Moves)  
AddPartyMon_WriteMovePP:
	ld b, NUM_MOVES
.pploop
	ld a, [hli]     ; a = MoveID
	
	; MoveID == 0 つまりそこの技スロットは空 -> .empty
	and a
	jr z, .empty

	; a = PP
	dec a
	push hl
	push de
	push bc
	ld hl, Moves
	ld bc, MoveEnd - Moves
	call AddNTimes	; hl = Moves[i] つまり 対象の技データ
	ld de, wcd6d
	ld a, BANK(Moves)
	call FarCopyData ; [wcd6d] = 技データ
	pop bc
	pop de
	pop hl
	ld a, [wcd6d + 5] ; a = PP(Move[5])
; PPスロットに書き込む
.empty
	inc de
	ld [de], a
	dec b
	jr nz, .pploop ; there are still moves to read
	ret

; ケーブルクラブで使われる関数なので無視  
; adds enemy mon [wcf91] (at position [wWhichPokemon] in enemy list) to own party
; used in the cable club trade center
_AddEnemyMonToPlayerParty:
	ld hl, wPartyCount
	ld a, [hl]
	cp PARTY_LENGTH
	scf
	ret z            ; party full, return failure
	inc a
	ld [hl], a       ; add 1 to party members
	ld c, a
	ld b, $0
	add hl, bc
	ld a, [wcf91]
	ld [hli], a      ; add mon as last list entry
	ld [hl], $ff     ; write new sentinel
	ld hl, wPartyMons
	ld a, [wPartyCount]
	dec a
	ld bc, wPartyMon2 - wPartyMon1
	call AddNTimes
	ld e, l
	ld d, h
	ld hl, wLoadedMon
	call CopyData    ; write new mon's data (from wLoadedMon)
	ld hl, wPartyMonOT
	ld a, [wPartyCount]
	dec a
	call SkipFixedLengthTextEntries
	ld d, h
	ld e, l
	ld hl, wEnemyMonOT
	ld a, [wWhichPokemon]
	call SkipFixedLengthTextEntries
	ld bc, NAME_LENGTH
	call CopyData    ; write new mon's OT name (from an enemy mon)
	ld hl, wPartyMonNicks
	ld a, [wPartyCount]
	dec a
	call SkipFixedLengthTextEntries
	ld d, h
	ld e, l
	ld hl, wEnemyMonNicks
	ld a, [wWhichPokemon]
	call SkipFixedLengthTextEntries
	ld bc, NAME_LENGTH
	call CopyData    ; write new mon's nickname (from an enemy mon)
	ld a, [wcf91]
	ld [wd11e], a
	predef IndexToPokedex
	ld a, [wd11e]
	dec a
	ld c, a
	ld b, FLAG_SET
	ld hl, wPokedexOwned
	push bc
	call FlagAction ; add to owned pokemon
	pop bc
	ld hl, wPokedexSeen
	call FlagAction ; add to seen pokemon
	and a
	ret                  ; return success

; **_MoveMon**  
; ポケモンを別のデータスロットに移動させる処理  
; - - -  
; 移動した後のデータクリアはここではしない  
; 
; INPUT: [wMoveMonType] = BOX_TO_PARTY or PARTY_TO_BOX or DAYCARE_TO_PARTY or PARTY_TO_DAYCARE (移動元と移動先)  
; OUTPUT: carry = 0(成功) or 1(移動先がいっぱいで失敗)  
_MoveMon:
	; [wMoveMonType] によって分岐
	ld a, [wMoveMonType]
	and a   ; BOX_TO_PARTY		; BOX_TO_PARTY -> .checkPartyMonSlots
	jr z, .checkPartyMonSlots
	cp DAYCARE_TO_PARTY			; DAYCARE_TO_PARTY -> .checkPartyMonSlots
	jr z, .checkPartyMonSlots
	cp PARTY_TO_DAYCARE			; PARTY_TO_DAYCARE -> .findMonDataSrc
	ld hl, wDayCareMon
	jr z, .findMonDataSrc
	; fallthrough				; PARTY_TO_BOX -> fallthrough

	; 移動先がPCボックスのとき、
	; PCボックスに空きがある -> .boxFull
	; PCボックスに空きがない -> .partyOrBoxNotFull
	ld hl, wNumInBox
	ld a, [hl]
	cp MONS_PER_BOX
	jr nz, .partyOrBoxNotFull
	jr .boxFull

.checkPartyMonSlots
	; 移動先が手持ちのとき、
	; 手持ちに空きがある -> .boxFull
	; 手持ちに空きがない -> .partyOrBoxNotFull
	ld hl, wPartyCount
	ld a, [hl]
	cp PARTY_LENGTH
	jr nz, .partyOrBoxNotFull

.boxFull
	; 移動先のデータスロットに空きスロットがないとき、キャリーを立てて return 
	scf
	ret

.partyOrBoxNotFull
	; 移動先に空きスロットがあるとき

	; wNumInBox または wPartyCount をインクリメント
	inc a
	ld [hl], a

	; hl = 移動先の wPartySpecies(wBoxSpecies) のエントリ
	ld c, a
	ld b, 0
	add hl, bc

	; a = 移動対象のポケモンID
	ld a, [wMoveMonType]
	cp DAYCARE_TO_PARTY
	ld a, [wDayCareMon]
	jr z, .copySpecies
	ld a, [wcf91]	; Pokemon ID

; ここでは ポケモンIDをコピー
.copySpecies
	; 移動先のポケモンIDスロット(wPartySpecies or wBoxSpecies) にポケモンIDをコピー
	ld [hli], a
	ld [hl], $ff         ; 終端記号

; ここからは Pokemon Data をコピー

	; hl = 移動先の wPartyMons(wBoxMons) のエントリ
.findMonDataDest
	ld a, [wMoveMonType]
	dec a
	ld hl, wPartyMons
	ld bc, wPartyMon2 - wPartyMon1 ; $2c
	ld a, [wPartyCount]
	jr nz, .addMonOffset
	ld hl, wBoxMons
	ld bc, wBoxMon2 - wBoxMon1 ; $21
	ld a, [wNumInBox]
.addMonOffset
	dec a
	call AddNTimes

.findMonDataSrc
	push hl	; push 移動先の wPartyMons(wBoxMons, wDayCareMon) のエントリ
	ld e, l
	ld d, h	; de = 移動先の wPartyMons(wBoxMons, wDayCareMon) のエントリ

	; hl = 移動元の wPartyMons(wBoxMons, wDayCareMon) のエントリ
	ld a, [wMoveMonType]
	and a
	ld hl, wBoxMons
	ld bc, wBoxMon2 - wBoxMon1 ; $21
	jr z, .addMonOffset2
	cp DAYCARE_TO_PARTY
	ld hl, wDayCareMon
	jr z, .copyMonData
	ld hl, wPartyMons
	ld bc, wPartyMon2 - wPartyMon1 ; $2c
.addMonOffset2
	ld a, [wWhichPokemon]
	call AddNTimes

	; この時点で  
	; hl = 移動元の wPartyMons(wBoxMons, wDayCareMon) のエントリ
	; de = 移動先の wPartyMons(wBoxMons, wDayCareMon) のエントリ
.copyMonData
	; ポケモンのデータを移動先にコピー
	push hl
	push de
	ld bc, wBoxMon2 - wBoxMon1	; box_struct_length
	call CopyData
	pop de
	pop hl

	; 移動元が手持ちの場合は XXXBoxLevel を XXXLevel で上書き
	ld a, [wMoveMonType]
	and a ; BOX_TO_PARTY
	jr z, .findOTdest
	cp DAYCARE_TO_PARTY
	jr z, .findOTdest
	ld bc, wBoxMon2 - wBoxMon1
	add hl, bc
	ld a, [hl] ; a = [XXXLevel]
	inc de
	inc de
	inc de
	ld [de], a ; [XXXBoxLevel] = a

; ここからは OT(最初のトレーナー名) をコピーする
.findOTdest
	ld a, [wMoveMonType]
	cp PARTY_TO_DAYCARE
	ld de, wDayCareMonOT
	jr z, .findOTsrc
	dec a 
	ld hl, wPartyMonOT
	ld a, [wPartyCount]
	jr nz, .addOToffset
	ld hl, wBoxMonOT
	ld a, [wNumInBox]
.addOToffset
	dec a
	call SkipFixedLengthTextEntries
	ld d, h
	ld e, l
.findOTsrc
	ld hl, wBoxMonOT
	ld a, [wMoveMonType]
	and a
	jr z, .addOToffset2
	ld hl, wDayCareMonOT
	cp DAYCARE_TO_PARTY
	jr z, .copyOT
	ld hl, wPartyMonOT
.addOToffset2
	ld a, [wWhichPokemon]
	call SkipFixedLengthTextEntries
.copyOT
	ld bc, NAME_LENGTH
	call CopyData
	ld a, [wMoveMonType]

; ここからは ポケモンの名前をコピーする
.findNickDest
	cp PARTY_TO_DAYCARE
	ld de, wDayCareMonName
	jr z, .findNickSrc
	dec a
	ld hl, wPartyMonNicks
	ld a, [wPartyCount]
	jr nz, .addNickOffset
	ld hl, wBoxMonNicks
	ld a, [wNumInBox]
.addNickOffset
	dec a
	call SkipFixedLengthTextEntries
	ld d, h
	ld e, l
.findNickSrc
	ld hl, wBoxMonNicks
	ld a, [wMoveMonType]
	and a
	jr z, .addNickOffset2
	ld hl, wDayCareMonName
	cp DAYCARE_TO_PARTY
	jr z, .copyNick
	ld hl, wPartyMonNicks
.addNickOffset2
	ld a, [wWhichPokemon]
	call SkipFixedLengthTextEntries
.copyNick
	ld bc, NAME_LENGTH
	call CopyData
	pop hl
	ld a, [wMoveMonType]
	cp PARTY_TO_BOX
	jr z, .done
	cp PARTY_TO_DAYCARE
	jr z, .done
	push hl
	srl a
	add $2
	ld [wMonDataLocation], a
	call LoadMonData
	callba CalcLevelFromExperience
	ld a, d
	ld [wCurEnemyLVL], a
	pop hl
	ld bc, wBoxMon2 - wBoxMon1
	add hl, bc
	ld [hli], a
	ld d, h
	ld e, l
	ld bc, -18
	add hl, bc
	ld b, $1
	call CalcStats

.done
	and a	; キャリーをクリア
	ret
