; 16で初期化され、JOYPADの走査ループで、A,B,Start,Select が押されているときに 1ずつデクリメントされる  
; 0 になると リセット処理が走る  
; つまり A,B,Start,Select が 16ループの間押されているとリセット処理が走る  
hSoftReset EQU $FF8A

; base tile ID to which offsets are added
hBaseTileID EQU $FF8B

; 3-byte BCD number
hItemPrice EQU $FF8B

hDexWeight EQU $FF8B

hWarpDestinationMap EQU $FF8B

hOAMTile EQU $FF8B

hROMBankTemp EQU $FF8B

hPreviousTileset EQU $FF8B

hEastWestConnectedMapWidth EQU $FF8B

hSlideAmount EQU $FF8B

hRLEByteValue EQU $FF8B

H_SPRITEWIDTH            EQU $FF8B ; in tiles
H_SPRITEINTERLACECOUNTER EQU $FF8B
H_SPRITEHEIGHT           EQU $FF8C ; in tiles
H_SPRITEOFFSET           EQU $FF8D

H_DOWNARROWBLINKCNT1 EQU $FF8B  ; TODO: ▼の点滅をカウントするカウンター
H_DOWNARROWBLINKCNT2 EQU $FF8C  ; TODO: ▼の点滅をカウントするカウンター

H_SPRITEDATAOFFSET EQU $FF8B
H_SPRITEINDEX      EQU $FF8C

hMapStride EQU $FF8B
hMapWidth  EQU $FF8C

hNorthSouthConnectionStripWidth EQU $FF8B
hNorthSouthConnectedMapWidth    EQU $FF8C

; DisplayTextIDの引数
hSpriteIndexOrTextID EQU $FF8C

hPartyMonIndex EQU $FF8C

; OakSpeechSlidePicCommon で使用
; グラをスライドするたびにシフトされるタイルの総数
hSlidingRegionSize EQU $FF8C

; 2 bytes
hEnemySpeed EQU $FF8D

hVRAMSlot EQU $FF8D

hFourTileSpriteCount EQU $FF8E

; -1 = left  
;  0 = right  
hSlideDirection EQU $FF8D

hSpriteFacingDirection EQU $FF8D

hSpriteMovementByte2 EQU $FF8D

hSpriteImageIndex EQU $FF8D

hLoadSpriteTemp1 EQU $FF8D
hLoadSpriteTemp2 EQU $FF8E

hHalveItemPrices EQU $FF8E

hSpriteOffset2 EQU $FF8F

hOAMBufferOffset EQU $FF90

hSpriteScreenX EQU $FF91
hSpriteScreenY EQU $FF92

hTilePlayerStandingOn EQU $FF93

hSpritePriority EQU $FF94

; 2 bytes
hSignCoordPointer EQU $FF95

hNPCMovementDirections2Index EQU $FF95

; CalcPositionOfPlayerRelativeToNPC の処理対象のスプライトのオフセット
hNPCSpriteOffset EQU $FF95

; temp value used when swapping bytes
hSwapTemp EQU $FF95

hExperience EQU $FF96 ; 3 bytes, big endian

; Multiplication and division variables are meant
; to overlap for back-to-back usage. Big endian.

H_MULTIPLICAND EQU $FF96 ; 3 bytes
H_MULTIPLIER   EQU $FF99 ; 1 byte
H_PRODUCT      EQU $FF95 ; 4 bytes

H_DIVIDEND     EQU $FF95 ; 4 bytes
H_DIVISOR      EQU $FF99 ; 1 byte
H_QUOTIENT     EQU $FF95 ; 4 bytes
H_REMAINDER    EQU $FF99 ; 1 byte

H_DIVIDEBUFFER EQU $FF9A

H_MULTIPLYBUFFER EQU $FF9B

; PrintNumber (big endian).
H_PASTLEADINGZEROES EQU $FF95 ; last char printed
H_NUMTOPRINT        EQU $FF96 ; 3 bytes
H_POWEROFTEN        EQU $FF99 ; 3 bytes
H_SAVEDNUMTOPRINT   EQU $FF9C ; 3 bytes

hNPCPlayerYDistance EQU $FF95 ; NPCと主人公の間のY距離(歩数単位)
hNPCPlayerXDistance EQU $FF96 ; NPCと主人公の間のX距離(歩数単位)

hFindPathNumSteps EQU $FF97

; bit 0: pathの終端のYcoordがtargetのYcoordと一致したときにセット  
; bit 1: pathの終端のXcoordがtargetのXcoordと一致したときにセット  
; 
; 両方のbitがセットされている場合、pathのendがtargetの座標と一致していることを意味する(Pathが見つかっているときなど)  
hFindPathFlags EQU $FF98

hFindPathYProgress EQU $FF99
hFindPathXProgress EQU $FF9A

; 0 = プレイヤーから見たNPC(base:プレイヤー target:NPC)  
; 1 = NPCから見たプレイヤー(base:NPC target:プレイヤー)  
hNPCPlayerRelativePosPerspective EQU $FF9B

; bit 0:  
; 0 = target が base と同じY座標 か base より下 にいる 
; 1 = target が base より 上 にいる
; 
; bit 1:  
; 0 = target が base と同じX座標か base より左にいる 
; 1 = target が base より右にいる  
; 
; hNPCPlayerRelativePosPerspective == 0 -> base:プレイヤー, target:NPC  
; hNPCPlayerRelativePosPerspective == 1 -> base:NPC, target:プレイヤー
hNPCPlayerRelativePosFlags EQU $FF9D

; いくつかのコードがこのフラグを0にしているが特に理由はなさそう  
hUnusedCoinsByte EQU $FF9F

hMoney EQU $FF9F ; 3バイト(10進数で6桁)のBCDフォーマットの数値
hCoins EQU $FFA0 ; 2バイトのBCD数値 一時的なコイン枚数を格納するバッファ?

hDivideBCDDivisor  EQU $FFA2 ; 3-byte BCD number
hDivideBCDQuotient EQU $FFA2 ; 3-byte BCD number
hDivideBCDBuffer   EQU $FFA5 ; 3-byte BCD number

hSerialReceivedNewData EQU $FFA9

; $01 = シリアル通信でslave側  
; $02 = シリアル通信でmaster側  
; $ff = コネクション確立中  
hSerialConnectionStatus EQU $FFAA

hSerialIgnoringInitialData EQU $FFAB

hSerialSendData EQU $FFAC

hSerialReceiveData EQU $FFAD

; these values are copied to SCX, SCY, and WY during V-blank
hSCX EQU $FFAE      ; SCXにコピーされるアドレス
hSCY EQU $FFAF      ; SCYにコピーされるアドレス
hWY  EQU $FFB0      ; VBlank中、WYにコピーされるアドレス

hJoyLast     EQU $FFB1
hJoyReleased EQU $FFB2
hJoyPressed  EQU $FFB3
hJoyHeld     EQU $FFB4 ; 押されている状態のキー入力を格納
hJoy5        EQU $FFB5
hJoy6        EQU $FFB6
hJoy7        EQU $FFB7

; 現在のROMバンクの番号を保持する
H_LOADEDROMBANK EQU $FFB8

hSavedROMBank EQU $FFB9

; VBlank期間の自動的なBG転送(WRAMからVRAMへ)が有効かどうか  
; 0 => 無効  
; 1 => 有効
H_AUTOBGTRANSFERENABLED EQU $FFBA

TRANSFERTOP    EQU 0
TRANSFERMIDDLE EQU 1
TRANSFERBOTTOM EQU 2

; 3ステップに分けて行われる AutoBgMapTransfer が今何ステップ目か  
; 00 = 3/3  
; 01 = 2/3  
; 02 = 1/3  
H_AUTOBGTRANSFERPORTION EQU $FFBB

; 自動的なBG転送の転送先のアドレス
H_AUTOBGTRANSFERDEST EQU $FFBC ; 2 bytes

; temporary storage for stack pointer during memory transfers that use pop
; to increase speed
H_SPTEMP EQU $FFBF ; 2 bytes

; VBlankCopyBgMap での転送元となるアドレス(リトルエンディアンで2バイト)  
; 1バイト目を 2倍した値 によって転送が有効か無効か分かる
; 0 なら転送は無効  
; 0 以外なら転送は有効  
; つまり [H_VBCOPYBGSRC] が 0xXX00 なら転送は無効 
H_VBCOPYBGSRC EQU $FFC1 ; 2 bytes

; destination address for VBlankCopyBgMap function
H_VBCOPYBGDEST EQU $FFC3 ; 2 bytes

; number of rows for VBlankCopyBgMap to copy
; VBlankCopyBgMap でコピーを行う行数
H_VBCOPYBGNUMROWS EQU $FFC5

; VBlankCopyの転送サイズ  
; H_VBCOPYSIZE = n のときは n枚分のタイル つまり 16n byte転送
H_VBCOPYSIZE EQU $FFC6

; VBlankCopy のコピー元
H_VBCOPYSRC EQU $FFC7

; VBlankCopyのコピー先  
; 基本的に(というか絶対?) VRAMの タイルデータ($8000-97FF) を指す？
H_VBCOPYDEST EQU $FFC9

; size of source data for VBlankCopyDouble in 8-byte units
H_VBCOPYDOUBLESIZE EQU $FFCB

; source address for VBlankCopyDouble function
H_VBCOPYDOUBLESRC EQU $FFCC

; destination address for VBlankCopyDouble function
H_VBCOPYDOUBLEDEST EQU $FFCE

; controls whether a row or column of 2x2 tile blocks is redrawn in V-blank  
; 00 = no redraw  
; 01 = redraw column  
; 02 = redraw row  
hRedrawRowOrColumnMode EQU $FFD0

REDRAW_COL EQU 1
REDRAW_ROW EQU 2

hRedrawRowOrColumnDest EQU $FFD1

hRandomAdd EQU $FFD3
hRandomSub EQU $FFD4

H_FRAMECOUNTER EQU $FFD5 ; VBlankごとにデクリメントされる(遅延処理の実現に利用)

; V-blank sets this to 0 each time it runs.
; So, by setting it to a nonzero value and waiting for it to become 0 again,
; you can detect that the V-blank handler has run since then.
H_VBLANKOCCURRED EQU $FFD6

; 現在のタイルセットの種類  
; 00 = indoor  
; 01 = cave  
; 02 = outdoor  
; 00にセットすることで水や花が定期的に動く処理をoffにすることがよくある  
hTilesetType EQU $FFD7

; 20 = water  
; 21 = flower  
hMovingBGTilesCounter1 EQU $FFD8

; 現在処理中のスプライトの番号に$10をかけたもの  
; $10をかけるのはスプライトのデータ領域1つのサイズが$10であるから  
H_CURRENTSPRITEOFFSET EQU $FFDA ; multiple of $10

hItemCounter EQU $FFDB

hGymGateIndex EQU $FFDB

hGymTrashCanRandNumMask EQU $FFDB

hDexRatingNumMonsSeen  EQU $FFDB
hDexRatingNumMonsOwned EQU $FFDC

; $00 = bag full
; $01 = got item
; $80 = didn't meet required number of owned mons
; $FF = player cancelled
hOaksAideResult       EQU $FFDB

hOaksAideRequirement  EQU $FFDB ; つかまえた数として要求されている数
hOaksAideRewardItem   EQU $FFDC
hOaksAideNumMonsOwned EQU $FFDD

hItemToRemoveID    EQU $FFDB    ; RemoveItemByIDで削除対象のアイテムID
hItemToRemoveIndex EQU $FFDC    ; RemoveItemByIDで削除対象のアイテムをループで探すときのループカウンタ

hVendingMachineItem  EQU $FFDB
hVendingMachinePrice EQU $FFDC ; 3-byte BCD number

; the first tile ID in a sequence of tile IDs that increase by 1 each step
hStartTileID EQU $FFE1

hNewPartyLength EQU $FFE4

hDividend2 EQU $FFE5
hDivisor2  EQU $FFE6
hQuotient2 EQU $FFE7

; 現在の方向を考慮したスプライトのタイルイメージのあるアドレス?
hSpriteVRAMSlotAndFacing EQU $FFE9

hCoordsInFrontOfPlayerMatch EQU $FFEA

hSpriteAnimFrameCounter EQU $FFEA

H_WHOSETURN EQU $FFF3 ; 0 on playerâ€™s turn, 1 on enemyâ€™s turn

; **hFlags_0xFFF6**  
; - bit 0: draw HP fraction to the right of bar instead of below (for party menu)  
; - bit 1: メニューの各アイテムの行間を2タイル分に(0なら1タイル分)
hFlags_0xFFF6 EQU $FFF6

hFieldMoveMonMenuTopMenuItemX EQU $FFF7

hDisableJoypadPolling EQU $FFF9

hJoyInput EQU $FFF8

