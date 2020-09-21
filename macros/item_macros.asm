ifInBattleJP: MACRO
	ld a, [wIsInBattle]
	and a
    jp nz, \1
ENDM

ifInBattleJR: MACRO
	ld a, [wIsInBattle]
	and a
    jr nz, \1
ENDM

ifInFieldJP: MACRO
	ld a, [wIsInBattle]
	and a
    jp z, \1
ENDM

ifInFieldJR: MACRO
	ld a, [wIsInBattle]
	and a
    jr z, \1
ENDM

ifInWildBattle: MACRO
	ld a, [wIsInBattle]
	dec a
	jr z, \1
ENDM

ifNotInWildBattle: MACRO
	ld a, [wIsInBattle]
	dec a
	jp nz, \1
ENDM