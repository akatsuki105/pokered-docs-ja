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
; - [wLoadedMon] = Pokemon Data
; - [wMonHeader] = Pokemon Header
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

	ld hl, wPartyMons
	ld bc, wPartyMon2 - wPartyMon1
	ld a, [wMonDataLocation]

	; 自分のパーティのポケモン
	cp ENEMY_PARTY_DATA
	jr c, .getMonEntry

	; 相手のパーティのポケモン
	ld hl, wEnemyMons
	jr z, .getMonEntry

	cp 2
	ld hl, wBoxMons
	ld bc, wBoxMon2 - wBoxMon1
	jr z, .getMonEntry

	ld hl, wDayCareMon
	jr .copyMonData

; INPUT:
; - a = どのポケモンがセレクトされているか
; - hl = リストの先頭
; - bc = リストの各エントリのサイズ
.getMonEntry
	ld a, [wWhichPokemon]
	call AddNTimes	; hl = リストの対象のエントリ

; 
.copyMonData
	ld de, wLoadedMon
	ld bc, wPartyMon2 - wPartyMon1
	jp CopyData
