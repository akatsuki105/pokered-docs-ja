; "Hello there! Welcome to the world of #MON!"  
; "My name is OAK! People call me the #MON PROF!"  
_OakSpeechText1::
	text "Hello there!"
	line "Welcome to the"
	cont "world of #MON!"

	para "My name is OAK!"
	line "People call me"
	cont "the #MON PROF!"
	prompt

; "This world is inhabited by creatures called #MON!@@"  
_OakSpeechText2A::
	text "This world is"
	line "inhabited by"
	cont "creatures called"
	cont "#MON!@@"

; "For some people, #MON are pets."  
; "Others use them for fights."  
; "Myself... I study #MON as a profession."  
_OakSpeechText2B::
	text $51,"For some people,"
	line "#MON are"
	cont "pets. Others use"
	cont "them for fights."

	para "Myself..."

	para "I study #MON"
	line "as a profession."
	prompt

; "First, what is your name?"
_IntroducePlayerText::
	text "First, what is"
	line "your name?"
	prompt

; "This is my grand-son."  
; "He's been your rival since you were a baby."  
; "...Erm, what is his name again?"  
_IntroduceRivalText::
	text "This is my grand-"
	line "son. He's been"
	cont "your rival since"
	cont "you were a baby."

	para "...Erm, what is"
	line "his name again?"
	prompt

; "<PLAYER>!"  
; "Your very own #MON legend is about to unfold!"  
; "A world of dreams and adventures with #MON awaits!"  
; "Let's go!"  
_OakSpeechText3::
	text "<PLAYER>!"

	para "Your very own"
	line "#MON legend is"
	cont "about to unfold!"

	para "A world of dreams"
	line "and adventures"
	cont "with #MON"
	cont "awaits! Let's go!"
	done
