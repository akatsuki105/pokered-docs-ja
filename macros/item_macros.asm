OP_JP    EQU 0
OP_JR    EQU 1
OP_CALL    EQU 2

; Battle

jpIfInBattle: MACRO
	ld a, [wIsInBattle]
	and a
    jp nz, \1
ENDM

jrIfInBattle: MACRO
	ld a, [wIsInBattle]
	and a
    jr nz, \1
ENDM

callIfInBattle: MACRO
	ld a, [wIsInBattle]
	and a
    call nz, \1
ENDM

retIfInBattle: MACRO
	ld a, [wIsInBattle]
	and a
    ret nz, \1
ENDM

; Field

jpIfInField: MACRO
	ld a, [wIsInBattle]
	and a
    jp z, \1
ENDM

jrIfInField: MACRO
	ld a, [wIsInBattle]
	and a
    jr z, \1
ENDM

callIfInField: MACRO
	ld a, [wIsInBattle]
	and a
    call z, \1
ENDM

retIfInField: MACRO
	ld a, [wIsInBattle]
	and a
    ret z, \1
ENDM

; Wild battle

jpIfInWildBattle: MACRO
	ld a, [wIsInBattle]
	dec a
    jp z, \1
ENDM

jrIfInWildBattle: MACRO
	ld a, [wIsInBattle]
	dec a
    jr z, \1
ENDM

callIfInWildBattle: MACRO
	ld a, [wIsInBattle]
	dec a
    call z, \1
ENDM

retIfInWildBattle: MACRO
	ld a, [wIsInBattle]
	dec a
    ret z, \1
ENDM

; Not wild battle

jpNotIfInWildBattle: MACRO
	ld a, [wIsInBattle]
	dec a
    jp nz, \1
ENDM

jrNotIfInWildBattle: MACRO
	ld a, [wIsInBattle]
	dec a
    jr nz, \1
ENDM

callNotIfInWildBattle: MACRO
	ld a, [wIsInBattle]
	dec a
    call nz, \1
ENDM

retNotIfInWildBattle: MACRO
	ld a, [wIsInBattle]
	dec a
    ret nz, \1
ENDM

; Trainer battle

jpIfInTrainerBattle: MACRO
	ld a, [wIsInBattle]
	cp $2
    jp z, \1
ENDM

jrIfInTrainerBattle: MACRO
	ld a, [wIsInBattle]
	cp $2
    jr z, \1
ENDM

callIfInTrainerBattle: MACRO
	ld a, [wIsInBattle]
	cp $2
    call z, \1
ENDM

retIfInTrainerBattle: MACRO
	ld a, [wIsInBattle]
	cp $2
    ret z, \1
ENDM

; Not traner battle

jpNotIfInTrainerBattle: MACRO
	ld a, [wIsInBattle]
	cp $2
    jp nz, \1
ENDM

jrNotIfInTrainerBattle: MACRO
	ld a, [wIsInBattle]
	cp $2
    jr nz, \1
ENDM

callNotIfInTrainerBattle: MACRO
	ld a, [wIsInBattle]
	cp $2
    call nz, \1
ENDM

retNotIfInTrainerBattle: MACRO
	ld a, [wIsInBattle]
	cp $2
    ret nz, \1
ENDM
