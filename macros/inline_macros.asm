inline: MACRO
	IF _NARG == 1 
        IF !STRCMP(\1, "[de++] = [hl++]")
            ld a, [hli]
            ld [de], a
            inc de
        ELIF !STRCMP(\1, "[de] = [hl++]")
            ld a, [hli]
            ld [de], a
        ELIF !STRCMP(\1, "[++de] = [hl++]")
            ld a, [hli]
            inc de
            ld [de], a
        ELIF !STRCMP(\1, "[hl++] = [de++]")
            ld a, [de]
            inc de
            ld [hli], a
        ELIF !STRCMP(\1, "hl = [hl]")
            ld a, [hli]
            ld h, [hl]
            ld l, a
        ENDC
	ENDC
ENDM