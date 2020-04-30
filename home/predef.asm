; Predefされた(ドキュメント参照)のAレジスタにはいっている関数を呼び出す  
; 他のレジスタを退避するには、Predefで呼び出した関数先でGetPredefRegistersを呼び出す
Predef::
	; GetPredefPointerの引数としてPredefIDをセット
	ld [wPredefID], a

	; wPredefParentBank = 現在のROM番号
	; TODO: A hack for LoadDestinationWarpPosition.
	; LoadTilesetHeader(predef $19)参照
	ld a, [H_LOADEDROMBANK]
	ld [wPredefParentBank], a

	; GetPredefPointerのあるROMバンクにスイッチ
	push af
	ld a, BANK(GetPredefPointer)
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	
	call GetPredefPointer

	; Predefのあるバンクにスイッチ
	ld a, [wPredefBank]
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a

	; Predefにジャンプ(終了後に.doneに帰ってくるようにしている)
	ld de, .done
	push de
	jp hl
.done
	; バンクを復帰
	pop af
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	ret

; GetPredefPointerで退避されたレジスタを復帰させる
GetPredefRegisters::
	ld a, [wPredefRegisters + 0]
	ld h, a
	ld a, [wPredefRegisters + 1]
	ld l, a
	ld a, [wPredefRegisters + 2]
	ld d, a
	ld a, [wPredefRegisters + 3]
	ld e, a
	ld a, [wPredefRegisters + 4]
	ld b, a
	ld a, [wPredefRegisters + 5]
	ld c, a
	ret
