inline: MACRO
	IF _NARG == 1 
        IF \1 == "[de++] = [hl++]"
            ld a, [hli]
            ld [de], a
            inc de
        ENDC
	ENDC
ENDM