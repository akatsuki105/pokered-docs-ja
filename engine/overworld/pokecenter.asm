DisplayPokemonCenterDialogue_:
	call SaveScreenTilesToBuffer1 ; save screen

	; 『ようこそ！ ポケモンセンターへ ここでは ポケモンの たいりょくを かいふくを いたします』
	ld hl, PokemonCenterWelcomeText
	call PrintText

	; ポケモンセンター利用フラグを立てる
	ld hl, wd72e
	bit 2, [hl]
	set 1, [hl]
	set 2, [hl]
	; ???
	jr nz, .skipShallWeHealYourPokemon

	; "Shall we heal your #MON?"
	ld hl, ShallWeHealYourPokemonText
	call PrintText

.skipShallWeHealYourPokemon
	; あずける/やめる
	call YesNoChoicePokeCenter
	
	; やめる -> .declinedHealing
	ld a, [wCurrentMenuItem]
	and a
	jr nz, .declinedHealing

	; あずける

	; パーティが全滅したときに戻される場所をこのポケモンセンターに設定
	call SetLastBlackoutMap

	; 『それでは あずからせて いただきます！』
	call LoadScreenTilesFromBuffer1 ; restore screen
	ld hl, NeedYourPokemonText
	call PrintText

	; 稼働アニメーションを流してポケモンの回復処理を行う
	ld a, $18
	ld [wSpriteStateData1 + $12], a ; make the nurse turn to face the machine
	call Delay3
	predef HealParty
	callba AnimateHealingMachine ; do the healing machine animation

	; ポケモンセンターのBGMに戻す(回復アニメーションでBGMが変わるので)
	xor a
	ld [wAudioFadeOutControl], a
	ld a, [wAudioSavedROMBank]
	ld [wAudioROMBank], a
	ld a, [wMapMusicSoundID]
	ld [wLastMusicSoundID], a
	ld [wNewSoundID], a
	call PlaySound

	; 『おまちどうさまでした！ おあずかりした ポケモンは みんな げんきに なりましたよ！』
	ld hl, PokemonFightingFitText
	call PrintText
	
	; ジョーイさんにお辞儀をさせる
	ld a, $14
	ld [wSpriteStateData1 + $12], a ; make the nurse bow
	ld c, a
	call DelayFrames

	jr .done
.declinedHealing
	call LoadScreenTilesFromBuffer1 ; restore screen
.done
	; 『またの ごりようを おまちしてます！』
	ld hl, PokemonCenterFarewellText
	call PrintText
	jp UpdateSprites

; 『ようこそ！ ポケモンセンターへ ここでは ポケモンの たいりょくを かいふくを いたします』  
; "Welcome to our #MON CENTER! We heal your #MON back to perfect health!"
PokemonCenterWelcomeText:
	TX_FAR _PokemonCenterWelcomeText
	db "@"

; "Shall we heal your #MON?"
ShallWeHealYourPokemonText:
	TX_DELAY
	TX_FAR _ShallWeHealYourPokemonText
	db "@"

; 『それでは あずからせて いただきます！』  
; "OK. We'll need your #MON."
NeedYourPokemonText:
	TX_FAR _NeedYourPokemonText
	db "@"

; 『おまちどうさまでした！ おあずかりした ポケモンは みんな げんきに なりましたよ！』  
; "Thank you! Your #MON are fighting fit!"
PokemonFightingFitText:
	TX_FAR _PokemonFightingFitText
	db "@"

; 『またの ごりようを おまちしてます！』  
; "We hope to see you again!"
PokemonCenterFarewellText:
	TX_DELAY
	TX_FAR _PokemonCenterFarewellText
	db "@"
