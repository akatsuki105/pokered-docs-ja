; ゲーム内で利用される OAM のフラグ  
; GameBoy本体の OAM の attr とはビットの意味が違うので注意 (ref: https://gbdev.io/pandocs/#vram-sprite-attribute-table-oam)

; ---

; ゲーム内のスプライト(8*8pxのタイルが4枚)だが、このフラグが立っているとき、そのOAM(8*8px)は4枚のタイルの右下であることを示す
; GameBoy本体の OAMに格納されるが DMGでは 0-2bitは意味を持たないので勝手に bitの使い方を変えている
OAMFLAG_ENDOFDATA   EQU %00000001
; GameBoy本体の OAMに格納されるが DMGでは 0-2bitは意味を持たないので勝手に bitの使い方を変えている
OAMFLAG_CANBEMASKED EQU %00000010
; OAM をX方向にに反転させるフラグ (<- | ->)  
; 左を向いてる OAM に右を向かせたり、上下に歩いているときに前に出した足を右左と反転させるために使われる  
; GameBoy本体の OAM の attr に格納される 
OAMFLAG_VFLIPPED    EQU %00100000

; ---

; OAM attribute flags(GameBoy本体の OAMのattrの各bitにラベルをつけたもの)
OAM_PALETTE   EQU %111
OAM_TILE_BANK EQU 3
OAM_OBP_NUM   EQU 4 ; Non CGB Mode Only
OAM_X_FLIP    EQU 5
OAM_Y_FLIP    EQU 6
OAM_PRIORITY  EQU 7 ; 0: OBJ above BG, 1: OBJ behind BG (colors 1-3)

; OAM attribute masks
OAM_HFLIP     EQU 1 << OAM_X_FLIP ; horizontal flip
OAM_VFLIP     EQU 1 << OAM_Y_FLIP ; vertical flip
OAM_BEHIND_BG EQU 1 << OAM_PRIORITY ; behind bg (except color 0)
