; 手持ちのポケモンのHPバーの色を黄色扱いにして GetAnimationSpeed に続く
AnimatePartyMon_ForceSpeed1:
	xor a
	ld [wCurrentMenuItem], a
	ld b, a
	inc a
	jr GetAnimationSpeed

; [wCurrentMenuItem]が指す手持ちのポケモンのHPバーの色を格納して GetAnimationSpeed に続く
AnimatePartyMon:
	ld hl, wPartyMenuHPBarColors
	ld a, [wCurrentMenuItem]
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [hl] ; a = [wCurrentMenuItem]が指す手持ちのポケモンのHPバーの色 0(green) or 1(yellow) or 2(red) 

; **GetAnimationSpeed**  
; ポケモンのアイコンのアニメーション処理を行う  
; - - -  
; INPUT: a = ポケモンのHPバーの色 0(green) or 1(yellow) or 2(red) 
GetAnimationSpeed:
	; hl = アニメーション間隔を指すアドレス
	ld c, a
	ld hl, PartyMonSpeeds
	add hl, bc

	; a = 0(SGB) or 1(SGBでない)
	ld a, [wOnSGB]
	xor $1

	; a = c = アニメーション間隔
	add [hl]
	ld c, a
	; b = ???
	add a
	ld b, a
	
; [wAnimCounter] == 0 -> .resetSprites
	ld a, [wAnimCounter]
	and a
	jr z, .resetSprites
; [wAnimCounter] == c -> .animateSprite
	cp c
	jr z, .animateSprite
; それ以外のとき [wAnimCounter]をインクリメントする
.incTimer
	inc a
	cp b
	jr nz, .skipResetTimer
	xor a ; reset timer
.skipResetTimer
	ld [wAnimCounter], a
	jp DelayFrame

; OAMアニメーションを最初に戻す
.resetSprites
	push bc
	ld hl, wMonPartySpritesSavedOAM
	ld de, wOAMBuffer
	ld bc, $60
	call CopyData
	pop bc
	xor a
	jr .incTimer

.animateSprite
	push bc
	; hl = 対象のポケモンのアイコンのアドレス
	ld hl, wOAMBuffer + $02 ; OAMは各4byteで2バイト目はタイル番号を指す
	ld bc, $10				; 各ポケモンアイコンは 16*16pxなので スプライト4枚分 = 4*4 = 0x10
	ld a, [wCurrentMenuItem]
	call AddNTimes

	ld c, $40 ; amount to increase the tile id by

; アイコンのスプライトが SPRITE_BALL_M or SPRITE_HELIX -> .editCoords
; それ以外 -> .editTileIDS
	ld a, [hl]
	cp $4 ; tile ID for SPRITE_BALL_M
	jr z, .editCoords
	cp $8 ; tile ID for SPRITE_HELIX
	jr nz, .editTileIDS

; アイコンが ボール(SPRITE_BALL_M) または アンモナイト?(SPRITE_HELIX)のときは アニメーションは上下に座標をずらすだけ
.editCoords
	dec hl
	dec hl ; dec hl to the OAM y coord
	ld c, $1 ; amount to increase the y coord by
; それ以外は、2枚目のスプライトアイコンを読み込む
.editTileIDS
	ld b, $4	; アイコンは16*16pxなので 8*8が4枚?
	ld de, $4 	; 各OAM = 4バイト
; 4回(b=4)ループする
.loop
	ld a, [hl]
	add c		; y座標　+= 1 or スプライトのタイル番号 += 40
	ld [hl], a
	add hl, de
	dec b
	jr nz, .loop

	pop bc
	ld a, c
	jr .incTimer

; **PartyMonSpeeds**  
; ポケモンのアイコンのアニメーションスピード
; - - -  
; 手持ちのポケモンのアイコンのアニメーションは2フレームの間をループしている  
; 配列 PartyMonSpeeds の要素は 緑のHP、黄色のHP、赤のHPの順に各フレームが持続するVBlankの回数を指定している  
; ポケモンのニックネームをつける際にもポケモンのアイコンのアニメーションが映し出されるが、このときは常に黄色のHPと同じアニメーションスピードになる  
; 
; db 5, 16, 32 green,yellow,red
PartyMonSpeeds:
	db 5, 16, 32

; パーティを構成するポケモンのスプライトをVBlank中にVRAMに転送する
LoadMonPartySpriteGfx:
	ld hl, MonPartySpritePointers
	ld a, $1c

LoadAnimSpriteGfx:
; Load animated sprite tile patterns into VRAM during V-blank. hl is the address
; of an array of structures that contain arguments for CopyVideoData and a is
; the number of structures in the array.
	ld bc, $0
.loop
	push af
	push bc
	push hl
	add hl, bc
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld b, a
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call CopyVideoData
	pop hl
	pop bc
	ld a, $6
	add c
	ld c, a
	pop af
	dec a
	jr nz, .loop
	ret

; **LoadMonPartySpriteGfxWithLCDDisabled**  
; LCDを無効化して、ポケモンのSDアイコンの2bppデータをVRAMに転送する  
; - - -  
; プレイヤーの手持ちのポケモンにかかわらず全種類のSDアイコンを転送する
LoadMonPartySpriteGfxWithLCDDisabled:
	call DisableLCD
	ld hl, MonPartySpritePointers
	ld a, $1c
	ld bc, $0
	
; MonPartySpritePointers のエントリ通りに転送を行っていく
.loop
; {
	push af
	push bc
	push hl

	add hl, bc

	; push ROM内の2bppデータのアドレス
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	push de

	; bc = 2bppデータのバイト長
	ld a, [hli]
	ld c, a
	swap c
	ld b, $0

	; a = バンク番号
	ld a, [hli]

	; de = 転送先のVRAMアドレス
	ld e, [hl]
	inc hl
	ld d, [hl]

	; hl = ROM内の2bppデータのアドレス
	pop hl

	call FarCopyData2

	pop hl
	pop bc

	; 次のSDアイコンへ
	ld a, $6
	add c
	ld c, a
	pop af
	dec a
	jr nz, .loop
; }
	
	; 最後に LCDを戻す
	jp EnableLCD	; return

; **MonPartySpritePointers**  
; ポケモンのSDアイコンのテーブル  
MonPartySpritePointers:
	dw SlowbroSprite + $c0	; from
	db $40 / $10 			; size(40 bytes)
	db BANK(SlowbroSprite)	; bank
	dw vSprites				; dest

	dw BallSprite
	db $80 / $10 ; $80 bytes
	db BANK(BallSprite)
	dw vSprites + $40

	dw ClefairySprite + $c0
	db $40 / $10 ; $40 bytes
	db BANK(ClefairySprite)
	dw vSprites + $c0

	dw BirdSprite + $c0
	db $40 / $10 ; $40 bytes
	db BANK(BirdSprite)
	dw vSprites + $100

	dw SeelSprite
	db $40 / $10 ; $40 bytes
	db BANK(SeelSprite)
	dw vSprites + $140

	dw MonPartySprites + $40
	db $10 / $10 ; $10 bytes
	db BANK(MonPartySprites)
	dw vSprites + $180

	dw MonPartySprites + $50
	db $10 / $10 ; $10 bytes
	db BANK(MonPartySprites)
	dw vSprites + $1a0

	dw MonPartySprites + $60
	db $10 / $10 ; $10 bytes
	db BANK(MonPartySprites)
	dw vSprites + $1c0

	dw MonPartySprites + $70
	db $10 / $10 ; $10 bytes
	db BANK(MonPartySprites)
	dw vSprites + $1e0

	dw MonPartySprites + $80
	db $10 / $10 ; $10 bytes
	db BANK(MonPartySprites)
	dw vSprites + $200

	dw MonPartySprites + $90
	db $10 / $10 ; $10 bytes
	db BANK(MonPartySprites)
	dw vSprites + $220

	dw MonPartySprites + $A0
	db $10 / $10 ; $10 bytes
	db BANK(MonPartySprites)
	dw vSprites + $240

	dw MonPartySprites + $B0
	db $10 / $10 ; $10 bytes
	db BANK(MonPartySprites)
	dw vSprites + $260

	dw MonPartySprites + $100
	db $40 / $10 ; $40 bytes
	db BANK(MonPartySprites)
	dw vSprites + $380

	dw SlowbroSprite
	db $40 / $10 ; $40 bytes
	db BANK(SlowbroSprite)
	dw vSprites + $400

	dw BallSprite
	db $80 / $10 ; $80 bytes
	db BANK(BallSprite)
	dw vSprites + $440

	dw ClefairySprite
	db $40 / $10 ; $40 bytes
	db BANK(ClefairySprite)
	dw vSprites + $4c0

	dw BirdSprite
	db $40 / $10 ; $40 bytes
	db BANK(BirdSprite)
	dw vSprites + $500

	dw SeelSprite + $C0
	db $40 / $10 ; $40 bytes
	db BANK(SeelSprite)
	dw vSprites + $540

	dw MonPartySprites
	db $10 / $10 ; $10 bytes
	db BANK(MonPartySprites)
	dw vSprites + $580

	dw MonPartySprites + $10
	db $10 / $10 ; $10 bytes
	db BANK(MonPartySprites)
	dw vSprites + $5a0

	dw MonPartySprites + $20
	db $10 / $10 ; $10 bytes
	db BANK(MonPartySprites)
	dw vSprites + $5c0

	dw MonPartySprites + $30
	db $10 / $10 ; $10 bytes
	db BANK(MonPartySprites)
	dw vSprites + $5E0

	dw MonPartySprites + $C0
	db $10 / $10 ; $10 bytes
	db BANK(MonPartySprites)
	dw vSprites + $600

	dw MonPartySprites + $D0
	db $10 / $10 ; $10 bytes
	db BANK(MonPartySprites)
	dw vSprites + $620

	dw MonPartySprites + $E0
	db $10 / $10 ; $10 bytes
	db BANK(MonPartySprites)
	dw vSprites + $640

	dw MonPartySprites + $F0
	db $10 / $10 ; $10 bytes
	db BANK(MonPartySprites)
	dw vSprites + $660

	dw MonPartySprites + $140
	db $40 / $10 ; $40 bytes
	db BANK(MonPartySprites)
	dw vSprites + $780

WriteMonPartySpriteOAMByPartyIndex:
; Write OAM blocks for the party mon in [hPartyMonIndex].
	push hl
	push de
	push bc
	ld a, [hPartyMonIndex]
	ld hl, wPartySpecies
	ld e, a
	ld d, 0
	add hl, de
	ld a, [hl]
	call GetPartyMonSpriteID
	ld [wOAMBaseTile], a
	call WriteMonPartySpriteOAM
	pop bc
	pop de
	pop hl
	ret

WriteMonPartySpriteOAMBySpecies:
; Write OAM blocks for the party sprite of the species in
; [wMonPartySpriteSpecies].
	xor a
	ld [hPartyMonIndex], a
	ld a, [wMonPartySpriteSpecies]
	call GetPartyMonSpriteID
	ld [wOAMBaseTile], a
	jr WriteMonPartySpriteOAM

UnusedPartyMonSpriteFunction:
; This function is unused and doesn't appear to do anything useful. It looks
; like it may have been intended to load the tile patterns and OAM data for
; the mon party sprite associated with the species in [wcf91].
; However, its calculations are off and it loads garbage data.
	ld a, [wcf91]
	call GetPartyMonSpriteID
	push af
	ld hl, vSprites
	call .LoadTilePatterns
	pop af
	add $54
	ld hl, vSprites + $40
	call .LoadTilePatterns
	xor a
	ld [wMonPartySpriteSpecies], a
	jr WriteMonPartySpriteOAMBySpecies

.LoadTilePatterns
	push hl
	add a
	ld c, a
	ld b, 0
	ld hl, MonPartySpritePointers
	add hl, bc
	add hl, bc
	add hl, bc
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld b, a
	pop hl
	jp CopyVideoData

WriteMonPartySpriteOAM:
; Write the OAM blocks for the first animation frame into the OAM buffer and
; make a copy at wMonPartySpritesSavedOAM.
	push af
	ld c, $10
	ld h, wOAMBuffer / $100
	ld a, [hPartyMonIndex]
	swap a
	ld l, a
	add $10
	ld b, a
	pop af
	cp SPRITE_HELIX << 2
	jr z, .helix
	call WriteSymmetricMonPartySpriteOAM
	jr .makeCopy
.helix
	call WriteAsymmetricMonPartySpriteOAM
; Make a copy of the OAM buffer with the first animation frame written so that
; we can flip back to it from the second frame by copying it back.
.makeCopy
	ld hl, wOAMBuffer
	ld de, wMonPartySpritesSavedOAM
	ld bc, $60
	jp CopyData

GetPartyMonSpriteID:
	ld [wd11e], a
	predef IndexToPokedex
	ld a, [wd11e]
	ld c, a
	dec a
	srl a
	ld hl, MonPartyData
	ld e, a
	ld d, 0
	add hl, de
	ld a, [hl]
	bit 0, c
	jr nz, .skipSwap
	swap a ; use lower nybble if pokedex num is even
.skipSwap
	and $f0
	srl a
	srl a
	ret

INCLUDE "data/mon_party_sprites.asm"

MonPartySprites:
	INCBIN "gfx/mon_ow_sprites.2bpp"
