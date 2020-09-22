; **SaveTrainerName**  
; wcd6d にトレーナーの名前を格納する  
; - - -  
; [wTrainerClass] = 対象の trainer class  
SaveTrainerName:
	; hl = TrainerNamePointers の該当エントリ
	ld hl, TrainerNamePointers
	ld a, [wTrainerClass]
	dec a
	ld c, a
	ld b, 0
	add hl, bc
	add hl, bc

	; hl = 名前
	ld a, [hli]
	ld h, [hl]
	ld l, a

; wcd6d にトレーナーの名前を格納する  
	ld de, wcd6d
.CopyCharacter
; {
	inline "[de++] = [hl++]"
	cp "@"
	jr nz, .CopyCharacter
; }
	ret

; trainer class -> トレーナー名
TrainerNamePointers:
	dw YoungsterName
	dw BugCatcherName
	dw LassName
	dw wTrainerName
	dw JrTrainerMName
	dw JrTrainerFName
	dw PokemaniacName
	dw SuperNerdName
	dw wTrainerName
	dw wTrainerName
	dw BurglarName
	dw EngineerName
	dw JugglerXName
	dw wTrainerName
	dw SwimmerName
	dw wTrainerName
	dw wTrainerName
	dw BeautyName
	dw wTrainerName
	dw RockerName
	dw JugglerName
	dw wTrainerName
	dw wTrainerName
	dw BlackbeltName
	dw wTrainerName
	dw ProfOakName
	dw ChiefName
	dw ScientistName
	dw wTrainerName
	dw RocketName
	dw CooltrainerMName
	dw CooltrainerFName
	dw wTrainerName
	dw wTrainerName
	dw wTrainerName
	dw wTrainerName
	dw wTrainerName
	dw wTrainerName
	dw wTrainerName
	dw wTrainerName
	dw wTrainerName
	dw wTrainerName
	dw wTrainerName
	dw wTrainerName
	dw wTrainerName
	dw wTrainerName
	dw wTrainerName

; "YOUNGSTER"
YoungsterName:
	db "YOUNGSTER@"

; "BUG CATCHER"
BugCatcherName:
	db "BUG CATCHER@"

; "LASS"
LassName:
	db "LASS@"

; "JR.TRAINER♂"
JrTrainerMName:
	db "JR.TRAINER♂@"

; "JR.TRAINER♀"
JrTrainerFName:
	db "JR.TRAINER♀@"

; "POKéMANIAC"
PokemaniacName:
	db "POKéMANIAC@"

SuperNerdName:
	db "SUPER NERD@"
BurglarName:
	db "BURGLAR@"
EngineerName:
	db "ENGINEER@"
JugglerXName:
	db "JUGGLER@"
SwimmerName:
	db "SWIMMER@"
BeautyName:
	db "BEAUTY@"
RockerName:
	db "ROCKER@"
JugglerName:
	db "JUGGLER@"
BlackbeltName:
	db "BLACKBELT@"
ProfOakName:
	db "PROF.OAK@"
ChiefName:
	db "CHIEF@"
ScientistName:
	db "SCIENTIST@"
RocketName:
	db "ROCKET@"
CooltrainerMName:
	db "COOLTRAINER♂@"
CooltrainerFName:
	db "COOLTRAINER♀@"
