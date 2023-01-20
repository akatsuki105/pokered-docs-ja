; **ApplyOutOfBattlePoisonDamage**  
; マップ上で歩いているときに毒ダメージを与える処理  
; - - -  
; OUTPUT: a = 0xff(毒ダメージでパーティが全滅) or 0x00(何もなし)
ApplyOutOfBattlePoisonDamage:
	; a[7] = 1 -> .noBlackOut
	ld a, [wd730]
	add a
	jp c, .noBlackOut ; no black out if joypad states are being simulated

	; パーティのポケモン数が0(オーキドからポケモンをもらっていない) -> .noBlackOut
	ld a, [wPartyCount]
	and a
	jp z, .noBlackOut

	call IncrementDayCareMonExp

	; [wStepCounter]が0より大きい -> .noBlackOut
	ld a, [wStepCounter]
	and $3
	jp nz, .noBlackOut

	; ここ以降の処理は[wStepCounter]が0のとき、つまり4歩ごとにしか毒ダメージの処理は実行されない
	ld [wWhichPokemon], a
	ld hl, wPartyMon1Status
	ld de, wPartySpecies

	; パーティのポケモンを1匹ずつ見ていって処理をする
.applyDamageLoop
	; 毒状態じゃない -> .nextMon2
	ld a, [hl]
	and (1 << PSN)
	jr z, .nextMon2

	; hl = wPartyMon1HP
	dec hl
	dec hl

	; HP=0 つまり ひん死 -> .nextMon
	ld a, [hld]
	ld b, a
	ld a, [hli]	; hl = HPの下位バイト
	or b
	jr z, .nextMon

	; HPから1引く処理
	; HPの下位バイトから1引く
	ld a, [hl]
	dec a
	; 1引く前のHPの下位バイトが0より大きい -> .noBorrow
	ld [hld], a
	inc a
	jr nz, .noBorrow
	; 1引く前のHPの下位バイトが0だったときは上位バイトを1減らして -> .nextMon
	dec [hl]
	inc hl ; hl = wPartyMon1HP[1]
	jr .nextMon

.noBorrow
	; 毒ダメージを食らったがひん死になってはいない -> .nextMon
	ld a, [hli]
	or [hl]
	jr nz, .nextMon

	; 毒ダメージでひん死になった(a = 0) 
	
	push hl ; hl = wPartyMon1HP[1]

	; [wPartyMon1Status] = 0
	inc hl
	inc hl
	ld [hl], a

	; [wd11e] = [wPartySpecies]
	ld a, [de]
	ld [wd11e], a

	push de ; de = wPartySpecies
	
	; [wcd6d] = ひん死になったポケモンのニックネーム
	ld a, [wWhichPokemon]
	ld hl, wPartyMonNicks
	call GetPartyMonName

	; すべてのキー入力を無効に
	xor a
	ld [wJoyIgnore], a

	call EnableAutoTextBoxDrawing
	
	; "<POKEMON> fainted!"というテキストを表示する
	ld a, TEXT_MON_FAINTED
	ld [hSpriteIndexOrTextID], a
	call DisplayTextID

	pop de
	pop hl
.nextMon
	inc hl
	inc hl ; hl = wPartyMon${N}Status
.nextMon2
	; [wPartySpecies+1] == 0xff -> パーティを全部見た -> .applyDamageLoopDone
	inc de
	ld a, [de]
	inc a
	jr z, .applyDamageLoopDone

	; hl = wPartyMon${N+1}Status
	ld bc, wPartyMon2 - wPartyMon1
	add hl, bc
	push hl

	; [wWhichPokemon]++
	ld hl, wWhichPokemon
	inc [hl]

	pop hl

	jr .applyDamageLoop ; 次のポケモンへ
	
.applyDamageLoopDone
	ld hl, wPartyMon1Status
	ld a, [wPartyCount]
	ld d, a ; d = [wPartyCount]
	ld e, 0
.countPoisonedLoop
	; e = パーティのだれかが毒状態なら e > 0
	ld a, [hl]
	and (1 << PSN)
	or e
	ld e, a

	; hl = wPartyMon${N}Status -> wPartyMon${N+1}Status
	ld bc, wPartyMon2 - wPartyMon1
	add hl, bc

	; パーティを全部見た
	dec d
	jr nz, .countPoisonedLoop

	; だれも毒状態になっていない -> .skipPoisonEffectAndSound
	ld a, e
	and a ; are any party members poisoned?
	jr z, .skipPoisonEffectAndSound

	; だれかが毒状態のとき
	; 毒のエフェクト(画面フラッシュ&サウンド)を出す
	ld b, $2
	predef ChangeBGPalColor0_4Frames ; change BG white to dark grey for 4 frames
	ld a, SFX_POISONED
	call PlaySound

.skipPoisonEffectAndSound
	; パーティにひん死でないポケモンがいる -> .noBlackOut 
	predef AnyPartyAlive
	ld a, d
	and a
	jr nz, .noBlackOut

	; パーティが全員ひん死 なので『めのまえが まっくらに なった！』処理をする
	call EnableAutoTextBoxDrawing
	ld a, TEXT_BLACKED_OUT
	ld [hSpriteIndexOrTextID], a
	call DisplayTextID

	; wd72e[5] = 1
	ld hl, wd72e
	set 5, [hl]

	ld a, $ff
	jr .done
.noBlackOut
	xor a
.done
	ld [wOutOfBattleBlackout], a ; a = 0xff(全滅) or 0x00(生存)
	ret
