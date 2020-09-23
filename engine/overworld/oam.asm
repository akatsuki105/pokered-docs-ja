; **PrepareOAMData**  
; 現在、可視化する必要がある スプライト(人や岩など)のOAMデータ を決定して、それを wOAMBuffer に書き込む関数  
; - - -  
; この関数は VBlank中に実行される  
; スプライトが有効かどうかの判断、また wOAMBuffer に書き込む値は wSpriteStateData1 の内容をもとにする  
PrepareOAMData:
	ld a, [wUpdateSpritesEnabled]	; a = [wUpdateSpritesEnabled] - 1

	; [wUpdateSpritesEnabled] - 1 == 0 つまり スプライトが有効 -> .updateEnabled
	dec a
	jr z, .updateEnabled
	; [wUpdateSpritesEnabled] - 1 != 0xff つまり [wUpdateSpritesEnabled] == 0xff -> return
	cp -1
	ret nz

	; [wUpdateSpritesEnabled] == 0 のとき
	ld [wUpdateSpritesEnabled], a ; [wUpdateSpritesEnabled] = 0xff
	jp HideSprites ; OAM を全部非表示にして return

.updateEnabled
	xor a
	ld [hOAMBufferOffset], a		; [hOAMBufferOffset] = 0

.spriteLoop
; {
	ld [hSpriteOffset2], a			; [hSpriteOffset2] = 0xX0

	; a = [0xc1X0], de = 0xc1X0
	ld d, wSpriteStateData1 / $100	; d = 0xc1
	ld a, [hSpriteOffset2]			; e = 0xX0
	ld e, a
	ld a, [de] 						; a = [0xc1X0] = picture ID

	; picture ID == 0 -> .nextSprite
	and a
	jp z, .nextSprite

	; a = [0xc1X2]
	; de = 0xc1X2(facing/anim)
	; [wd5cd] = [0xc1X2]
	inc e
	inc e
	ld a, [de]
	ld [wd5cd], a

	; [0xc1X2] != 0xff つまり スプライトを表示するとき -> .visible
	cp $ff
	jr nz, .visible

	; スプライトを表示しない時
	call GetSpriteScreenXY
	jr .nextSprite

.visible
	; この時点で a = [0xc1X2]
	cp $a0 ; is the sprite unchanging like an item ball or boulder?
	jr c, .usefacing

; unchanging
; 対象のスプライトが、アイテムや 『かいりき』の岩のように 『顔』 を持たない場合
	and $f
	add $10 ; アイテム(モンボアイコン)や岩は方向を持たないので 方向を表す後半のテーブル(c1X2の下位ニブルのこと)はスキップする
	jr .next

.usefacing
; 対象のスプライトが、人など 『顔』　を持っている場合
	and $f	; and 0b0000XXXX

; この時点で  
; a = スプライトの方向 0x00 or 0x04 or 0x08 or 0x0c  
; de = 0xc1X2
.next
	ld l, a

; [hSpritePriority] = [c2x7] (0x80(スプライトが草むらの上) or 0x00(それ以外))
	push de
	inc d
	ld a, e
	add $5
	ld e, a		; de = c2x7
	ld a, [de] 	; a = sprite priority
	and $80		; 0b_1000_0000
	ld [hSpritePriority], a ; temp store sprite priority
	pop de

	; hl = SpriteFacingAndAnimationTable の対応方向の frame0 のエントリ
	ld h, 0		; hl = スプライトの方向 0x00 or 0x04 or 0x08 or 0x0c 
	ld bc, SpriteFacingAndAnimationTable
	add hl, hl 	; *= 2
	add hl, hl	; *= 2
	add hl, bc	; hl = 4*hl + SpriteFacingAndAnimationTable

	; bc = SpriteFacing${A}And${B} (SpriteFacingAndAnimationTable の dwエントリ0)
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld b, a
	; hl = SpriteOAMParameters(Flipped) (SpriteFacingAndAnimationTable の dwエントリ1)
	inline "hl = [hl]"

	call GetSpriteScreenXY

	; de = OAM(Buf) の先頭
	ld a, [hOAMBufferOffset]
	ld e, a
	ld d, wOAMBuffer / $100

.tileLoop
 ; {
	; hl = SpriteOAMParameters(or SpriteOAMParametersFlipped) の offsetY のアドレス

	ld a, [hSpriteScreenY]   ; Y座標(pixel単位)
	add $10                  ; Y += 16 (GBのOAMの仕様)
	add [hl]                 ; table の Yオフセット を加算
	ld [de], a               ; OAMの Y座標に計算した値を書き込む

	inc hl	; hl = SpriteOAMParameters(or SpriteOAMParametersFlipped) の offsetX のアドレス

	ld a, [hSpriteScreenX]   ; X座標(pixel単位)
	add $8                   ; X += 8 (GBのOAMの仕様)
	add [hl]                 ; table の Xオフセット を加算
	inc e					 ; de = OAMのX
	ld [de], a               ; OAMの X座標に計算した値を書き込む

	inc e					; de = OAMのタイルID

	; a = SpriteFacing${A}And${B}[i] = pattern number offset
	; pattern number offset = animation | orientation
	; animation = 歩きモーション(0x80) or 突っ立っている(0x00)
	; orientation = 0x00 or 0x04 or 0x08
	ld a, [bc]

	; SpriteFacing${A}And${B} の次のエントリへ  
	; 例: bc = SpriteFacingDownAndStanding の $02 のアドレスなら $03 のアドレスへ
	inc bc
	push bc

	; b = SpriteFacing${A}And${B}[i]
	ld b, a

	; a = [c1x2]の上位ニブル = スプライトが使用されているか
	ld a, [wd5cd]            ; a = [c1x2]
	swap a                   ; high nybble determines sprite used (0 is always player sprite, next are some npcs)
	and $f

	; [c1x2] が $aX か $bX のスプライトは 一つの 『顔』 しかもたない (12タイル ではなく 4タイル)
	; 1タイル = 8*8px つまり 12タイル = 4(上向き) + 4(下向き) + 4(左右)
	; As a result, sprite $b's tile offset is less than normal.
	; 従って、$bXのタイルオフセットは通常より小さい

	; $bXでない -> .notFourTileSprite  
	; $aX は .visible で対処済み?
	cp $b
	jr nz, .notFourTileSprite

; .fourTileSprite
	; $bX のとき
	ld a, $a * 12 + 4
	jr .next2

.notFourTileSprite
	; a = 12a = 12 * (c1x2の上位ニブル)
	sla a	; 2a
	sla a	; 4a
	ld c, a	; c = 4a
	sla a	; 8a
	add c	; a = 8a + 4a = 12a

; VRAMオフセット(c1X2の上位ニブル)から求まるスプライトのタイルIDのベース
; VRAMオフセットが [0, a]のとき ベースタイルID = 12 * (c1X2の上位ニブル) = タイル数 * VRAMオフセット
; VRAMオフセットが b のとき ベースタイルID = (12 * 0x0a) + 4 (VRAMオフセットaのスプライトは4タイルしかもたないので)
; つまりこの時点で a = スプライトのベースタイルID

.next2
	add b 	; a = SpriteFacing${A}And${B}[i] (つまり 自分の向いている方向や歩き状態を考慮したオフセットをベースタイルIDに加えている)
	; この時点で a = OAMのタイルID		

	pop bc				; 上の`add b`で加えた `SpriteFacing${A}And${B}[i]` の次のアドレス (つまり SpriteFacing${A}And${B}[i+1])
	
	ld [de], a 			; OAMのタイルIDをセット

	inc hl				; hl = SpriteOAMParameters(or SpriteOAMParametersFlipped) の attr のアドレス
	inc e
	ld a, [hl]

	; attr の OAMFLAG_CANBEMASKED がセットされていない つまり attrをマスクすることを許可していない -> .skipPriority
	bit 1, a
	jr z, .skipPriority
	
	; attr のマスクが可能
	; スプライトが草むらの上なら 最上位ビットを立てるように attr をマスクしたものを a に格納する(|= 0x80)
	ld a, [hSpritePriority]
	or [hl]					; a = ([hSpritePriority] | attr)

.skipPriority
	inc hl			; 次の OAM(8*8px)のための SpriteOAMParameters
	ld [de], a		; attr (もしくは ([hSpritePriority] | attr)) を OAM(wOAMBuffer)に格納
	inc e			; 次の OAM の wOAMBuffer

	; OAMFLAG_ENDOFDATA つまり 今処理中のスプライトが 右下のOAMタイル でない -> .tileLoop
	bit 0, a 		; OAMFLAG_ENDOFDATA
	jr z, .tileLoop
 ; }

	; ここに来た時は 右下の OAMタイル を処理し終えた場合
	; このとき e = 次の [hOAMBufferOffset]
	; なぜなら wOAMBuffer = (8*8pxのOAM 40個分) = (16*16のスプライト 10個分) なので 右下のタイルを終えた時点で 0-10のどれかだから
	; この eを [hOAMBufferOffset] にセットして [hOAMBufferOffset] を次に進める
	ld a, e
	ld [hOAMBufferOffset], a

.nextSprite
	; a = 0x${X}0 -> 0x${X+1}0 (X、現在処理中のスプライトのオフセット)
	ld a, [hSpriteOffset2]
	add $10

	; 16人分のスプライトを処理するまでループ
	; wOAMBuffer は 10人分しかないが picuture IDが 0のスプライトは早々にここにジャンプされるので大丈夫
	cp $100 % $100	; cp 0 -> 0xf0 + 0x10 = 0x00(オーバーフロー)
	jp nz, .spriteLoop
; }

	; 使ってない OAM をクリアする 
	ld a, [hOAMBufferOffset]	; 0xX0 (例: 2人スプライトを処理した場合は 0x20)
	ld l, a
	ld h, wOAMBuffer / $100		; hl = c3X0
	ld de, $4
	ld b, $a0

	; a = 0x90(段差or釣り) or 0xa0(それ以外)
	; Don't clear the last 4 entries because they are used for the shadow in the
	; jumping down ledge animation and the rod in the fishing animation.
	ld a, [wd736]
	bit 6, a 
	ld a, $a0
	jr z, .clear
	ld a, $90

.clear
; {
	; 段差or釣り中なら wOAMBuffer のクリアは 9人分まで(段差釣り中は影のスプライトを最後のスロットに用意してやる必要があるので)
	; それ以外は 10人分 つまり wOAMBufferの最後まで クリアする
	cp l
	ret z

	; クリアする つまり c3XY = 0xa0
	ld [hl], b
	add hl, de
	jr .clear
; }

; **GetSpriteScreenXY**  
; OAMの (16*16px) のグリッド単位での XY座標 を計算する
; - - -  
; wSpriteStateData1 参照
; 
; INPUT:  
; de = 0xc1X2
; 
; OUTPUT:  
; [0xc1Xa], [0xc1Xb] = 計算された Y, X座標  
; [hSpriteScreenX], [hSpriteScreenY] = pixel単位のX, Y座標(c1x6, c1x4)  
GetSpriteScreenXY:

	; [hSpriteScreenY] = [0xc1X4]
	inc e
	inc e
	ld a, [de] ; c1x4
	ld [hSpriteScreenY], a

	; [hSpriteScreenX] = [0xc1X6]
	inc e
	inc e
	ld a, [de] ; c1x6
	ld [hSpriteScreenX], a

	; de = 0xc1Xa
	ld a, 4
	add e
	ld e, a

	; [0xc1Xa] = OAMの (16*16px) のグリッド単位での Y座標
	ld a, [hSpriteScreenY]
	add 4
	and $f0	; and 0b11110000 つまり a /= 16
	ld [de], a ; c1xa (y)

	; [0xc1Xb] = OAMの (16*16px) のグリッド単位での X座標
	inc e
	ld a, [hSpriteScreenX]
	and $f0
	ld [de], a  ; c1xb (x)

	ret
