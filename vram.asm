vChars0 EQU $8000   ; タイルアセットを配置する領域1
vChars1 EQU $8800   ; タイルアセットを配置する領域2
vChars2 EQU $9000
vBGMap0 EQU $9800   ; BGマップ1
vBGMap1 EQU $9c00   ; BGマップ2

; Battle/Menu
vSprites  EQU vChars0   ; $8000
vFont     EQU vChars1   ; $8800
vFrontPic EQU vChars2   ; $9000
vBackPic  EQU vFrontPic + 7 * 7 * $10 ; $9490

; Overworld
vNPCSprites  EQU vChars0    ; 0x8000 NPCの立ち2bppタイルデータがあるVRAMアドレス
vNPCSprites2 EQU vChars1    ; 0x8800 NPCの歩き2bppタイルデータがあるVRAMアドレス
vTileset     EQU vChars2    ; 0x9000

; Title
vTitleLogo  EQU vChars1 ; $8800 
vTitleLogo2 EQU vFrontPic + 7 * 7 * $10 ; $9490

