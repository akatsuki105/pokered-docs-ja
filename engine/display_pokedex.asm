; INPUT: [wd11e] = ポケモンID
_DisplayPokedex:
	; 図鑑はテキストを一気に表示
	ld hl, wd730
	set 6, [hl]
	predef ShowPokedexData
	ld hl, wd730
	res 6, [hl]

	call ReloadMapData
	ld c, 10
	call DelayFrames
	predef IndexToPokedex
	ld a, [wd11e]
	dec a
	ld c, a
	ld b, FLAG_SET
	ld hl, wPokedexSeen
	predef FlagActionPredef
	ld a, $1
	ld [wDoNotWaitForButtonPressAfterDisplayingText], a
	ret
