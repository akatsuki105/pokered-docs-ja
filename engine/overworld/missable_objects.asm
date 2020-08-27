; **MarkTownVisitedAndLoadMissableObjects**  
; マップ訪問フラグを立て、 missable object(マップ上のアイテム)の情報を wMissableObjectList に読み込む  
; - - -  
; LoadMapHeader によってマップ読み込み時に呼び出される  
MarkTownVisitedAndLoadMissableObjects:
	ld a, [wCurMap]
	
	; [wCurMap] >= ROUTE_1 -> .next
	; Town の Map ID は 全て ROUTE_1 の前に割り当てられているので wCurMap >= ROUTE_1 なら Townではない
	cp ROUTE_1
	jr nc, .next

; .inTown
	; Town のときは 訪れたことのあるマップを表すフラグを立てる (そらをとぶ のため)
	ld c, a
	ld b, FLAG_SET
	ld hl, wTownVisitedFlag
	predef FlagActionPredef

.next
	; hl = 現在のマップの MapHSPointersエントリ
	ld hl, MapHSPointers
	ld a, [wCurMap]
	ld b, $0
	ld c, a
	add hl, bc
	add hl, bc	; MapHSPointers の各エントリは 2byte なので

	; hl = [hl]	(LoadMissableObjects の `ld l, a`と合わせて)
	ld a, [hli]
	ld h, [hl]
	; fall through

; **LoadMissableObjects**  
; missable object(マップ上のアイテム)の情報を wMissableObjectList に読み込む  
LoadMissableObjects:
	ld l, a

	; この時点で hl = MapHS${XX}

	push hl

; hl = MapHS${XX} - MapHS00
	ld de, MapHS00             ; calculate difference between out pointer and the base pointer
	ld a, l
	sub e
	jr nc, .asm_f13c
	dec h
.asm_f13c
	ld l, a
	ld a, h
	sub d
	ld h, a

	; (MapHS${XX} - MapHS00) / 3  
	; MapHS${XX} の global offsetが得られる (つまり MapHS00 から MapHS${XX} まで　いくつの missable item が得られる)
	ld a, h
	ld [H_DIVIDEND], a
	ld a, l
	ld [H_DIVIDEND+1], a
	xor a
	ld [H_DIVIDEND+2], a
	ld [H_DIVIDEND+3], a
	ld a, $3
	ld [H_DIVISOR], a
	ld b, $2
	call Divide

	ld a, [wCurMap]
	ld b, a						; b = [wCurMap]
	ld a, [H_DIVIDEND+3]
	ld c, a                    	; a = c = global_offset
	ld de, wMissableObjectList	; de = wMissableObjectList
	pop hl						; hl = MapHS${XX}

.writeMissableObjectsListLoop
; ループ全体を通して、 wMissableObjectList に 現在のマップの missable object情報を書き込んでいく
; {
	; a = Map ID (MapHS${XX} の各エントリの 1byte目)
	ld a, [hli]

	; テーブルの終わり(MapHSA2 のときに有効) -> .done
	cp $ff
	jr z, .done     ; end of list

	; Map ID != [wCurMap] つまり 現在のマップ の探索は終了 -> .done
	cp b
	jr nz, .done

	ld a, [hli]					; a = スプライトID
	inc hl						; hl = 次のアイテムエントリ

	; wMissableObjectList のエントリの 1byte目 = スプライトID
	ld [de], a                 	; wMissableObjectList = スプライトID
	inc de
	; wMissableObjectList のエントリの 2byte目 = global offset (MapHS00を 0として対象の missable object が何番目のアイテムか)
	ld a, c
	inc c
	ld [de], a
	inc de

	jr .writeMissableObjectsListLoop
; }

.done
	; wMissableObjectList に 番兵として 0xffを書き込んで return
	ld a, $ff
	ld [de], a                 ; write sentinel
	ret

InitializeMissableObjectsFlags:
	ld hl, wMissableObjectFlags
	ld bc, wMissableObjectFlagsEnd - wMissableObjectFlags
	xor a
	call FillMemory ; clear missable objects flags
	ld hl, MapHS00
	xor a
	ld [wMissableObjectCounter], a
.missableObjectsLoop
	ld a, [hli]
	cp $ff          ; end of list
	ret z
	push hl
	inc hl
	ld a, [hl]
	cp Hide
	jr nz, .skip
	ld hl, wMissableObjectFlags
	ld a, [wMissableObjectCounter]
	ld c, a
	ld b, FLAG_SET
	call MissableObjectFlagAction ; set flag if Item is hidden
.skip
	ld hl, wMissableObjectCounter
	inc [hl]
	pop hl
	inc hl
	inc hl
	jr .missableObjectsLoop

; **IsObjectHidden**  
; 現在処理中のスプライトが missable object として非表示になっているかを確認する  
; 
; INPUT: [H_CURRENTSPRITEOFFSET] = 対象のスプライトのオフセット  
; 
; OUTPUT: a = [$ffe5] = 0(表示) or 1(非表示)
IsObjectHidden:
	; b = 現在処理中のスプライト番号
	ld a, [H_CURRENTSPRITEOFFSET]
	swap a
	ld b, a

; wMissableObjectList から [H_CURRENTSPRITEOFFSET] に対応する missable object を探す
	ld hl, wMissableObjectList
.loop
; {
	; 見つからないなら missable objectではないので常に表示 -> .notHidden
	ld a, [hli]
	cp $ff
	jr z, .notHidden ; 最後まで見た

	; 現在処理中のスプライト番号と一致するか確認
	cp b
	ld a, [hli]	; a = missable object の global offset
	jr nz, .loop
; }

	; c = 対象の missable object の 表示フラグ(0 -> 表示, 1 -> 非表示)
	ld c, a	; c = missable object の global offset
	ld b, FLAG_TEST
	ld hl, wMissableObjectFlags
	call MissableObjectFlagAction			; wMissableObjectFlagsの cビット目 を読みだして 結果を cに格納
	
	; c が 1 ならスプライトは非表示になっている
	ld a, c
	and a
	jr nz, .hidden
.notHidden
	xor a
.hidden
	ld [$ffe5], a
	ret

; **ShowObject**  
; missable object (モンボアイコンのアイテムなど) をマップ上に表示された状態にする  
; - - -  
; wMissableObjectFlags の missable object の非表示フラグをクリアする  
; 
; INPUT: [wMissableObjectIndex] = 表示する missable object の global offset (MapHS00 を 0として対象の missable object が何番目のアイテムか)
ShowObject:
; **ShowObject2**  
; `ShowObject` と同じ
ShowObject2:
	ld hl, wMissableObjectFlags
	ld a, [wMissableObjectIndex]
	ld c, a
	ld b, FLAG_RESET
	call MissableObjectFlagAction   ; reset "removed" flag
	jp UpdateSprites

; **HideObject**  
; missable object (モンボアイコンのアイテムなど) をマップ上から非表示にする  
; - - -  
; wMissableObjectFlags の missable object の非表示フラグを立てる  
; モンボアイコンのアイテムなどを拾うなどして消滅させるときにこの処理を呼ぶ  
; 
; INPUT: [wMissableObjectIndex] = 取り除く missable object の global offset (MapHS00 を 0として対象の missable object が何番目のアイテムか)
HideObject:
	ld hl, wMissableObjectFlags
	ld a, [wMissableObjectIndex]
	ld c, a
	ld b, FLAG_SET
	call MissableObjectFlagAction   ; set "removed" flag
	jp UpdateSprites

; **MissableObjectFlagAction**  
; hlのビットフィールドのビットcにおいてアクションbを実行する  
; - - -  
; `FlagAction` と全く同じ処理  
; 
; INPUT:  
; c = アクション b の対象が hl の何ビット目か  
; b = bitに対してとるアクション(0 -> クリア, 1 -> セット, 2 -> リード)  
; 
; OUTPUT: cレジスタ = アクションの結果(リードなら読み取ったbit)  
MissableObjectFlagAction:

	push hl
	push de
	push bc

	; bit
	ld a, c
	ld d, a
	and 7
	ld e, a

	; byte
	ld a, d
	srl a
	srl a
	srl a
	add l
	ld l, a
	jr nc, .ok
	inc h
.ok

	; d = 1 << e (bitmask)
	inc e
	ld d, 1
.shift
	dec e
	jr z, .shifted
	sla d
	jr .shift
.shifted

	ld a, b
	and a
	jr z, .reset
	cp 2
	jr z, .read

.set
	ld a, [hl]
	ld b, a
	ld a, d
	or b
	ld [hl], a
	jr .done

.reset
	ld a, [hl]
	ld b, a
	ld a, d
	xor $ff
	and b
	ld [hl], a
	jr .done

.read
	ld a, [hl]
	ld b, a
	ld a, d
	and b

.done
	pop bc
	pop de
	pop hl
	ld c, a
	ret
