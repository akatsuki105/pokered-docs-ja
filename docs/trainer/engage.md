# Engage

トレーナーに発見される、自分から話しかけた時に起こる会敵イベントのこと

## トレーナーによる発見

トレーナーは、主人公を発見するとバトルをしかけてくる

発見したかの判定は、Map Scriptの中で `CheckFightingMapTrainers` によって行われている

例としてニビシティジムの Map Scriptを見る

```asm
; Root Map Script
CeruleanGym_Script:
	ld hl, wCurrentMapScriptFlags
	bit 6, [hl]
	res 6, [hl]
	call nz, CeruleanGymScript_5c6d0
	call EnableAutoTextBoxDrawing
	ld hl, CeruleanGymTrainerHeader0
	ld de, CeruleanGym_ScriptPointers
	ld a, [wCeruleanGymCurScript]
	call ExecuteCurMapScriptInTable
	ld [wCeruleanGymCurScript], a
	ret

CeruleanGym_ScriptPointers:
	dw CheckFightingMapTrainers
	dw DisplayEnemyTrainerTextAndStartBattle
	dw EndTrainerBattle
	dw CeruleanGymScript3
```

CheckFightingMapTrainers は 0番目の Map Scriptに紐づけられており、wPewterGymCurScriptが 0 の間は毎フレーム、トレーナーによる発見判定が行われる
