; プレイヤーがドアタイルに立っているときに下に強制的に移動させる  
; プレイヤーが建物から外に出たときはドアタイルにワープするので、そこからドアの前に移動させる動作を実現するのに使う
PlayerStepOutFromDoor:
	; wd730のbit1をクリア
	ld hl, wd730
	res 1, [hl]

	; プレイヤーがドアタイルにいない
	call IsPlayerStandingOnDoorTile
	jr nc, .notStandingOnDoor

	; プレイヤーのボタン入力を無効化
	ld a, $fc
	ld [wJoyIgnore], a

	; プレイヤーを下に1歩だけ勝手に歩かせる準備
	ld hl, wd736
	set 1, [hl]
	ld a, $1
	ld [wSimulatedJoypadStatesIndex], a
	ld a, D_DOWN
	ld [wSimulatedJoypadStatesEnd], a
	xor a
	ld [wSpriteStateData1 + 2], a

	; 勝手に歩かせる
	call StartSimulatingJoypadStates
	ret
.notStandingOnDoor
	; キー入力のシミュレートをしない
	xor a
	ld [wWastedByteCD3A], a
	ld [wSimulatedJoypadStatesIndex], a
	ld [wSimulatedJoypadStatesEnd], a

	; ドアから下に進んでいる状態を表すフラグをクリア
	ld hl, wd736
	res 0, [hl]
	res 1, [hl]

	; simulated joypadフラグをクリア
	ld hl, wd730
	res 7, [hl]
	ret

; **_EndNPCMovementScript**  
; scripted NPC と simulated joypad に関する変数やフラグをクリア  
_EndNPCMovementScript:
	; simulated joypadフラグをクリア
	ld hl, wd730
	res 7, [hl]
	
	; NPCのプログラム動作が初期化されているときに立つフラグをセット
	ld hl, wd72e
	res 7, [hl]
	
	; ドアフラグを消す
	ld hl, wd736
	res 0, [hl]
	res 1, [hl]
	
	; 変数を初期化
	xor a
	ld [wNPCMovementScriptSpriteOffset], a
	ld [wNPCMovementScriptPointerTableNum], a
	ld [wNPCMovementScriptFunctionNum], a
	ld [wWastedByteCD3A], a
	ld [wSimulatedJoypadStatesIndex], a
	ld [wSimulatedJoypadStatesEnd], a
	ret

; **PalletMovementScriptPointerTable**  
; マサラタウンのオーキド博士の強制連行イベントの NPC movement script のアドレスを格納したテーブル  
PalletMovementScriptPointerTable:
	dw PalletMovementScript_OakMoveLeft			; 0: オーキドを左
	dw PalletMovementScript_PlayerMoveLeft		; 1: 主人公を左
	dw PalletMovementScript_WaitAndWalkToLab	; 2
	dw PalletMovementScript_WalkToLab			; 3
	dw PalletMovementScript_Done				; 4

; **PalletMovementScript_OakMoveLeft**  
; オーキド博士による連行イベントで、オーキドの初期位置が右のときにオーキド博士を左に移動させる  
; - - -  
; 初期位置右: https://imgur.com/6bac8HE.png  
; 初期位置左: https://imgur.com/CTFq90R.png  
; 
; [wNPCMovementScriptFunctionNum] == 0 に対応 
; 
; INPUT:  
; [wSpriteIndex] = オーキド博士のスプライトのオフセット  
PalletMovementScript_OakMoveLeft:
	; [wNumStepsToTake] = オーキド博士が初期位置まであるく歩数
	ld a, [wXCoord] 		; $a(左) or $b(右)
	sub $a
	ld [wNumStepsToTake], a ; $0(左) or $1(右)

	; 左にいるときは歩く必要なし -> .playerOnLeftTile
	jr z, .playerOnLeftTile

	; 右(https://imgur.com/6bac8HE)にいるときは オーキド博士を左に1歩移動させる
	; Make Prof. Oak step to the left.

	; wNPCMovementDirections2 に 左移動の movement data を配置
	ld b, 0
	ld c, a
	ld hl, wNPCMovementDirections2
	ld a, NPC_MOVEMENT_LEFT
	call FillMemory
	ld [hl], $ff	; wNPCMovementDirections2 の終端記号

	; [H_SPRITEINDEX] = オーキド博士のスプライトのオフセット
	ld a, [wSpriteIndex]
	ld [H_SPRITEINDEX], a

	; movement dataどおりにオーキド博士を一マス左に移動させる
	ld de, wNPCMovementDirections2
	call MoveSprite

	; [wNPCMovementScriptFunctionNum] を PalletMovementScript_PlayerMoveLeft に  
	ld a, $1
	ld [wNPCMovementScriptFunctionNum], a
	jr .done

	; この時点でオーキド博士は初期位置(左)にいる
.playerOnLeftTile
	; [wNPCMovementScriptFunctionNum] を PalletMovementScript_WalkToLab に  
	ld a, $3
	ld [wNPCMovementScriptFunctionNum], a

.done
	; マップが変わってもBGMを変わらないようにする
	ld hl, wFlags_D733
	set 1, [hl]
	ld a, $fc
	ld [wJoyIgnore], a
	ret

; **PalletMovementScript_PlayerMoveLeft**  
; PalletMovementScript_OakMoveLeft でオーキド博士を左に動かした後に主人公も続いて左に動かす処理  
; - - -  
; [wNPCMovementScriptFunctionNum] == 1 に対応  
; https://imgur.com/9MBdCpd.gif
PalletMovementScript_PlayerMoveLeft:
	; wd730 がセットされていたら、オーキド博士がまだ左に動いているのでreturn 
	ld a, [wd730]
	bit 0, a
	ret nz

	; wNPCMovementDirections2 に入っている 左方向の入力を simulate joypadの入力として wSimulatedJoypadStatesEnd に配置
	ld a, [wNumStepsToTake]
	ld [wSimulatedJoypadStatesIndex], a
	ld [hNPCMovementDirections2Index], a
	predef ConvertNPCMovementDirectionsToJoypadMasks
	; simulated joypadの移動として主人公を左に移動
	call StartSimulatingJoypadStates

	; [wNPCMovementScriptFunctionNum] = PalletMovementScript_WaitAndWalkToLab
	ld a, $2
	ld [wNPCMovementScriptFunctionNum], a
	ret

; **PalletMovementScript_WaitAndWalkToLab**  
; `PalletMovementScript_WalkToLab` とほぼ同じ  
; - - -  
; [wNPCMovementScriptFunctionNum] == 2 に対応  
; プレイヤーが `PalletMovementScript_PlayerMoveLeft` で左に移動し終えたのを確認して、 `PalletMovementScript_WalkToLab`
PalletMovementScript_WaitAndWalkToLab:
	ld a, [wSimulatedJoypadStatesIndex]
	and a
	ret nz

; **PalletMovementScript_WalkToLab**  
; オーキド博士と一緒にオーキド研究所まで歩いていく処理  
; - - -  
; [wNPCMovementScriptFunctionNum] == 3 に対応  
PalletMovementScript_WalkToLab:
	; プレイヤーが勝手に動けないように
	xor a
	ld [wOverrideSimulatedJoypadStatesMask], a

	ld a, [wSpriteIndex]
	swap a
	ld [wNPCMovementScriptSpriteOffset], a

	; simulated joypad として 主人公にオーキド研究所まで歩いていく移動データを与える
	xor a
	ld [wSpriteStateData2 + $06], a
	ld hl, wSimulatedJoypadStatesEnd
	ld de, RLEList_PlayerWalkToLab
	call DecodeRLEList
	dec a
	ld [wSimulatedJoypadStatesIndex], a

	; scripted NPC として オーキド博士にオーキド研究所まで歩いていく移動データを与える
	ld hl, wNPCMovementDirections2
	ld de, RLEList_ProfOakWalkToLab
	call DecodeRLEList
	
	ld hl, wd72e
	res 7, [hl]
	ld hl, wd730
	set 7, [hl]

	; [wNPCMovementScriptFunctionNum] = PalletMovementScript_Done
	ld a, $4
	ld [wNPCMovementScriptFunctionNum], a
	ret

RLEList_ProfOakWalkToLab:
	db NPC_MOVEMENT_DOWN, $05
	db NPC_MOVEMENT_LEFT, $01
	db NPC_MOVEMENT_DOWN, $05
	db NPC_MOVEMENT_RIGHT, $03
	db NPC_MOVEMENT_UP, $01
	db $E0, $01 ; stand still
	db $FF

RLEList_PlayerWalkToLab:
	db D_UP, $02		; ↑ ↑
	db D_RIGHT, $03		; → → →
	db D_DOWN, $05		; ↓ ↓ ↓ ↓ ↓
	db D_LEFT, $01		; ←
	db D_DOWN, $06		; ↓ ↓ ↓ ↓ ↓ ↓
	db $FF

; オーキド研究所まで歩いていく処理が終わったのを確認して simulated joypad や scripted NPCのフラグをクリア
; [wNPCMovementScriptFunctionNum] == 4 に対応  
PalletMovementScript_Done:
	; オーキド研究所まで歩いていく処理の途中なら return
	ld a, [wSimulatedJoypadStatesIndex]
	and a
	ret nz

	; 主人公の家の隣にいるオーキド博士を非表示にする
	ld a, HS_PALLET_TOWN_OAK
	ld [wMissableObjectIndex], a
	predef HideObject

	; フラグを削除
	ld hl, wd730
	res 7, [hl]
	ld hl, wd72e
	res 7, [hl]
	jp EndNPCMovementScript

; **PewterMuseumGuyMovementScriptPointerTable**  
; ニビシティでのニビ科学博物館までの強制連行イベントの NPC movement script のアドレスを格納したテーブル
PewterMuseumGuyMovementScriptPointerTable:
	dw PewterMovementScript_WalkToMuseum	; 0
	dw PewterMovementScript_Done			; 1

; **PewterMovementScript_WalkToMuseum**  
; ニビ科学博物館までの強制連行を行うように scripted NPC と simulated joypadの値を設定する  
; - - -  
; [wNPCMovementScriptFunctionNum] == 0 に対応  
PewterMovementScript_WalkToMuseum:
	; Music_MuseumGuy を再生
	ld a, BANK(Music_MuseumGuy)
	ld [wAudioROMBank], a
	ld [wAudioSavedROMBank], a
	ld a, MUSIC_MUSEUM_GUY
	ld [wNewSoundID], a
	call PlaySound

	; [wNPCMovementScriptSpriteOffset] = [wSpriteIndex]*0x10
	ld a, [wSpriteIndex]
	swap a
	ld [wNPCMovementScriptSpriteOffset], a

	call StartSimulatingJoypadStates
	
	; simulated joypad として ニビ科学博物館まで歩いていく movement data を与える
	ld hl, wSimulatedJoypadStatesEnd
	ld de, RLEList_PewterMuseumPlayer
	call DecodeRLEList
	dec a
	ld [wSimulatedJoypadStatesIndex], a
	xor a
	ld [wWhichPewterGuy], a
	predef PewterGuys

	; scripted NPC として ニビ科学博物館まで歩いていく movement data を与える
	ld hl, wNPCMovementDirections2
	ld de, RLEList_PewterMuseumGuy
	call DecodeRLEList

	ld hl, wd72e
	res 7, [hl]
	
	; [wNPCMovementScriptFunctionNum] = PewterMovementScript_Done
	ld a, $1
	ld [wNPCMovementScriptFunctionNum], a
	ret

RLEList_PewterMuseumPlayer:
	db 0, $01
	db D_UP, $03
	db D_LEFT, $0D
	db D_UP, $06
	db $FF

RLEList_PewterMuseumGuy:
	db NPC_MOVEMENT_UP, $06
	db NPC_MOVEMENT_LEFT, $0D
	db NPC_MOVEMENT_UP, $03
	db NPC_MOVEMENT_LEFT, $01
	db $FF

PewterMovementScript_Done:
	ld a, [wSimulatedJoypadStatesIndex]
	and a
	ret nz
	ld hl, wd730
	res 7, [hl]
	ld hl, wd72e
	res 7, [hl]
	jp EndNPCMovementScript

; **PewterGymGuyMovementScriptPointerTable**  
; ニビシティでのジムまでの強制連行イベントの NPC movement script のアドレスを格納したテーブル
PewterGymGuyMovementScriptPointerTable:
	dw PewterMovementScript_WalkToGym 	; 0
	dw PewterMovementScript_Done		; 1

; **PewterMovementScript_WalkToGym**  
; ニビジムまでの強制連行を行うように scripted NPC と simulated joypadの値を設定する  
; - - -  
; [wNPCMovementScriptFunctionNum] == 0 に対応 
PewterMovementScript_WalkToGym:
	; Music_MuseumGuy を再生
	ld a, BANK(Music_MuseumGuy)
	ld [wAudioROMBank], a
	ld [wAudioSavedROMBank], a
	ld a, MUSIC_MUSEUM_GUY
	ld [wNewSoundID], a
	call PlaySound

	; [wNPCMovementScriptSpriteOffset] = [wSpriteIndex]*0x10
	ld a, [wSpriteIndex]
	swap a
	ld [wNPCMovementScriptSpriteOffset], a

	xor a
	ld [wSpriteStateData2 + $06], a
	
	; simulated joypad として ニビジム まで歩いていく movement data を与える
	ld hl, wSimulatedJoypadStatesEnd
	ld de, RLEList_PewterGymPlayer
	call DecodeRLEList
	dec a
	ld [wSimulatedJoypadStatesIndex], a
	ld a, 1
	ld [wWhichPewterGuy], a
	predef PewterGuys
	
	; scripted NPC として ニビジム まで歩いていく movement data を与える
	ld hl, wNPCMovementDirections2
	ld de, RLEList_PewterGymGuy
	call DecodeRLEList

	ld hl, wd72e
	res 7, [hl]
	ld hl, wd730
	set 7, [hl]

	; [wNPCMovementScriptFunctionNum] = PewterMovementScript_Done
	ld a, $1
	ld [wNPCMovementScriptFunctionNum], a
	ret

RLEList_PewterGymPlayer:
	db 0, $01
	db D_RIGHT, $02
	db D_DOWN, $05
	db D_LEFT, $0B
	db D_UP, $05
	db D_LEFT, $0F
	db $FF

RLEList_PewterGymGuy:
	db NPC_MOVEMENT_DOWN, $02
	db NPC_MOVEMENT_LEFT, $0F
	db NPC_MOVEMENT_UP, $05
	db NPC_MOVEMENT_LEFT, $0B
	db NPC_MOVEMENT_DOWN, $05
	db NPC_MOVEMENT_RIGHT, $03
	db $FF

; **FreezeEnemyTrainerSprite**  
; スプライトを動かなくさせる処理  
; - - -  
; INPUT: [wSpriteIndex] = 対象のスプライトのオフセット
FreezeEnemyTrainerSprite:
	; ポケモンタワーの7Fでは、戦闘を行ったロケット団はその場から消えるため、以降の処理を行う必要はない
	ld a, [wCurMap]
	cp POKEMON_TOWER_7F
	ret z ; the Rockets on Pokemon Tower 7F leave after battling, so don't freeze them

	ld hl, RivalIDs
	ld a, [wEngagedTrainerClass]
	ld b, a

; RivalIDs を順にみていって、戦闘の相手がライバルでないことを確認する
.loop
; {
	ld a, [hli]

	; RivalIDs を最後までみたなら相手はライバルではない -> .notRival
	cp $ff
	jr z, .notRival

	; 戦闘の相手がライバルだった場合も、その場から去るため以降の処理を行う必要はない
	cp b
	ret z

	jr .loop
; }

.notRival
	; movement byte1, 2 を 0xff にしてスプライトを動かなくする
	ld a, [wSpriteIndex]
	ld [H_SPRITEINDEX], a
	jp SetSpriteMovementBytesToFF

RivalIDs:
	db OPP_SONY1	; $19
	db OPP_SONY2	; $2A
	db OPP_SONY3	; $2B
	db $ff
