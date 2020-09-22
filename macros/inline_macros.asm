inline: MACRO
	IF _NARG == 1 
        IF !STRCMP(\1, "[de++] = [hl++]")
            ld a, [hli]
            ld [de], a
            inc de
        ELIF !STRCMP(\1, "[++de] = [hl++]")
            ld a, [hli]
            inc de
            ld [de], a
        ENDC
	ENDC
ENDM