; **UncompressSpriteData**  
; spriteのグラフィックデータを解凍する関数  
; - - -  
; aレジスタで指定した対象のグラフィックがあるバンクにスイッチして _UncompressSpriteData を呼び出す  
; スイッチしたバンクのどのアドレスからグラフィックデータがあるかは wSpriteInputPtr に格納されている  
UncompressSpriteData::
	; グラフィックデータのあるバンクにスイッチ
	ld b, a
	ld a, [H_LOADEDROMBANK]
	push af
	ld a, b
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	; SRAMの変数を設定
	ld a, SRAM_ENABLE
	ld [MBC1SRamEnable], a
	xor a
	ld [MBC1SRamBank], a
	; _UncompressSpriteDataを呼び出してスプライトを解凍する
	call _UncompressSpriteData
	; バンクを戻す
	pop af
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	ret

; スプライトをロードするのに必要なデータを初期化し、UncompressSpriteDataLoop を呼び出す
_UncompressSpriteData::
	; sSpriteBuffer1 と sSpriteBuffer2 を0クリア
	ld hl, sSpriteBuffer1
	ld c, (2*SPRITEBUFFERSIZE) % $100
	ld b, (2*SPRITEBUFFERSIZE) / $100
	xor a
	call FillMemory

	ld a, $1
	ld [wSpriteInputBitCounter], a
	ld a, $3
	ld [wSpriteOutputBitOffset], a
	
	; 
	xor a
	ld [wSpriteCurPosX], a
	ld [wSpriteCurPosY], a
	ld [wSpriteLoadFlags], a

	; 入力の最初のバイトから、タイル（8x8ピクセル）のスプライトの幅（7-4bit）と高さ（3-0bit）がわかるので読み取る
	call ReadNextInputByte

	; 読み取った最初のバイトから得たタイルの高さと幅とをそれぞれ [wSpriteHeight], [wSpriteWidth]に格納する
	ld b, a
	and $f
	add a
	add a
	add a
	ld [wSpriteHeight], a
	ld a, b
	swap a
	and $f
	add a
	add a
	add a
	ld [wSpriteWidth], a

	; 次に 1bit 読み取って [wSpriteLoadFlags] に格納
	; 結果として [wSpriteLoadFlags]の bit1 は 0, bit0 は読み取ったデータになる
	; これにより sSpriteBuffer1 とsSpriteBuffer2 に2つのデータチャンクが読み込まれる
	; bit0 は最初のチャンクが配置される buffer が sSpriteBuffer1ととsSpriteBuffer2 のどちらなのかを示している
	call ReadNextInputBit
	ld [wSpriteLoadFlags], a 
	; 下に続く

; uncompresses a chunk from the sprite input data stream (pointed to at wd0da) into sSpriteBuffer1 or sSpriteBuffer2
; 各チャンクは1bppでスプライトのグラフィックデータを保持している 2つのチャンクを組み合わせることで2bppのスプライトのグラを復元する
; note that this is an endless loop which is terminated during a call to MoveToNextBufferPosition by manipulating the stack
UncompressSpriteDataLoop::
	; hl = sSpriteBuffer1(wSpriteLoadFlagsの bit0 == 0) or sSpriteBuffer2(wSpriteLoadFlagsの bit0 == 1)
	ld hl, sSpriteBuffer1
	ld a, [wSpriteLoadFlags]
	bit 0, a
	jr z, .useSpriteBuffer1
	ld hl, sSpriteBuffer2

.useSpriteBuffer1
	call StoreSpriteOutputPointer

	; wSpriteLoadFlagsの bit1 == 0 -> .startDecompression  
	ld a, [wSpriteLoadFlags]
	bit 1, a
	jr z, .startDecompression  ; check if last iteration

	; 2チャンク目も読み取る場合は, 1-2bitさらに読み進めて unpacking modeを決定する
	call ReadNextInputBit
	and a
	jr z, .unpackingMode0      
	call ReadNextInputBit      
	inc a					   ; ここにきている時点で1bit目は1なのでインクリメント

	; INPUT: a = unpacking mode
.unpackingMode0
	ld [wSpriteUnpackMode], a

.startDecompression
	; 最初の1bit目が 0 -> .readRLEncodedZeros
	call ReadNextInputBit
	and a
	jr z, .readRLEncodedZeros ; if first bit is 0, the input starts with zeroes, otherwise with (non-zero) input

.readNextInput
	; a = 読み取った2bit (1bit目 << 1 | 2bit目)
	call ReadNextInputBit		; read1
	ld c, a
	call ReadNextInputBit		; read2
	sla c
	or c                       	; a = read1 << 1 | read2
	
	; a == 0 つまり read1もread2も 0 -> .readRLEncodedZeros 
	and a
	jr z, .readRLEncodedZeros

	; 読み取った2bit(read1, read2)が0でないときは output bufferに反映
	call WriteSpriteBitsToBuffer
	call MoveToNextBufferPosition
	jr .readNextInput

.readRLEncodedZeros
	ld c, $0                   ; number of zeroes it length encoded, the number
.countConsecutiveOnesLoop      ; of consecutive ones determines the number of bits the number has
	call ReadNextInputBit
	and a
	jr z, .countConsecutiveOnesFinished
	inc c
	jr .countConsecutiveOnesLoop
.countConsecutiveOnesFinished
	ld a, c
	add a
	ld hl, LengthEncodingOffsetList
	add l
	ld l, a
	jr nc, .noCarry
	inc h
.noCarry
	ld a, [hli]                ; read offset that is added to the number later on
	ld e, a                    ; adding an offset of 2^length - 1 makes every integer uniquely
	ld d, [hl]                 ; representable in the length encoding and saves bits
	push de
	inc c
	ld e, $0
	ld d, e
.readNumberOfZerosLoop        ; reads the next c+1 bits of input
	call ReadNextInputBit
	or e
	ld e, a
	dec c
	jr z, .readNumberOfZerosDone
	sla e
	rl d
	jr .readNumberOfZerosLoop
.readNumberOfZerosDone
	pop hl                     ; add the offset
	add hl, de
	ld e, l
	ld d, h
.writeZerosLoop
	ld b, e
	xor a                      ; write 00 to buffer
	call WriteSpriteBitsToBuffer
	ld e, b
	call MoveToNextBufferPosition
	dec de
	ld a, d
	and a
	jr nz, .continueLoop
	ld a, e
	and a
.continueLoop
	jr nz, .writeZerosLoop
	jr .readNextInput

; **MoveToNextBufferPosition**  
; スプライトのグラフィックデータを読み進める  
; - - -  
; 現在解凍中のスプライトのoutput pointer を次の position に進めてreturnする  
; グラフィックデータをすべて読み終えたとき、returnせず UnpackSprite にジャンプする
; 
; ![flow](../docs/image/pic/uncompress.png)
MoveToNextBufferPosition::
	; wSpriteCurPosY + 1 == wSpriteHeight つまり処理が最後の行にいったとき -> .curColumnDone(列ごとに処理するので)
	ld a, [wSpriteHeight]
	ld b, a
	ld a, [wSpriteCurPosY]
	inc a ; a = [wSpriteCurPosY]+1 = 次の行
	cp b
	jr z, .curColumnDone

	; 現在の列が終わっていない(最後の行まで終えていない)ときは次の行に進める(通常の処理)
	ld [wSpriteCurPosY], a ; [wSpriteCurPosY] を次の行に
	; wSpriteOutputPtrを進める(指すアドレスを1バイト増やす)
	ld a, [wSpriteOutputPtr]	; [wSpriteOutputPtr]++
	inc a						
	ld [wSpriteOutputPtr], a
	ret nz
	ld a, [wSpriteOutputPtr+1] 	; wSpriteOutputPtrは wSpriteOutputPtr+1と合わせて2バイトの値であるため、wSpriteOutputPtrがオーバーフローしたらwSpriteOutputPtr+1をインクリメントする(キャリーみたいに)
	inc a
	ld [wSpriteOutputPtr+1], a
	ret
	
	; 現在の行を終えたとき、次の行へ行く
.curColumnDone
	; [wSpriteCurPosY]をリセット
	xor a
	ld [wSpriteCurPosY], a

	; [wSpriteOutputBitOffset] == 0 つまり 8列終えた -> .bitOffsetsDone
	ld a, [wSpriteOutputBitOffset]
	and a
	jr z, .bitOffsetsDone

	; 現在の列を2列進める([wSpriteOutputBitOffset]を読み進める)
	dec a
	ld [wSpriteOutputBitOffset], a	; [wSpriteOutputBitOffset]--

	; wSpriteOutputPtr を 最初の行 に 戻す
	ld hl, wSpriteOutputPtrCached
	ld a, [hli]
	ld [wSpriteOutputPtr], a
	ld a, [hl]
	ld [wSpriteOutputPtr+1], a
	ret

	; 1タイル分の列(8列)処理し終えたらここにきて次のタイル列に
.bitOffsetsDone
	; [wSpriteOutputBitOffset]を 3 にリセット
	ld a, $3
	ld [wSpriteOutputBitOffset], a

	; 次のタイル列へ ([wSpriteCurPosX] += 8)
	ld a, [wSpriteCurPosX]
	add $8
	ld [wSpriteCurPosX], a

	; 全部の列を処理した -> .allColumnsDone
	ld b, a
	ld a, [wSpriteWidth]
	cp b
	jr z, .allColumnsDone

	; 次のタイル列へいくために wSpriteOutputPtrを 1 進める
	; 最初の行のptrはcacheされる
	ld a, [wSpriteOutputPtr]
	ld l, a
	ld a, [wSpriteOutputPtr+1]
	ld h, a
	inc hl
	jp StoreSpriteOutputPointer

.allColumnsDone
	pop hl
	xor a
	ld [wSpriteCurPosX], a
	
	; wSpriteLoadFlags を見てもう一度 UncompressSpriteDataLoopするか決める (0:する、　1:しない)
	ld a, [wSpriteLoadFlags]
	bit 1, a
	jr nz, .done
	xor $1
	set 1, a
	ld [wSpriteLoadFlags], a
	jp UncompressSpriteDataLoop
.done
	jp UnpackSprite

; aに格納されている 2bitの値 を wSpriteOutputPtr が示す output buffer に書き込む
WriteSpriteBitsToBuffer::
	ld e, a

	; a = 000000XX の形で入ってくるので wSpriteOutputBitOffset の値を見て適切な形にシフトする
	; [wSpriteOutputBitOffset] == 0 -> .offset0
	; [wSpriteOutputBitOffset] == 1 -> .offset1
	; [wSpriteOutputBitOffset] == 2 -> .offset2
	ld a, [wSpriteOutputBitOffset]
	and a
	jr z, .offset0
	cp $2
	jr c, .offset1
	jr z, .offset2

	; [wSpriteOutputBitOffset] == 3
	; e = XX000000 -> .offset0
	rrc e
	rrc e
	jr .offset0

	; e = 0000XX00 -> .offset1
.offset1
	sla e
	sla e
	jr .offset0

	; e = 00XX0000 -> .offset2
.offset2
	swap e

	; INPUT: e = wSpriteOutputBitOffset に合わせて整形した2bit
.offset0
	; wSpriteOutputPtrの指す場所(output buffer)に2bitを書き込む
	ld a, [wSpriteOutputPtr]
	ld l, a
	ld a, [wSpriteOutputPtr+1]
	ld h, a
	ld a, [hl]
	or e	; output buffer |= e
	ld [hl], a
	ret

; **ReadNextInputBit**  
; wSpriteInputPtr から値を 1bit 読み進めて読み取ったbitを a に入れて返す  
ReadNextInputBit::
	; offset != 1 -> .curByteHasMoreBitsToRead
	ld a, [wSpriteInputBitCounter]
	dec a
	jr nz, .curByteHasMoreBitsToRead

	; offset == 1 つまり これが今のバイトの最後のbit
	call ReadNextInputByte
	ld [wSpriteInputCurByte], a
	ld a, $8

	; INPUT: a = [wSpriteInputBitCounter] - 1(今のバイトの次のbit) or 8(次のバイトに移った)
.curByteHasMoreBitsToRead
	ld [wSpriteInputBitCounter], a ; wSpriteInputBitCounterを進める
	; バイトデータを読み進めた分消滅させる([wSpriteInputCurByte] <<= 1)
	ld a, [wSpriteInputCurByte]
	rlca
	ld [wSpriteInputCurByte], a
	and $1 ; a = 読み取り結果
	ret

; **ReadNextInputByte**  
; wSpriteInputPtr から値を1つ読み進めて読み取った結果を a に入れて返す  
; - - -  
; a = read([wSpriteInputPtr]), [wSpriteInputPtr]++  
ReadNextInputByte::
	; wSpriteInputPtrの指すアドレスの内容をbに読み込む
	ld a, [wSpriteInputPtr]
	ld l, a
	ld a, [wSpriteInputPtr+1]
	ld h, a		; hl = [wSpriteInputPtr] << 8 | [wSpriteInputPtr+1]
	ld a, [hli] ; a = [hl++]
	ld b, a

	; wSpriteInputPtrの指すアドレス値をインクリメント
	ld a, l
	ld [wSpriteInputPtr], a
	ld a, h
	ld [wSpriteInputPtr+1], a
	
	ld a, b ; a = b = 読み取った内容
	ret

; the nth item is 2^n - 1
LengthEncodingOffsetList::
	dw %0000000000000001
	dw %0000000000000011
	dw %0000000000000111
	dw %0000000000001111
	dw %0000000000011111
	dw %0000000000111111
	dw %0000000001111111
	dw %0000000011111111
	dw %0000000111111111
	dw %0000001111111111
	dw %0000011111111111
	dw %0000111111111111
	dw %0001111111111111
	dw %0011111111111111
	dw %0111111111111111
	dw %1111111111111111

; unpacks the sprite data depending on the unpack mode
UnpackSprite::
	ld a, [wSpriteUnpackMode]
	cp $2
	jp z, UnpackSpriteMode2
	and a
	jp nz, XorSpriteChunks
	ld hl, sSpriteBuffer1
	call SpriteDifferentialDecode
	ld hl, sSpriteBuffer2
	; fall through

; decodes differential encoded sprite data
; input bit value 0 preserves the current bit value and input bit value 1 toggles it (starting from initial value 0).
SpriteDifferentialDecode::
	xor a
	ld [wSpriteCurPosX], a
	ld [wSpriteCurPosY], a
	call StoreSpriteOutputPointer
	ld a, [wSpriteFlipped]
	and a
	jr z, .notFlipped
	ld hl, DecodeNybble0TableFlipped
	ld de, DecodeNybble1TableFlipped
	jr .storeDecodeTablesPointers
.notFlipped
	ld hl, DecodeNybble0Table
	ld de, DecodeNybble1Table
.storeDecodeTablesPointers
	ld a, l
	ld [wSpriteDecodeTable0Ptr], a
	ld a, h
	ld [wSpriteDecodeTable0Ptr+1], a
	ld a, e
	ld [wSpriteDecodeTable1Ptr], a
	ld a, d
	ld [wSpriteDecodeTable1Ptr+1], a
	ld e, $0                          ; last decoded nybble, initialized to 0
.decodeNextByteLoop
	ld a, [wSpriteOutputPtr]
	ld l, a
	ld a, [wSpriteOutputPtr+1]
	ld h, a
	ld a, [hl]
	ld b, a
	swap a
	and $f
	call DifferentialDecodeNybble     ; decode high nybble
	swap a
	ld d, a
	ld a, b
	and $f
	call DifferentialDecodeNybble     ; decode low nybble
	or d
	ld b, a
	ld a, [wSpriteOutputPtr]
	ld l, a
	ld a, [wSpriteOutputPtr+1]
	ld h, a
	ld a, b
	ld [hl], a                        ; write back decoded data
	ld a, [wSpriteHeight]
	add l                             ; move on to next column
	jr nc, .noCarry
	inc h
.noCarry
	ld [wSpriteOutputPtr], a
	ld a, h
	ld [wSpriteOutputPtr+1], a
	ld a, [wSpriteCurPosX]
	add $8
	ld [wSpriteCurPosX], a
	ld b, a
	ld a, [wSpriteWidth]
	cp b
	jr nz, .decodeNextByteLoop        ; test if current row is done
	xor a
	ld e, a
	ld [wSpriteCurPosX], a
	ld a, [wSpriteCurPosY]           ; move on to next row
	inc a
	ld [wSpriteCurPosY], a
	ld b, a
	ld a, [wSpriteHeight]
	cp b
	jr z, .done                       ; test if all rows finished
	ld a, [wSpriteOutputPtrCached]
	ld l, a
	ld a, [wSpriteOutputPtrCached+1]
	ld h, a
	inc hl
	call StoreSpriteOutputPointer
	jr .decodeNextByteLoop
.done
	xor a
	ld [wSpriteCurPosY], a
	ret

; decodes the nybble stored in a. Last decoded data is assumed to be in e (needed to determine if initial value is 0 or 1)
DifferentialDecodeNybble::
	srl a               ; c=a%2, a/=2
	ld c, $0
	jr nc, .evenNumber
	ld c, $1
.evenNumber
	ld l, a
	ld a, [wSpriteFlipped]
	and a
	jr z, .notFlipped     ; determine if initial value is 0 or one
	bit 3, e              ; if flipped, consider MSB of last data
	jr .selectLookupTable
.notFlipped
	bit 0, e              ; else consider LSB
.selectLookupTable
	ld e, l
	jr nz, .initialValue1 ; load the appropriate table
	ld a, [wSpriteDecodeTable0Ptr]
	ld l, a
	ld a, [wSpriteDecodeTable0Ptr+1]
	jr .tableLookup
.initialValue1
	ld a, [wSpriteDecodeTable1Ptr]
	ld l, a
	ld a, [wSpriteDecodeTable1Ptr+1]
.tableLookup
	ld h, a
	ld a, e
	add l
	ld l, a
	jr nc, .noCarry
	inc h
.noCarry
	ld a, [hl]
	bit 0, c
	jr nz, .selectLowNybble
	swap a  ; select high nybble
.selectLowNybble
	and $f
	ld e, a ; update last decoded data
	ret

DecodeNybble0Table::
	dn $0, $1
	dn $3, $2
	dn $7, $6
	dn $4, $5
	dn $f, $e
	dn $c, $d
	dn $8, $9
	dn $b, $a
DecodeNybble1Table::
	dn $f, $e
	dn $c, $d
	dn $8, $9
	dn $b, $a
	dn $0, $1
	dn $3, $2
	dn $7, $6
	dn $4, $5
DecodeNybble0TableFlipped::
	dn $0, $8
	dn $c, $4
	dn $e, $6
	dn $2, $a
	dn $f, $7
	dn $3, $b
	dn $1, $9
	dn $d, $5
DecodeNybble1TableFlipped::
	dn $f, $7
	dn $3, $b
	dn $1, $9
	dn $d, $5
	dn $0, $8
	dn $c, $4
	dn $e, $6
	dn $2, $a

; combines the two loaded chunks with xor (the chunk loaded second is the destination). The source chunk is differeintial decoded beforehand.
XorSpriteChunks::
	xor a
	ld [wSpriteCurPosX], a
	ld [wSpriteCurPosY], a
	call ResetSpriteBufferPointers
	ld a, [wSpriteOutputPtr]          ; points to buffer 1 or 2, depending on flags
	ld l, a
	ld a, [wSpriteOutputPtr+1]
	ld h, a
	call SpriteDifferentialDecode      ; decode buffer 1 or 2, depending on flags
	call ResetSpriteBufferPointers
	ld a, [wSpriteOutputPtr]          ; source buffer, points to buffer 1 or 2, depending on flags
	ld l, a
	ld a, [wSpriteOutputPtr+1]
	ld h, a
	ld a, [wSpriteOutputPtrCached]    ; destination buffer, points to buffer 2 or 1, depending on flags
	ld e, a
	ld a, [wSpriteOutputPtrCached+1]
	ld d, a
.xorChunksLoop
	ld a, [wSpriteFlipped]
	and a
	jr z, .notFlipped
	push de
	ld a, [de]
	ld b, a
	swap a
	and $f
	call ReverseNybble                 ; if flipped reverse the nybbles in the destination buffer
	swap a
	ld c, a
	ld a, b
	and $f
	call ReverseNybble
	or c
	pop de
	ld [de], a
.notFlipped
	ld a, [hli]
	ld b, a
	ld a, [de]
	xor b
	ld [de], a
	inc de
	ld a, [wSpriteCurPosY]
	inc a
	ld [wSpriteCurPosY], a             ; go to next row
	ld b, a
	ld a, [wSpriteHeight]
	cp b
	jr nz, .xorChunksLoop               ; test if column finished
	xor a
	ld [wSpriteCurPosY], a
	ld a, [wSpriteCurPosX]
	add $8
	ld [wSpriteCurPosX], a             ; go to next column
	ld b, a
	ld a, [wSpriteWidth]
	cp b
	jr nz, .xorChunksLoop               ; test if all columns finished
	xor a
	ld [wSpriteCurPosX], a
	ret

; reverses the bits in the nybble given in register a
ReverseNybble::
	ld de, NybbleReverseTable
	add e
	ld e, a
	jr nc, .noCarry
	inc d
.noCarry
	ld a, [de]
	ret

; resets sprite buffer pointers to buffer 1 and 2, depending on wSpriteLoadFlags
ResetSpriteBufferPointers::
	ld a, [wSpriteLoadFlags]
	bit 0, a
	jr nz, .buffer2Selected
	ld de, sSpriteBuffer1
	ld hl, sSpriteBuffer2
	jr .storeBufferPointers
.buffer2Selected
	ld de, sSpriteBuffer2
	ld hl, sSpriteBuffer1
.storeBufferPointers
	ld a, l
	ld [wSpriteOutputPtr], a
	ld a, h
	ld [wSpriteOutputPtr+1], a
	ld a, e
	ld [wSpriteOutputPtrCached], a
	ld a, d
	ld [wSpriteOutputPtrCached+1], a
	ret

; maps each nybble to its reverse
NybbleReverseTable::
	db $0, $8, $4, $c, $2, $a, $6 ,$e, $1, $9, $5, $d, $3, $b, $7 ,$f

; combines the two loaded chunks with xor (the chunk loaded second is the destination). Both chunks are differeintial decoded beforehand.
UnpackSpriteMode2::
	call ResetSpriteBufferPointers
	ld a, [wSpriteFlipped]
	push af
	xor a
	ld [wSpriteFlipped], a            ; temporarily clear flipped flag for decoding the destination chunk
	ld a, [wSpriteOutputPtrCached]
	ld l, a
	ld a, [wSpriteOutputPtrCached+1]
	ld h, a
	call SpriteDifferentialDecode
	call ResetSpriteBufferPointers
	pop af
	ld [wSpriteFlipped], a
	jp XorSpriteChunks

; **StoreSpriteOutputPointer**  
; hl を wSpriteOutputPtr と wSpriteOutputPtrCachedに格納する  
; - - -  
; [wSpriteOutputPtr] = [wSpriteOutputPtrCached] = l  
; [wSpriteOutputPtr+1] = [wSpriteOutputPtrCached+1] = h  
StoreSpriteOutputPointer::
	ld a, l
	ld [wSpriteOutputPtr], a
	ld [wSpriteOutputPtrCached], a
	ld a, h
	ld [wSpriteOutputPtr+1], a
	ld [wSpriteOutputPtrCached+1], a
	ret
