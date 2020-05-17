; **LoadMonData_**  
; [wMonDataLocation]から[wWhichPokemon]で指定したポケモンのデータをロードする
; - - -
; 
; INPUT:  
; wWhichPokemon: wMonDataLocation内のポケモンのインデックス  
; wMonDataLocation:  
; - 0: パーティのポケモン
; - 1: 敵のポケモン
; - 2: ボックスのポケモン
; - 3: 育て屋のポケモン
; 
; OUTPUT:  
; - [wcf91] = ポケモンのID
; - [wLoadedMon] = ポケモンのデータ
; - [wMonHeader] = ポケモンのbase stats
LoadMonData_:
	; 育て屋の場合は wDayCareMonSpecies にポケモンのIDが入っている
	ld a, [wDayCareMonSpecies]
	ld [wcf91], a
	ld a, [wMonDataLocation]
	cp DAYCARE_DATA
	jr z, .GetMonHeader

	; それらの場合は専用の関数を使って取得する
	ld a, [wWhichPokemon]
	ld e, a
	callab GetMonSpecies

; INPUT: [wcf91] = ポケモンのID
.GetMonHeader
	ld a, [wcf91]
	ld [wd0b5], a ; input for GetMonHeader
	call GetMonHeader
	; TODO: wip

	ld hl, wPartyMons
	ld bc, wPartyMon2 - wPartyMon1
	ld a, [wMonDataLocation]
	cp ENEMY_PARTY_DATA
	jr c, .getMonEntry

	ld hl, wEnemyMons
	jr z, .getMonEntry

	cp 2
	ld hl, wBoxMons
	ld bc, wBoxMon2 - wBoxMon1
	jr z, .getMonEntry

	ld hl, wDayCareMon
	jr .copyMonData

.getMonEntry
	ld a, [wWhichPokemon]
	call AddNTimes

.copyMonData
	ld de, wLoadedMon
	ld bc, wPartyMon2 - wPartyMon1
	jp CopyData
