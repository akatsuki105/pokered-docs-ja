; aバンクのhlが示すアドレスから(aバンクの)deが示すアドレスにbcバイトだけコピー
FarCopyData::
	; 元のバンク番号を保存
	ld [wBuffer], a
	ld a, [H_LOADEDROMBANK]
	push af

	; バンク切り替え
	ld a, [wBuffer]
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	call CopyData

	; バンクを戻す
	pop af
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	ret

; hlが示すアドレスからdeが示すアドレスにbcバイトだけコピー
CopyData::
	inline "[de++] = [hl++]"
	dec bc
	ld a, c
	or b
	jr nz, CopyData	; もしbcが0になっていたら b | cも当然0なので
	ret
