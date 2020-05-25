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

	ld a, $18
	ld [wSpriteStateData1 + $12], a ; make the nurse turn to face the machine
	call Delay3
	predef HealParty
	callba AnimateHealingMachine ; do the healing machine animation
	xor a
	ld [wAudioFadeOutControl], a
	ld a, [wAudioSavedROMBank]
	ld [wAudioROMBank], a
	ld a, [wMapMusicSoundID]
	ld [wLastMusicSoundID], a
	ld [wNewSoundID], a
	call PlaySound
	ld hl, PokemonFightingFitText
	call PrintText
	ld a, $14
	ld [wSpriteStateData1 + $12], a ; make the nurse bow
	ld c, a
	call DelayFrames
	jr .done
.declinedHealing
	call LoadScreenTilesFromBuffer1 ; restore screen
.done
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

; "Thank you! Your #MON are fighting fit!"
PokemonFightingFitText:
	TX_FAR _PokemonFightingFitText
	db "@"

; "We hope to see you again!"
PokemonCenterFarewellText:
	TX_DELAY
	TX_FAR _PokemonCenterFarewellText
	db "@"
