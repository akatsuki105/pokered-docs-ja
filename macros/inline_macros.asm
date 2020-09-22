inline: MACRO
	IF _NARG == 1 
        IF \1 == "[de++] = [hl++]"
            ld a, [hli]
            ld [de], a
            inc de
        ELSE
            IF \1 == "[++de] = [hl++]"
                ld a, [hli]
                inc de
                ld [de], a
            ENDC
        ENDC
	ENDC
ENDM