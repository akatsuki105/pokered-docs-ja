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
    ret nz
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
    ret z
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
    ret z
ENDM

; Not wild battle

jpIfNotInWildBattle: MACRO
	ld a, [wIsInBattle]
	dec a
    jp nz, \1
ENDM

jrIfNotInWildBattle: MACRO
	ld a, [wIsInBattle]
	dec a
    jr nz, \1
ENDM

callIfNotInWildBattle: MACRO
	ld a, [wIsInBattle]
	dec a
    call nz, \1
ENDM

retIfNotInWildBattle: MACRO
	ld a, [wIsInBattle]
	dec a
    ret nz
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
    ret z
ENDM

; Not traner battle

jpIfNotInTrainerBattle: MACRO
	ld a, [wIsInBattle]
	cp $2
    jp nz, \1
ENDM

jrIfNotInTrainerBattle: MACRO
	ld a, [wIsInBattle]
	cp $2
    jr nz, \1
ENDM

callIfNotInTrainerBattle: MACRO
	ld a, [wIsInBattle]
	cp $2
    call nz, \1
ENDM

retIfNotInTrainerBattle: MACRO
	ld a, [wIsInBattle]
	cp $2
    ret nz
ENDM

; Lost battle

jpIfInLostBattle: MACRO
	ld a, [wIsInBattle]
	cp $ff
    jp z, \1
ENDM