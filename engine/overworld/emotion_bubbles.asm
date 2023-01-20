; **EmotionBubble**  
; !マークなどの感情を表す吹き出しを表示させる処理
; 
; INPUT: [wWhichEmotionBubble] = 対象のEmotion Bubble番号
EmotionBubble:
	; hl = 対象のEmotionBubbleの画像データのポインタ
	ld a, [wWhichEmotionBubble]
	ld c, a
	ld b, 0
	ld hl, EmotionBubblesPointerTable
	; 各エントリ2バイトなので2回Add
	add hl, bc
	add hl, bc

	; de = 画像データ
	ld e, [hl]
	inc hl
	ld d, [hl]

	; EmotionBubbleのタイルデータをVRAMに転送
	ld hl, vChars1 + $780
	lb bc, BANK(EmotionBubbles), $04
	call CopyVideoData

	; スプライト表示を無効化
	ld a, [wUpdateSpritesEnabled]
	push af
	ld a, $ff
	ld [wUpdateSpritesEnabled], a

	ld a, [wd736]
	bit 6, a 
	; 段差から降りている最中/釣り中のときはde, hlのポインタを変える
	ld hl, wOAMBuffer + 4 * 35 + $3 ; $8f
	ld de, wOAMBuffer + 4 * 39 + $3 ; $9f
	jr z, .next
	; それ以外のとき
	ld hl, wOAMBuffer + 4 * 31 + $3 ; $7f
	ld de, wOAMBuffer + 4 * 35 + $3 ; $8f

; OAMのデータを16バイトほど前のアドレスのメモリに移動して、OAMBufferの開始地点にEmotion BuffleのOAMデータのためのスペースを確保
; INPUT:  
; - de = コピー先
; - hl = コピー元
.next
	ld bc, $90 ; 160 => OAMデータの長さ
.loop
	ld a, [hl]
	ld [de], a
	dec hl
	dec de
	dec bc
	ld a, c
	or b
	jr nz, .loop

; get the screen coordinates of the sprite the bubble is to be displayed above
; Emotion Bubbleを表示する対象のスプライトのcoordsを得る
	; hl = 対象のスプライトの$c1x4
	ld hl, wSpriteStateData1 + 4
	ld a, [wEmotionBubbleSpriteIndex]
	swap a
	ld c, a
	ld b, 0
	add hl, bc

	; b = スプライトのY座標
	; c = スプライトのX座標 + 8
	ld a, [hli]
	ld b, a
	inc hl		; hl = $c1x6
	ld a, [hl]
	add $8
	ld c, a

	; OAMにEmotion bubbleのOAMデータを書き込む
	ld de, EmotionBubblesOAM
	xor a
	call WriteOAMBlock
	ld c, 60
	call DelayFrames

	pop af

	; Emotion Bubbleを表示させる
	ld [wUpdateSpritesEnabled], a
	call DelayFrame
	jp UpdateSprites

; EmotionBubbleの画像データのポインタのリスト
EmotionBubblesPointerTable:
	dw EmotionBubbles
	dw EmotionBubbles + $40
	dw EmotionBubbles + $80

; EmotionBubbleのOAMデータ
EmotionBubblesOAM:
	db $F8,$00,$F9,$00	; (Y座標, X座標, タイル番号, 属性)
	db $FA,$00,$FB,$00

EmotionBubbles:
	INCBIN "gfx/emotion_bubbles.2bpp"
