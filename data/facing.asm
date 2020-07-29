; **SpriteFacingAndAnimationTable**  
; ???  
; - - -  
; 各エントリ 4byte  
; 
; 0-1: SpriteFacing${A}And${B}のアドレス(2byte)  
; 2-3: ???
SpriteFacingAndAnimationTable:
; facing down
	dw SpriteFacingDownAndStanding, SpriteOAMParameters        ; walk animation frame 0
	dw SpriteFacingDownAndWalking, SpriteOAMParameters         ; walk animation frame 1
	dw SpriteFacingDownAndStanding, SpriteOAMParameters        ; walk animation frame 2
	dw SpriteFacingDownAndWalking, SpriteOAMParametersFlipped  ; walk animation frame 3
; facing up
	dw SpriteFacingUpAndStanding, SpriteOAMParameters          ; walk animation frame 0
	dw SpriteFacingUpAndWalking, SpriteOAMParameters           ; walk animation frame 1
	dw SpriteFacingUpAndStanding, SpriteOAMParameters          ; walk animation frame 2
	dw SpriteFacingUpAndWalking, SpriteOAMParametersFlipped    ; walk animation frame 3
; facing left
	dw SpriteFacingLeftAndStanding, SpriteOAMParameters        ; walk animation frame 0
	dw SpriteFacingLeftAndWalking, SpriteOAMParameters         ; walk animation frame 1
	dw SpriteFacingLeftAndStanding, SpriteOAMParameters        ; walk animation frame 2
	dw SpriteFacingLeftAndWalking, SpriteOAMParameters         ; walk animation frame 3
; facing right
	dw SpriteFacingLeftAndStanding, SpriteOAMParametersFlipped ; walk animation frame 0
	dw SpriteFacingLeftAndWalking, SpriteOAMParametersFlipped  ; walk animation frame 1
	dw SpriteFacingLeftAndStanding, SpriteOAMParametersFlipped ; walk animation frame 2
	dw SpriteFacingLeftAndWalking, SpriteOAMParametersFlipped  ; walk animation frame 3
; ???
	dw SpriteFacingDownAndStanding, SpriteOAMParameters        ; ---
	dw SpriteFacingDownAndStanding, SpriteOAMParameters        ; This table is used for sprites $a and $b.
	dw SpriteFacingDownAndStanding, SpriteOAMParameters        ; All orientation and animation parameters
	dw SpriteFacingDownAndStanding, SpriteOAMParameters        ; lead to the same result. Used for immobile
	dw SpriteFacingDownAndStanding, SpriteOAMParameters        ; sprites like items on the ground
	dw SpriteFacingDownAndStanding, SpriteOAMParameters        ; ---
	dw SpriteFacingDownAndStanding, SpriteOAMParameters
	dw SpriteFacingDownAndStanding, SpriteOAMParameters
	dw SpriteFacingDownAndStanding, SpriteOAMParameters
	dw SpriteFacingDownAndStanding, SpriteOAMParameters
	dw SpriteFacingDownAndStanding, SpriteOAMParameters
	dw SpriteFacingDownAndStanding, SpriteOAMParameters
	dw SpriteFacingDownAndStanding, SpriteOAMParameters
	dw SpriteFacingDownAndStanding, SpriteOAMParameters
	dw SpriteFacingDownAndStanding, SpriteOAMParameters
	dw SpriteFacingDownAndStanding, SpriteOAMParameters

; --------------------
; SpriteFacing${A}And${B}  
; ${A}: Down, Up, Left  
; ${B}: Standing, Walking  
; 
; db ${X+Y}, ${X+Y}+1, ${X+Y}+2, ${X+Y}+3
; X: 0x80(歩) or 0x00(立)
; Y: 0x00(下) or 0x04(上) or 0x08(右 or 左)
; つまり ${X+Y} = 0x00 or 0x04 or 0x08 or 0x80 or 0x84 or 0x88

; down
SpriteFacingDownAndStanding:
	db $00,$01,$02,$03
SpriteFacingDownAndWalking:
	db $80,$81,$82,$83

; up
SpriteFacingUpAndStanding:
	db $04,$05,$06,$07
SpriteFacingUpAndWalking:
	db $84,$85,$86,$87

; right or left
SpriteFacingLeftAndStanding:
	db $08,$09,$0a,$0b
SpriteFacingLeftAndWalking:
	db $88,$89,$8a,$8b

; --------------------

; **SpriteOAMParameters**  
; OAM4枚からなるオブジェクト(16\*16pxのスプライト) の各OAMの属性を定めたテーブル  
; - - -  
; ポケモンのスプライトは 16\*16px なので 8\*8pxのスプライトが 4枚必要になることに注意  
; db offsetY, offsetX, attr  
SpriteOAMParameters:
	db $00,$00, $00                                      ; 左上(0, 0)
	db $00,$08, $00                                      ; 右上(8, 0)
	db $08,$00, OAMFLAG_CANBEMASKED                      ; 左下(0, 8)
	db $08,$08, OAMFLAG_CANBEMASKED | OAMFLAG_ENDOFDATA  ; 右下(8, 8)
; **SpriteOAMParametersFlipped**  
; OAM4枚からなるオブジェクト(16\*16pxのスプライト) の各OAMの属性を定めたテーブル  
SpriteOAMParametersFlipped:
	db $00,$08, OAMFLAG_VFLIPPED
	db $00,$00, OAMFLAG_VFLIPPED
	db $08,$08, OAMFLAG_VFLIPPED | OAMFLAG_CANBEMASKED
	db $08,$00, OAMFLAG_VFLIPPED | OAMFLAG_CANBEMASKED | OAMFLAG_ENDOFDATA
