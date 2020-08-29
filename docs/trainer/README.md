# トレーナー

## Trainer Header

```asm
TrainerHeaderLabel:
	dbEventFlagBit EVENT_BEAT_CELADON_GYM_TRAINER_0
	db ($2 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_CELADON_GYM_TRAINER_0
	dw CeladonGymBattleText2 ; TextBeforeBattle
	dw CeladonGymAfterBattleText2 ; TextAfterBattle
	dw CeladonGymEndBattleText2 ; TextEndBattle
	dw CeladonGymEndBattleText2 ; TextEndBattle
```

```asm
; scripts/CeladonGym.asm

CeladonGymTrainerHeader0:
	dbEventFlagBit EVENT_BEAT_CELADON_GYM_TRAINER_0
	db ($2 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_CELADON_GYM_TRAINER_0
	dw CeladonGymBattleText2 ; TextBeforeBattle
	dw CeladonGymAfterBattleText2 ; TextAfterBattle
	dw CeladonGymEndBattleText2 ; TextEndBattle
	dw CeladonGymEndBattleText2 ; TextEndBattle

CeladonGymTrainerHeader1:
	dbEventFlagBit EVENT_BEAT_CELADON_GYM_TRAINER_1
	db ($2 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_CELADON_GYM_TRAINER_1
	dw CeladonGymBattleText3 ; TextBeforeBattle
	dw CeladonGymAfterBattleText3 ; TextAfterBattle
	dw CeladonGymEndBattleText3 ; TextEndBattle
	dw CeladonGymEndBattleText3 ; TextEndBattle

CeladonGymTrainerHeader2:
	dbEventFlagBit EVENT_BEAT_CELADON_GYM_TRAINER_2
	db ($4 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_CELADON_GYM_TRAINER_2
	dw CeladonGymBattleText4 ; TextBeforeBattle
	dw CeladonGymAfterBattleText4 ; TextAfterBattle
	dw CeladonGymEndBattleText4 ; TextEndBattle
	dw CeladonGymEndBattleText4 ; TextEndBattle

CeladonGymTrainerHeader3:
	dbEventFlagBit EVENT_BEAT_CELADON_GYM_TRAINER_3
	db ($4 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_CELADON_GYM_TRAINER_3
	dw CeladonGymBattleText5 ; TextBeforeBattle
	dw CeladonGymAfterBattleText5 ; TextAfterBattle
	dw CeladonGymEndBattleText5 ; TextEndBattle
	dw CeladonGymEndBattleText5 ; TextEndBattle

CeladonGymTrainerHeader4:
	dbEventFlagBit EVENT_BEAT_CELADON_GYM_TRAINER_4
	db ($2 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_CELADON_GYM_TRAINER_4
	dw CeladonGymBattleText6 ; TextBeforeBattle
	dw CeladonGymAfterBattleText6 ; TextAfterBattle
	dw CeladonGymEndBattleText6 ; TextEndBattle
	dw CeladonGymEndBattleText6 ; TextEndBattle

CeladonGymTrainerHeader5:
	dbEventFlagBit EVENT_BEAT_CELADON_GYM_TRAINER_5
	db ($2 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_CELADON_GYM_TRAINER_5
	dw CeladonGymBattleText7 ; TextBeforeBattle
	dw CeladonGymAfterBattleText7 ; TextAfterBattle
	dw CeladonGymEndBattleText7 ; TextEndBattle
	dw CeladonGymEndBattleText7 ; TextEndBattle

CeladonGymTrainerHeader6:
	dbEventFlagBit EVENT_BEAT_CELADON_GYM_TRAINER_6, 1
	db ($3 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_CELADON_GYM_TRAINER_6, 1
	dw CeladonGymBattleText8 ; TextBeforeBattle
	dw CeladonGymAfterBattleText8 ; TextAfterBattle
	dw CeladonGymEndBattleText8 ; TextEndBattle
	dw CeladonGymEndBattleText8 ; TextEndBattle

	db $ff
```