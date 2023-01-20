; **ForcedBikeOrSurfMaps**  
; このマスに入ると、自転車か波乗りを強制される?
; - - -  
; MapID, y, x  
; db ROUTE_16,$0A,$11	; (11, a)  
; db ROUTE_16,$0B,$11	; (11, b)  
; db ROUTE_18,$08,$21	; (21, 8)  
; db ROUTE_18,$09,$21	; (21, 9)  
; db SEAFOAM_ISLANDS_B3F,$07,$12  
; db SEAFOAM_ISLANDS_B3F,$07,$13  
; db SEAFOAM_ISLANDS_B4F,$0E,$04  
; db SEAFOAM_ISLANDS_B4F,$0E,$05  
; db $FF ;end  
ForcedBikeOrSurfMaps:
	db ROUTE_16,$0A,$11 ; (11, a)
	db ROUTE_16,$0B,$11	; (11, b)
	db ROUTE_18,$08,$21 ; (21, 8)
	db ROUTE_18,$09,$21	; (21, 9)
	db SEAFOAM_ISLANDS_B3F,$07,$12
	db SEAFOAM_ISLANDS_B3F,$07,$13
	db SEAFOAM_ISLANDS_B4F,$0E,$04
	db SEAFOAM_ISLANDS_B4F,$0E,$05
	db $FF ;end
