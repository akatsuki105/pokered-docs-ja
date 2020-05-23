; **AnimateHealingMachine**  
; 回復マシンの稼働アニメーションを流す関数
AnimateHealingMachine:
	; 回復マシンの稼働アニメーションを流す
	ld de, PokeCenterFlashingMonitorAndHealBall
	ld hl, vChars0 + $7c0
	lb bc, BANK(PokeCenterFlashingMonitorAndHealBall), $03 ; loads one too many tiles
	call CopyVideoData

	; スプライトを無効化
	ld hl, wUpdateSpritesEnabled
	ld a, [hl]
	push af ; stack_depth = 0 => [wUpdateSpritesEnabled]をpush
	ld [hl], $ff
	push hl ; stack_depth = 1 => wUpdateSpritesEnabledをpush

	; [rOBP1] = $e0 = 11 10 00 00
	ld a, [rOBP1]
	push af ; stack_depth = 2 => [rOBP1]をpush
	ld a, $e0
	ld [rOBP1], a

	; 回復時のスプライト(今はモニターだけ)を表示する
	ld hl, wOAMBuffer + $84
	ld de, PokeCenterOAMData
	call CopyHealingMachineOAM

	; BGMの再生を止める
	ld a, 4
	ld [wAudioFadeOutControl], a
	ld a, $ff
	ld [wNewSoundID], a
	call PlaySound

	; 現在のBGM(ポケセンのBGM)が止まるまで待つ
.waitLoop
	ld a, [wAudioFadeOutControl]
	and a ; is fade-out finished?
	jr nz, .waitLoop ; if not, check again

	; パーティのポケモン数だけモンスターボールを回復マシンに設置するアニメーションを再生 
	ld a, [wPartyCount]
	ld b, a
.partyLoop
	call CopyHealingMachineOAM
	ld a, SFX_HEALING_MACHINE
	call PlaySound
	ld c, 30
	call DelayFrames
	dec b
	jr nz, .partyLoop

	; ?
	ld a, [wAudioROMBank]
	cp BANK(Audio3_UpdateMusic)
	ld [wAudioSavedROMBank], a
	jr nz, .next

	; BGMの再生を止める
	ld a, $ff
	ld [wNewSoundID], a
	call PlaySound

	; 回復音を鳴らす
	ld a, BANK(Music_PkmnHealed)
	ld [wAudioROMBank], a
.next
	ld a, MUSIC_PKMN_HEALED
	ld [wNewSoundID], a
	call PlaySound

	; 回復中のマシン点滅処理
	ld d, $28
	call FlashSprite8Times

	; 回復音の再生が終わるのを待つ
.waitLoop2
	ld a, [wChannelSoundIDs]
	cp MUSIC_PKMN_HEALED ; is the healed music still playing?
	jr z, .waitLoop2 ; if so, check gain

	ld c, 32
	call DelayFrames

	; [rOBP1]を復帰
	pop af ; stack_depth = 2 => [rOBP1]をpop
	ld [rOBP1], a
	; [wUpdateSpritesEnabled]を復帰
	pop hl ; stack_depth = 1 => hl = wUpdateSpritesEnabled
	pop af ; stack_depth = 0 => a = [wUpdateSpritesEnabled]
	ld [hl], a
	jp UpdateSprites ; スプライトの状態をもとに戻す

PokeCenterFlashingMonitorAndHealBall:
	INCBIN "gfx/pokecenter_ball.2bpp"

PokeCenterOAMData:
	db $24,$34,$7C,$10 ; heal machine monitor
	db $2B,$30,$7D,$10 ; pokeballs 1-6
	db $2B,$38,$7D,$30
	db $30,$30,$7D,$10
	db $30,$38,$7D,$30
	db $35,$30,$7D,$10
	db $35,$38,$7D,$30

; **FlashSprite8Times**  
; スプライトを8回点滅させる  
; - - -
; 点滅のバリエーションは[rOBP1]、dの値に依存する  
; INPUT: d = [rOBP1]とxorさせる値
FlashSprite8Times:
	ld b, 8

.loop
	; [rOBP1] = [rOBP1] xor d
	ld a, [rOBP1]
	xor d
	ld [rOBP1], a

	; 10フレーム遅延
	ld c, 10
	call DelayFrames
	
	dec b
	jr nz, .loop
	
	ret

; copy one OAM entry and advance the pointers
; 
; INPUT:  
; - hl = コピー先
; - de = コピー元
; 
; OUTPUT:
; - hl = hl + 4
; - de = de + 4
CopyHealingMachineOAM:
	; [hl++] = [de++]
	ld a, [de]
	inc de
	ld [hli], a

	; [hl++] = [de++]
	ld a, [de]
	inc de
	ld [hli], a
	
	; [hl++] = [de++]
	ld a, [de]
	inc de
	ld [hli], a

	; [hl++] = [de++]
	ld a, [de]
	inc de
	ld [hli], a
	ret
