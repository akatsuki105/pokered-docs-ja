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

ifInBattle: MACRO
	ld a, [wIsInBattle]
	and a
    
    IF \1 == OP_JP
		jp nz, \2
	ENDC
	IF \1 == OP_JR
		jr nz, \2
	ENDC
	IF \1 == OP_CALL
		call nz, \2
	ENDC
ENDM

; Field

ifInField: MACRO
	ld a, [wIsInBattle]
	and a

    IF \1 == OP_JP
		jp z, \2
	ENDC
	IF \1 == OP_JR
		jr z, \2
	ENDC
	IF \1 == OP_CALL
		call z, \2
	ENDC
ENDM

ifInWildBattle: MACRO
	ld a, [wIsInBattle]
	dec a

    IF \1 == OP_JP
		jp z, \2
	ENDC
	IF \1 == OP_JR
		jr z, \2
	ENDC
	IF \1 == OP_CALL
		call z, \2
	ENDC
ENDM

ifNotInWildBattle: MACRO
	ld a, [wIsInBattle]
	dec a
    IF \1 == OP_JP
		jp nz, \2
	ENDC
	IF \1 == OP_JR
		jr nz, \2
	ENDC
	IF \1 == OP_CALL
		call nz, \2
	ENDC
ENDM

ifInTrainerBattle: MACRO
	ld a, [wIsInBattle]
	cp $2
	IF \1 == OP_JP
		jp z, \2
	ENDC
	IF \1 == OP_JR
		jr z, \2
	ENDC
	IF \1 == OP_CALL
		call z, \2
	ENDC
ENDM

ifNotInTrainerBattle: MACRO
	ld a, [wIsInBattle]
	cp $2
	IF \1 == OP_JP
		jp nz, \2
	ENDC
	IF \1 == OP_JR
		jr nz, \2
	ENDC
	IF \1 == OP_CALL
		call nz, \2
	ENDC
ENDM