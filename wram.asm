INCLUDE "constants.asm"

; arg÷8バイト確保(余りは切り上げ)
flag_array: MACRO
	ds ((\1) + 7) / 8
ENDM

; box_structのバイト長
box_struct_length EQU 25 + NUM_MOVES * 2

; ボックス内のポケモンが保持しているデータ
box_struct: MACRO
\1Species::    db
\1HP::         dw
\1BoxLevel::   db
\1Status::     db
\1Type::
\1Type1::      db
\1Type2::      db
\1CatchRate::  db
\1Moves::      ds NUM_MOVES	; [moveNum, moveNum, moveNum, moveNum]
\1OTID::       dw
\1Exp::        ds 3
\1HPExp::      dw
\1AttackExp::  dw
\1DefenseExp:: dw
\1SpeedExp::   dw
\1SpecialExp:: dw
\1DVs::        ds 2	; 1byte = AAAABBBB 2byte = CCCCDDDD (A=こうげき, B=ぼうぎょ, C=すばやさ, D=とくしゅ) HPはこれらから計算
\1PP::         ds NUM_MOVES
ENDM

; パーティ内のポケモンが保持しているデータ
party_struct: MACRO
	box_struct \1
\1Level::      db
\1Stats::
\1MaxHP::      dw
\1Attack::     dw
\1Defense::    dw
\1Speed::      dw
\1Special::    dw
ENDM

; 戦闘中のポケモンが保持しているデータ
battle_struct: MACRO
\1Species::    db
\1HP::         dw
\1PartyPos::
\1BoxLevel::   db
\1Status::     db
\1Type::
\1Type1::      db
\1Type2::      db
\1CatchRate::  db
\1Moves::      ds NUM_MOVES
\1DVs::        ds 2
\1Level::      db
\1Stats::
\1MaxHP::      dw
\1Attack::     dw
\1Defense::    dw
\1Speed::      dw
\1Special::    dw
\1PP::         ds NUM_MOVES
ENDM


SECTION "WRAM Bank 0", WRAM0

wUnusedC000:: ; c000
	ds 1

wSoundID:: ; c001
	ds 1

wMuteAudioAndPauseMusic:: ; c002
; bit 7: whether sound has been muted
; all bits: whether the effective is active
; Store 1 to activate effect (any value in the range [1, 127] works).
; All audio is muted and music is paused. Sfx continues playing until it
; ends normally.
; Store 0 to resume music.
	ds 1

wDisableChannelOutputWhenSfxEnds:: ; c003
	ds 1

wStereoPanning:: ; c004
	ds 1

wSavedVolume:: ; c005
	ds 1

wChannelCommandPointers:: ; c006
	ds 16

wChannelReturnAddresses:: ; c016
	ds 16

wChannelSoundIDs:: ; c026
	ds 8

wChannelFlags1:: ; c02e
	ds 8

wChannelFlags2:: ; c036
	ds 8

wChannelDutyCycles:: ; c03e
	ds 8

wChannelDutyCyclePatterns:: ; c046
	ds 8

wChannelVibratoDelayCounters:: ; c04e
; reloaded at the beginning of a note. counts down until the vibrato begins.
	ds 8

wChannelVibratoExtents:: ; c056
	ds 8

wChannelVibratoRates:: ; c05e
; high nybble is rate (counter reload value) and low nybble is counter.
; time between applications of vibrato.
	ds 8

wChannelFrequencyLowBytes:: ; c066
	ds 8

wChannelVibratoDelayCounterReloadValues:: ; c06e
; delay of the beginning of the vibrato from the start of the note
	ds 8

wChannelPitchSlideLengthModifiers:: ; c076
	ds 8

wChannelPitchSlideFrequencySteps:: ; c07e
	ds 8

wChannelPitchSlideFrequencyStepsFractionalPart:: ; c086
	ds 8

wChannelPitchSlideCurrentFrequencyFractionalPart:: ; c08e
	ds 8

wChannelPitchSlideCurrentFrequencyHighBytes:: ; c096
	ds 8

wChannelPitchSlideCurrentFrequencyLowBytes:: ; c09e
	ds 8

wChannelPitchSlideTargetFrequencyHighBytes:: ; c0a6
	ds 8

wChannelPitchSlideTargetFrequencyLowBytes:: ; c0ae
	ds 8

wChannelNoteDelayCounters:: ; c0b6
; Note delays are stored as 16-bit fixed-point numbers where the integer part
; is 8 bits and the fractional part is 8 bits.
	ds 8

wChannelLoopCounters:: ; c0be
	ds 8

wChannelNoteSpeeds:: ; c0c6
	ds 8

wChannelNoteDelayCountersFractionalPart:: ; c0ce
	ds 8

wChannelOctaves:: ; c0d6
	ds 8

wChannelVolumes:: ; c0de
; also includes fade for hardware channels that support it
	ds 8

wMusicWaveInstrument::
	ds 1

wSfxWaveInstrument::
	ds 1

wMusicTempo:: ; c0e8
	ds 2

wSfxTempo:: ; c0ea
	ds 2

wSfxHeaderPointer:: ; c0ec
	ds 2

wNewSoundID:: ; c0ee
	ds 1

; c0ef  
; 音楽再生時に `music header` のある ROMバンク番号を格納する(Music_XXXX e.g. Music_Pokecenter)  
wAudioROMBank::
	ds 1

wAudioSavedROMBank:: ; c0f0
	ds 1

wFrequencyModifier:: ; c0f1
	ds 1

wTempoModifier:: ; c0f2
	ds 1

	ds 13


SECTION "Sprite State Data", WRAM0

; **wSpriteDataStart**  
; 
; 現在のマップ上のスプライトのデータを保持している領域
wSpriteDataStart::

; c100  
; 現在のマップに配置されたすべてのスプライトのデータ   
; 16スプライト分の領域がある(1つのスプライトにつき16バイト)
; プレイヤーのスプライトは常に0番目の領域に配置される
;  
; - C1x0: picture ID (定数、マップ初期化時に読み込まれる)  
; - C1x1: 現在のスプライトの動作状況 (0: 未初期化, 1: 準備完了, 2: 遅延中, 3: 動作中)  
; - C1x2: スプライトのイメージ番号(スプライトの更新時に変化 $ffなら画面非表示で、特定の方向を向いたり、歩きモーション中だったりスプライト特有のオフセットのときと、いろいろな変化があり、それを示す番号)  
; - C1x3: スプライトのY座標変化 (-1/0/1のどれか スプライトの更新時にC1x4に加算される)   
; - C1x4: スプライトのY座標 (ピクセル単位 常にグリッド(16*16)の4ピクセル上にあるため、スプライトはタイルの中央に表示される 立体的に見せるため)  
; - C1x5: スプライトのX座標変化 (-1/0/1のどれか スプライトの更新時にC1x6に加算される)  
; - C1x6: スプライトのX座標 (ピクセル単位 移動中でないならグリッド(16*16)にぴったりおさまる)  
; - C1x7: 0から4までのフレームカウンタ 4になるとc1x8がインクリメントされる 歩きモーションなどのアニメーションのフレームカウントに利用  
; - C1x8: 0から3までのカウンタ 歩きモーションなどのアニメーションの状態を表すのに利用 つまり歩きモーションには16フレームかかる 
; - C1x9: スプライトの方向 (0: 下, 4: 上, 8: 左, $c: 右)  
; - C1xA: (16*16px) のグリッド単位での Y座標 つまり ([c1x4] + 4)/16
; - C1xB: (16*16px) のグリッド単位での X座標 つまり [c1x6]/16
; - C1xC: ???  
; - C1xD: ???  
; - C1xE: ???  
; - C1xF: ???  
wSpriteStateData1::
spritestatedata1: MACRO
\1PictureID:: db
\1MovementStatus:: db
\1ImageIndex:: db
\1YStepVector:: db
\1YPixels:: db
\1XStepVector:: db
\1XPixels:: db
\1IntraAnimFrameCounter:: db
\1AnimFrameCounter:: db
\1FacingDirection:: db
	ds 6
\1End::
endm

; 主人公のスプライト合わせて16スプライト分
wSpritePlayerStateData1::  spritestatedata1 wSpritePlayerStateData1
wSprite01StateData1::      spritestatedata1 wSprite01StateData1
wSprite02StateData1::      spritestatedata1 wSprite02StateData1
wSprite03StateData1::      spritestatedata1 wSprite03StateData1
wSprite04StateData1::      spritestatedata1 wSprite04StateData1
wSprite05StateData1::      spritestatedata1 wSprite05StateData1
wSprite06StateData1::      spritestatedata1 wSprite06StateData1
wSprite07StateData1::      spritestatedata1 wSprite07StateData1
wSprite08StateData1::      spritestatedata1 wSprite08StateData1
wSprite09StateData1::      spritestatedata1 wSprite09StateData1
wSprite10StateData1::      spritestatedata1 wSprite10StateData1
wSprite11StateData1::      spritestatedata1 wSprite11StateData1
wSprite12StateData1::      spritestatedata1 wSprite12StateData1
wSprite13StateData1::      spritestatedata1 wSprite13StateData1
wSprite14StateData1::      spritestatedata1 wSprite14StateData1
wSprite15StateData1::      spritestatedata1 wSprite15StateData1

; c200
; 現在のマップに配置されたすべてのスプライトのデータその2  
; 16スプライト分の領域がある(1つのスプライトにつき16バイト)
; プレイヤーのスプライトは常に0番目の領域に配置される
; 
; - C2x0: 歩きモーションのアニメーションカウンタ ($10から移動した分だけ減っていく)
; - C2x1: ???
; - C2x2: Y 変化量 (8で初期化 スプライトが初期座標から離れすぎないために設定されていると考えられるがバグがある)
; - C2x3: X 変化量 (8で初期化 スプライトが初期座標から離れすぎないために設定されていると考えられるがバグがある)
; - C2x4: Y 座標 (2*2のグリッド単位, 一番上のグリッドにいるときは4となる)
; - C2x5: X 座標 (2*2のグリッド単位, 一番左のグリッドにいるときは4となる)
; - C2x6: movement byte 1(スプライトの動きを決めるデータ) ($ff:動かない, $fe:ランダムに歩く, それ以外は未使用)
; - C2x7: 用途不明 (草むらにスプライトがいるとき$80になってそれ以外では$0になっている おそらくスプライトの上に草むらを描画するのに利用)
; - C2x8: 次の動きまでのクールタイム (どんどん減って行って, 0になるとC1x1が1にセットされる)
; - C2x9: ???
; - C2xA: ???
; - C2xB: ???
; - C2xC: ???
; - C2xD: SPRITE_RED など spriteIDが入る LoadMapSpriteTilePatternsで使われた後は 0クリアされる
; - C2xE: VRAMオフセット (スプライトのタイルデータがVRAMのどのアドレスにあるか) (主人公は常に1, C1x2で使用する) 画面非表示から表示に戻すときに必要になる？
; - C2xF: ???
wSpriteStateData2::
spritestatedata2: MACRO
\1WalkAnimationCounter:: db
	ds 1
\1YDisplacement:: db
\1XDisplacement:: db
\1MapY:: db
\1MapX:: db
\1MovementByte1:: db
\1GrassPriority:: db
\1MovementDelay:: db
	ds 5
\1ImageBaseOffset:: db
	ds 1
\1End::
endm

wSpritePlayerStateData2::  spritestatedata2 wSpritePlayerStateData2
wSprite01StateData2::      spritestatedata2 wSprite01StateData2
wSprite02StateData2::      spritestatedata2 wSprite02StateData2
wSprite03StateData2::      spritestatedata2 wSprite03StateData2
wSprite04StateData2::      spritestatedata2 wSprite04StateData2
wSprite05StateData2::      spritestatedata2 wSprite05StateData2
wSprite06StateData2::      spritestatedata2 wSprite06StateData2
wSprite07StateData2::      spritestatedata2 wSprite07StateData2
wSprite08StateData2::      spritestatedata2 wSprite08StateData2
wSprite09StateData2::      spritestatedata2 wSprite09StateData2
wSprite10StateData2::      spritestatedata2 wSprite10StateData2
wSprite11StateData2::      spritestatedata2 wSprite11StateData2
wSprite12StateData2::      spritestatedata2 wSprite12StateData2
wSprite13StateData2::      spritestatedata2 wSprite13StateData2
wSprite14StateData2::      spritestatedata2 wSprite14StateData2
wSprite15StateData2::      spritestatedata2 wSprite15StateData2


wSpriteDataEnd::

; Object Attribute Memory(スプライトテーブル)
SECTION "OAM Buffer", WRAM0

; c300  
; OAM DMAで転送されるデータ(160バイト)を格納しておくバッファ
wOAMBuffer::
	ds 4 * 40

; c3a0  
; スクリーンのタイルIDを格納したバッファ(32*32ではなく見えている範囲の20*18枚分のみ)
wTileMap::
	ds 20 * 18

wSerialPartyMonsPatchList:: ; c508
; list of indexes to patch with SERIAL_NO_DATA_BYTE after transfer

; c508  
; 一時的に画面上のタイルを保持しておくバッファ  
; 例えばメニューをマップの上に上書きして表示する際に下のマップデータを保持しておくのに利用される  
;	ds 20 * 18
wTileMapBackup::
	ds 200

wSerialEnemyMonsPatchList:: ; c5d0
; list of indexes to patch with SERIAL_NO_DATA_BYTE after transfer
	ds 200

	ds 80

; c6e8
wTempPic::

; c6e8  
wOverworldMap::
	ds 1300
wOverworldMapEnd::

; cbfc  
; RedrawRowOrColumn で再描画する 1行分 or 1列分　のタイルID  
wRedrawRowOrColumnSrcTiles::
	ds SCREEN_WIDTH * 2 ; 16px なので *2

; cc24  
; アイテム選択メニューで一番上(id 0)のカーソルの位置の Y coords  
wTopMenuItemY:: 
	ds 1
; cc25  
; アイテム選択メニューで一番上(id 0)のカーソルの位置の X coords  
wTopMenuItemX::
	ds 1

; cc26  
; 現在アイテム選択メニューで選択されているアイテムを表すID  
; 一番上のアイテムはIDが0、1つ下はIDが1となる  
; 一番上のアイテムというのは現在画面で見えている一番上のアイテムのことを指すことに注意  
; このスクリーン上のオフセットに[wListScrollOffset]を加えることでメニューリスト中の本当のアイテムオフセットを得る  
wCurrentMenuItem::
	ds 1

; cc27  
; the tile that was behind the menu cursor's current location  
; メニューカーソルの現在の位置でのタイルアドレス
wTileBehindCursor::
	ds 1

; cc28  
; menuの一番下の項目のID(画面に表示されているもののオフセット)  
; e.g. 2択menuなら Yes No の2つなので 0, 1 なので 1になる  
; e.g. listmenu なら上から4つ目の項目にカーソルがいくとスクロールするので 2  
wMaxMenuItem::
	ds 1

; cc29  
; キー入力のうち、入力されたときになんらかの反応をしめすキーの一覧  
; [↓, ↑, ←, →, Start, Select, B, A]
wMenuWatchedKeys::
	ds 1

; cc2a  
; 最後に選択されたメニューアイテムのID  
; 選択された場所を記録しておいて次に開いたときにそこにカーソルを合わせたいときに使う?  
wLastMenuItem::
	ds 1

; cc2b  
; 主に手持ちのmenu画面でカーソル位置を記憶しておくのに利用される  
; 
; 他にも、ポケモン選択したときやサブmenuを開いた時にカーソル位置が失われない様にマサキのPCのポケモンのlist menuのカーソル位置の記憶にも使われる  
; ただし、マサキのPCを終了すればリセットされる  
wPartyAndBillsPCSavedMenuItem::
	ds 1

wBagSavedMenuItem:: ; cc2c
; It is used by the bag list to remember the cursor position while the menu
; isn't active.
	ds 1

wBattleAndStartSavedMenuItem:: ; cc2d
; It is used by the start menu to remember the cursor position while the menu
; isn't active.
; The battle menu uses it so that the cursor position doesn't get lost when
; a sub-menu is shown. It's reset at the start of each battle.
	ds 1

wPlayerMoveListIndex:: ; cc2e
	ds 1

wPlayerMonNumber:: ; cc2f
; index in party of currently battling mon
	ds 1

; cc30  
; メニューカーソルの現在の位置に対応するwTileMapのアドレス  
; e.g. メニューカーソルが(1, 1)(8px単位)にあったら wTileMapの(1, 1)のアドレス
wMenuCursorLocation::
	ds 2

	ds 2

; cc34  
; HandleMenuInputがリターンする前に何回キー入力のチェックを行うかを定義  
; キー入力に回数制限を設けたいときに設定
wMenuJoypadPollCount::
	ds 1

; cc35  
; 順番入れ替えのために選択されているメニューアイテムのオフセット(1からカウント)  
; この値が0の場合はどのアイテムも順番入れ替えのために選択されていない状態であることを意味する  
wMenuItemToSwap::
	ds 1

; cc36  
; 現在画面一番上に表示されているアイテムのメニューでのオフセット  
; リストのどのセクションが画面上に表示されているかを取得するのに利用される  
wListScrollOffset::
	ds 1

; cc37  
; 0でないときには、menu wrap が無効になり、 menu の一番上や一番下の先を選択しようとすると HandleMenuInput からリターンする  
; 
; この設定はmenuのitemが一度に画面に表示しきれないくらい多いときにmenuをスクロールさせるために必要である  
wMenuWatchMovingOutOfBounds::
	ds 1

wTradeCenterPointerTableIndex:: ; cc38
	ds 1

	ds 1

; cc3a  
; テキスト出力先を表すポインタ  
; 書き込まれることはあれど読み込まれていることはなさそう  
wTextDest::
	ds 2

; cc3c  
; 0でないならDisplayTextIDでのテキストの描画の後にボタンが押されるのを待機する処理をスキップする  
wDoNotWaitForButtonPressAfterDisplayingText::
	ds 1

wSerialSyncAndExchangeNybbleReceiveData:: ; cc3d
; the final received nybble is stored here by Serial_SyncAndExchangeNybble

wSerialExchangeNybbleTempReceiveData:: ; cc3d
; temporary nybble used by Serial_ExchangeNybble

wLinkMenuSelectionReceiveBuffer:: ; cc3d
; two byte buffer
; the received menu selection is stored twice
	ds 1

wSerialExchangeNybbleReceiveData:: ; cc3e
; the final received nybble is stored here by Serial_ExchangeNybble
	ds 1

	ds 3

wSerialExchangeNybbleSendData:: ; cc42
; this nybble is sent when using Serial_SyncAndExchangeNybble or Serial_ExchangeNybble

wLinkMenuSelectionSendBuffer:: ; cc42
; two byte buffer
; the menu selection byte is stored twice before sending

	ds 5

wLinkTimeoutCounter:: ; cc47
; 1 byte

wUnknownSerialCounter:: ; cc47
; 2 bytes

; cc47
wEnteringCableClub::
	ds 1

	ds 1

; cc49
; $00 = player mons
; $01 = enemy mons
wWhichTradeMonSelectionMenu::

; cc49  
; 0 = 主人公の手持ち  
; 1 = 相手の手持ち  
; 2 = 現在のPCBox  
; 3 = 育て屋  
; 4 = 戦闘中のポケモン  
; 
; ただし AddPartyMonでは 異なる使われ方をする  
; - 下位ニブルが 0 なら ポケモンは主人公の手持ちに、 そうでないならライバルの手持ちに  
; - 値が 0 なら 主人公は 加わったポケモンのニックネームを変更可能  
wMonDataLocation::
	ds 1

; cc4a  
; menu wrapできる場合に1にセットされる   
wMenuWrappingEnabled::
	ds 1

; cc4b  
; whether to check for 180-degree turn (0 = don't, 1 = do)
wCheckFor180DegreeTurn::
	ds 1

	ds 1

wMissableObjectIndex:: ; cc4d
	ds 1

wPredefID:: ; cc4e
	ds 1
wPredefRegisters:: ; cc4f
	ds 6

; cc55
wTrainerHeaderFlagBit::
	ds 1

	ds 1

; cc57  
; どの NPC movment script が実行されているかを表すポインタ  
; - - -  
; 0x00: NPC movement scriptが実行されていない  
; 0x01: PalletMovementScriptPointerTable  
; 0x02: PewterMuseumGuyMovementScriptPointerTable  
; 0x03: PewterGymGuyMovementScriptPointerTable  
wNPCMovementScriptPointerTableNum::
	ds 1

; cc58  
; 現在の NPC movement script が格納されているROMバンク  
wNPCMovementScriptBank::
	ds 1

	ds 2

wUnusedCC5B:: ; cc5b

wVermilionDockTileMapBuffer:: ; cc5b
; 180 bytes

wOaksAideRewardItemName:: ; cc5b

; cc5b
wDexRatingNumMonsSeen::

; cc5b  
; 飲み物や化石など、特定の種類のアイテムにフィルターされたかばんのアイテムのリスト
wFilteredBagItems::

wElevatorWarpMaps:: ; cc5b

; cc5b  
; OAMのアニメーションの1つ目のフレームを保存しておく 60バイト の領域  
; 保存しておくことで 2つ目のフレームから戻るのが楽になる  
; (OAMのアニメーションは2つのフレーム(モーション)から成り立っていることに留意)
wMonPartySpritesSavedOAM::

wTrainerCardBlkPacket:: ; cc5b
; $40 bytes

wSlotMachineSevenAndBarModeChance:: ; cc5b
; If a random number greater than this value is generated, then the player is
; allowed to have three 7 symbols or bar symbols line up.
; So, this value is actually the chance of NOT entering that mode.
; If the slot is lucky, it equals 250, giving a 5/256 (~2%) chance.
; Otherwise, it equals 253, giving a 2/256 (~0.8%) chance.

; cc5b  
; [wHoFTeamIndex]回目の殿堂入りデータ  
; - - -  
; sHallOfFame[wHoFTeamIndex]
wHallOfFame::

wBoostExpByExpAll:: ; cc5b

; cc5b  
; 0-6の値  
; Shake screen horizontally, shake screen vertically, blink Pokemon...
wAnimationType::

; cc5b
wNPCMovementDirections::
	ds 1

; cc5c
wDexRatingNumMonsOwned::
	ds 1

wDexRatingText:: ; cc5d
	ds 1

wSlotMachineSavedROMBank:: ; cc5e
; ROM back to return to when the player is done with the slot machine
	ds 1

	ds 26

wAnimPalette:: ; cc79
	ds 1

	ds 29

; cc97  
; scripted NPC のためのスプライトの移動方向をここから格納していく  
; 
; 例えば　上 -> 右 と動くなら  
; [cc97] = NPC_MOVEMENT_UP  
; [cc98] = NPC_MOVEMENT_RIGHT  
; [cc99] = 0xff  
wNPCMovementDirections2::

; cc97  
; temporary buffer when swapping party mon data
wSwitchPartyMonTempBuffer::
	ds 10

; cca1  
; used in Pallet Town scripted movement  
wNumStepsToTake::
	ds 49

wRLEByteCount:: ; ccd2
	ds 1

wAddedToParty:: ; ccd3
; 0 = not added
; 1 = added

; ccd3  
; ここから simulated joypad の キー入力方向を1マスずつ記録していく  
; 詳しくは [simulated joypad](docs/simulated_joypad.md)参照  
; このアドレスは他の用途でも使用される  
wSimulatedJoypadStatesEnd::

; ccd3  
; ネストしたメニューがあるとき、現在操作中のメニューから見た親メニューのオフセット  
wParentMenuItem::

wCanEvolveFlags:: ; ccd3
; 1 flag for each party member indicating whether it can evolve
; The purpose of these flags is to track which mons levelled up during the
; current battle at the end of the battle when evolution occurs.
; Other methods of evolution simply set it by calling TryEvolvingMon.
	ds 1

; ccd4
wForceEvolution::
	ds 1

; if [ccd5] != 1, the second AI layer is not applied
wAILayer2Encouragement:: ; ccd5
	ds 1
	ds 1

; current HP of player and enemy substitutes
wPlayerSubstituteHP:: ; ccd7
	ds 1
wEnemySubstituteHP:: ; ccd8
	ds 1

wTestBattlePlayerSelectedMove:: ; ccd9
; The player's selected move during a test battle.
; InitBattleVariables sets it to the move Pound.
	ds 1

	ds 1

wMoveMenuType:: ; ccdb
; 0=regular, 1=mimic, 2=above message box (relearn, heal pp..)
	ds 1

wPlayerSelectedMove:: ; ccdc
	ds 1
wEnemySelectedMove:: ; ccdd
	ds 1

wLinkBattleRandomNumberListIndex:: ; ccde
	ds 1

wAICount:: ; ccdf
; number of times remaining that AI action can occur
	ds 1

	ds 2

wEnemyMoveListIndex:: ; cce2
	ds 1

wLastSwitchInEnemyMonHP:: ; cce3
; The enemy mon's HP when it was switched in or when the current player mon
; was switched in, which was more recent.
; It's used to determine the message to print when switching out the player mon.
	ds 2

wTotalPayDayMoney:: ; cce5
; total amount of money made using Pay Day during the current battle
	ds 3

wSafariEscapeFactor:: ; cce8
	ds 1
wSafariBaitFactor:: ; cce9
	ds 1;

	ds 1

wTransformedEnemyMonOriginalDVs:: ; cceb
	ds 2

wMonIsDisobedient:: ds 1 ; cced

wPlayerDisabledMoveNumber:: ds 1 ; ccee
wEnemyDisabledMoveNumber:: ds 1 ; ccef

wInHandlePlayerMonFainted:: ; ccf0
; When running in the scope of HandlePlayerMonFainted, it equals 1.
; When running in the scope of HandleEnemyMonFainted, it equals 0.
	ds 1

wPlayerUsedMove:: ds 1 ; ccf1
wEnemyUsedMove:: ds 1 ; ccf2

wEnemyMonMinimized:: ds 1 ; ccf3

wMoveDidntMiss:: ds 1 ; ccf4

wPartyFoughtCurrentEnemyFlags:: ; ccf5
; flags that indicate which party members have fought the current enemy mon
	flag_array 6

wLowHealthAlarmDisabled:: ; ccf6
; Whether the low health alarm has been disabled due to the player winning the
; battle.
	ds 1

wPlayerMonMinimized:: ; ccf7
	ds 1

	ds 13

wLuckySlotHiddenObjectIndex:: ; cd05

wEnemyNumHits:: ; cd05
; number of hits by enemy in attacks like Double Slap, etc.

wEnemyBideAccumulatedDamage:: ; cd05
; the amount of damage accumulated by the enemy while biding (2 bytes)

	ds 10

wInGameTradeGiveMonSpecies:: ; cd0f

wPlayerMonUnmodifiedLevel:: ; cd0f
	ds 1

wInGameTradeTextPointerTablePointer:: ; cd10

wPlayerMonUnmodifiedMaxHP:: ; cd10
	ds 2

wInGameTradeTextPointerTableIndex:: ; cd12

wPlayerMonUnmodifiedAttack:: ; cd12
	ds 1
wInGameTradeGiveMonName:: ; cd13
	ds 1
wPlayerMonUnmodifiedDefense:: ; cd14
	ds 2
wPlayerMonUnmodifiedSpeed:: ; cd16
	ds 2
wPlayerMonUnmodifiedSpecial:: ; cd18
	ds 2

; stat modifiers for the player's current pokemon
; value can range from 1 - 13 ($1 to $D)
; 7 is normal

wPlayerMonStatMods::
wPlayerMonAttackMod:: ; cd1a
	ds 1
wPlayerMonDefenseMod:: ; cd1b
	ds 1
wPlayerMonSpeedMod:: ; cd1c
	ds 1
wPlayerMonSpecialMod:: ; cd1d
	ds 1

wInGameTradeReceiveMonName:: ; cd1e

wPlayerMonAccuracyMod:: ; cd1e
	ds 1
wPlayerMonEvasionMod:: ; cd1f
	ds 1

	ds 3

wEnemyMonUnmodifiedLevel:: ; cd23
	ds 1
wEnemyMonUnmodifiedMaxHP:: ; cd24
	ds 2
wEnemyMonUnmodifiedAttack:: ; cd26
	ds 2
wEnemyMonUnmodifiedDefense:: ; cd28
	ds 1

wInGameTradeMonNick:: ; cd29
	ds 1

wEnemyMonUnmodifiedSpeed:: ; cd2a
	ds 2
wEnemyMonUnmodifiedSpecial:: ; cd2c
	ds 1

wEngagedTrainerClass:: ; cd2d
	ds 1
wEngagedTrainerSet:: ; cd2e
;	ds 1

; stat modifiers for the enemy's current pokemon
; value can range from 1 - 13 ($1 to $D)
; 7 is normal

wEnemyMonStatMods::
wEnemyMonAttackMod:: ; cd2e
	ds 1
wEnemyMonDefenseMod:: ; cd2f
	ds 1
wEnemyMonSpeedMod:: ; cd30
	ds 1
wEnemyMonSpecialMod:: ; cd31
	ds 1
wEnemyMonAccuracyMod:: ; cd32
	ds 1
wEnemyMonEvasionMod:: ; cd33
	ds 1

wInGameTradeReceiveMonSpecies::
	ds 1

	ds 2

; cd37  
; wNPCMovementDirections2 の何バイト目が処理対象かを示すインデックス
wNPCMovementDirections2Index::

wUnusedCD37:: ; cd37

; cd37
; 配列 wFilteredBagItems の要素の個数
wFilteredBagItemsCount::
	ds 1

; cd38  
; 次に勝手に入力されるキー入力は、 wSimulatedJoypadStatesEnd にこの値から1を引いた値を足したもの  
; つまり wSimulatedJoypadStatesEnd + [wSimulatedJoypadStatesIndex] - 1  
; 0 ならキー入力はシミュレートされていない(ポケモン赤によって勝手にキー入力されている状態ではない)
wSimulatedJoypadStatesIndex::
	ds 1

wWastedByteCD39:: ; cd39
; written to but nothing ever reads it
	ds 1

; cd3a  
; データが書き込まれてはいるが、読みだされている様子はない
wWastedByteCD3A::
	ds 1

; cd3b  
; bitが1の場所に該当するキー入力は実際のボタンを押すと simulated joypad で入力されたボタンをオーバーライドできる  
wOverrideSimulatedJoypadStatesMask::
	ds 1

	ds 1

wFallingObjectsMovementData:: ; cd3d
; up to 20 bytes (one byte for each falling object)

wSavedY:: ; cd3d

wTempSCX:: ; cd3d

wBattleTransitionCircleScreenQuadrantY:: ; cd3d
; 0 = upper half (Y < 9)
; 1 = lower half (Y >= 9)

wBattleTransitionCopyTilesOffset:: ; cd3d
; 2 bytes
; after 1 row/column has been copied, the offset to the next one to copy from

wInwardSpiralUpdateScreenCounter:: ; cd3d
; counts down from 7 so that every time 7 more tiles of the spiral have been
; placed, the tile map buffer is copied to VRAM so that progress is visible

wHoFTeamIndex:: ; cd3d

wSSAnneSmokeDriftAmount:: ; cd3d
; multiplied by 16 to get the number of times to go right by 2 pixels

wRivalStarterTemp:: ; cd3d

wBoxMonCounts:: ; cd3d
; 12 bytes
; array of the number of mons in each box

wDexMaxSeenMon:: ; cd3d

wPPRestoreItem:: ; cd3d

wWereAnyMonsAsleep:: ; cd3d

wCanPlaySlots:: ; cd3d

wNumShakes:: ; cd3d

wDayCareStartLevel:: ; cd3d
; the level of the mon at the time it entered day care

wWhichBadge:: ; cd3d

wPriceTemp:: ; cd3d
; 3-byte BCD number

; cd3d  
; タイトル画面で表示されているポケモンのIDを保持  
wTitleMonSpecies::

; cd3d  
; タイトル画面で主人公を表示するとき、タイルをOAMにループ処理で配置していく  
; その際、ループで配置するタイル番号を格納する
wPlayerCharacterOAMTile::

wMoveDownSmallStarsOAMCount:: ; cd3d
; the number of small stars OAM entries to move down

wChargeMoveNum:: ; cd3d

wCoordIndex:: ; cd3d

wOptionsTextSpeedCursorX:: ; cd3d

; cd3d
wBoxNumString::

wTrainerInfoTextBoxWidthPlus1:: ; cd3d

wSwappedMenuItem:: ; cd3d

; cd3d  
; `LeaguePCShowMon` で今表示しているポケモンの ポケモンID
wHoFMonSpecies::

; cd3d  
; 4 bytes  
; 処理中のポケモンが覚えているフィールドで使える技  
; 1 = cut  
; 2 = fly  
; 3 = surf  
; 4 = surf  
; 5 = strength  
; 6 = flash  
; 7 = dig  
; 8 = teleport  
; 9 = softboiled  
wFieldMoves::

; cd3d  
; 8 byte  
; トレーナーカードでバッジの左上に表示される番号のタイルのタイル番号
wBadgeNumberTile::

; cd3d  
; 0 = no bite  
; 1 = bite  
; 2 = no fish on map  
wRodResponse::

; cd3d  
wWhichTownMapLocation::

wStoppingWhichSlotMachineWheel:: ; cd3d
; which wheel the player is trying to stop
; 0 = none, 1 = wheel 1, 2 = wheel 2, 3 or greater = wheel 3

wTradedPlayerMonSpecies:: ; cd3d

wTradingWhichPlayerMon:: ; cd3d

wChangeBoxSavedMapTextPointer:: ; cd3d

; cd3d  
; `DoFlyAnimation` で 鳥 に羽ばたきながら移動させるか、その場で羽ばたかせるかを決める
; 0x00: 移動する  
; 0xff: その場で羽ばたく  
wFlyAnimUsingCoordList::

; cd3d  
wPlayerSpinInPlaceAnimFrameDelay::

; cd3d
wPlayerSpinWhileMovingUpOrDownAnimDeltaY::

; cd3d  
wHiddenObjectFunctionArgument::

; cd3d
; which entry from TradeMons to select  
wWhichTrade::

; cd3d  
; トレーナーに関する処理で、処理対象のトレーナーのスプライトオフセットを格納する(0xX0 の形で?)  
wTrainerSpriteOffset::

wUnusedCD3D:: ; cd3d
	ds 1

wHUDPokeballGfxOffsetX:: ; cd3e
; difference in X between the next ball and the current one

wBattleTransitionCircleScreenQuadrantX:: ; cd3e
; 0 = left half (X < 10)
; 1 = right half (X >= 10)

wSSAnneSmokeX:: ; cd3e

wRivalStarterBallSpriteIndex:: ; cd3e

wDayCareNumLevelsGrown:: ; cd3e

wOptionsBattleAnimCursorX:: ; cd3e

wTrainerInfoTextBoxWidth:: ; cd3e

wHoFPartyMonIndex:: ; cd3e

wNumCreditsMonsDisplayed:: ; cd3e
; the number of credits mons that have been displayed so far

; cd3e  
; トレーナーカードでジムリーダーの顔の上に表示される名前の最初のタイル番号  
wBadgeNameTile::

wFlyLocationsList:: ; cd3e
; 11 bytes plus $ff sentinel values at each end

wSlotMachineWheel1Offset:: ; cd3e

wTradedEnemyMonSpecies:: ; cd3e

wTradingWhichEnemyMon:: ; cd3e

; cd3e  
; `DoFlyAnimation` による そらをとぶ のアニメーションがあと何ループか記録している変数  
; 0 になったらアニメーションは終わる  
wFlyAnimCounter::

wPlayerSpinInPlaceAnimFrameDelayDelta:: ; cd3e

; cd3e
wPlayerSpinWhileMovingUpOrDownAnimMaxY::

wHiddenObjectFunctionRomBank:: ; cd3e

; cd3e  
; トレーナーの視界の長さ(16*16のマス単位)
wTrainerEngageDistance::
	ds 1

wHUDGraphicsTiles:: ; cd3f
; 3 bytes

wDayCareTotalCost:: ; cd3f
; 2-byte BCD number

wJigglypuffFacingDirections:: ; cd3f

wOptionsBattleStyleCursorX:: ; cd3f

wTrainerInfoTextBoxNextRowOffset:: ; cd3f

; cd3f  
; `LeaguePCShowMon` で今表示しているポケモンの レベル
wHoFMonLevel::

; cd3f  
; 8 bytes  
; 各ジムリーダーのところには 2×2タイル(16*16px) で ジムリーダーの顔 か バッジ が配置される  
; ここはその 2×2タイルのうちの最初のタイル番号を8つ集めたもの  
wBadgeOrFaceTiles::

wSlotMachineWheel2Offset:: ; cd3f

wNameOfPlayerMonToBeTraded:: ; cd3f

; cd3f  
; `DoFlyAnimation` による そらをとぶ のアニメーションで、各コマごとに $c102 に格納される値  
wFlyAnimBirdSpriteImageIndex::

; cd3f
wPlayerSpinInPlaceAnimFrameDelayEndValue::

; cd3f  
; プレイヤーをスピンさせる(方向転換させる)処理のディレイ間隔  
; スピンさせる(方向転換させる)処理: 1回転ではなく、 ↓ から ← や ← から ↑ への1方向転換  
wPlayerSpinWhileMovingUpOrDownAnimFrameDelay::

wHiddenObjectIndex:: ; cd3f

; cd3f  
; トレーナーに関する処理で処理対象のトレーナーの向いている方向を格納する  
wTrainerFacingDirection::
	ds 1

; cd40  
; show mon or show player?  
; 0 = mon  
; 1 = player  
wHoFMonOrPlayer::

wSlotMachineWheel3Offset:: ; cd40

; cd40
wPlayerSpinInPlaceAnimSoundID::

wHiddenObjectY:: ; cd40

wTrainerScreenY:: ; cd40

wUnusedCD40:: ; cd40
	ds 1

wDayCarePerLevelCost:: ; cd41
; 2-byte BCD number (always set to $0100)

wHoFTeamIndex2:: ; cd41

wHiddenItemOrCoinsIndex:: ; cd41

wTradedPlayerMonOT:: ; cd41

wHiddenObjectX:: ; cd41

wSlotMachineWinningSymbol:: ; cd41
; the OAM tile number of the upper left corner of the winning symbol minus 2

wNumFieldMoves:: ; cd41

wSlotMachineWheel1BottomTile:: ; cd41

wTrainerScreenX:: ; cd41
	ds 1
; a lot of the uses for these values use more than the said address

; cd42
wHoFTeamNo::

wSlotMachineWheel1MiddleTile:: ; cd42

wFieldMovesLeftmostXCoord:: ; cd42
	ds 1

wLastFieldMoveID:: ; cd43
; unused

wSlotMachineWheel1TopTile:: ; cd43
	ds 1

wSlotMachineWheel2BottomTile:: ; cd44
	ds 1

wSlotMachineWheel2MiddleTile:: ; cd45
	ds 1

wTempCoins1:: ; cd46
; 2 bytes
; temporary variable used to add payout amount to the player's coins

wSlotMachineWheel2TopTile:: ; cd46
	ds 1

wBattleTransitionSpiralDirection:: ; cd47
; 0 = outward, 1 = inward

wSlotMachineWheel3BottomTile:: ; cd47
	ds 1

wSlotMachineWheel3MiddleTile:: ; cd48

; cd48  
; ここから4バイトほどプレイヤーの方向データが入り、プレイヤーをスピンさせるときに利用される  
; また、1つ前の cd47 は一時的なバッファとしてプレイヤーの回転処理の際に利用される  
wFacingDirectionList::
	ds 1

wSlotMachineWheel3TopTile:: ; cd49

; cd49  
; トレーナーカード閲覧時にバッジを表示するために使われる一時的な 8byte の領域  
; 各バイトが各バッジに対応している  
; 0 => 未取得 1 => 取得済み  
wTempObtainedBadgesBooleans::
	ds 1

wTempCoins2:: ; cd4a
; 2 bytes
; temporary variable used to subtract the bet amount from the player's coins

wPayoutCoins:: ; cd4a
; 2 bytes
	ds 2

wTradedPlayerMonOTID:: ; cd4c

wSlotMachineFlags:: ; cd4c
; These flags are set randomly and control when the wheels stop.
; bit 6: allow the player to win in general
; bit 7: allow the player to win with 7 or bar (plus the effect of bit 6)
	ds 1

wSlotMachineWheel1SlipCounter:: ; cd4d
; wheel 1 can "slip" while this is non-zero

; cd4d  
; いあいぎりで切る対象を格納する  
; $3d = 木のタイル  
; $52 = 草のタイル  
wCutTile::
	ds 1

wSlotMachineWheel2SlipCounter:: ; cd4e
; wheel 2 can "slip" while this is non-zero

wTradedEnemyMonOT:: ; cd4e
	ds 1

wSavedPlayerScreenY:: ; cd4f

wSlotMachineRerollCounter:: ; cd4f
; The remaining number of times wheel 3 will roll down a symbol until a match is
; found, when winning is enabled. It's initialized to 4 each bet.

; cd4f  
; Emotion Bubbleを表示する対象のスプライトのオフセット
wEmotionBubbleSpriteIndex::
	ds 1

; cd50
wWhichEmotionBubble::

wSlotMachineBet:: ; cd50
; how many coins the player bet on the slot machine (1 to 3)

wSavedPlayerFacingDirection:: ; cd50

; cd50  
; 0 = いあいぎりアニメーション時に設定  
; 1 = かいりきの土埃アニメーション時に設定  
wWhichAnimationOffsets::
	ds 9

wTradedEnemyMonOTID:: ; cd59
	ds 2

wStandingOnWarpPadOrHole:: ; cd5b
; 0 = neither
; 1 = warp pad
; 2 = hole

wOAMBaseTile:: ; cd5b

wGymTrashCanIndex:: ; cd5b
	ds 1

wSymmetricSpriteOAMAttributes:: ; cd5c
	ds 1

wMonPartySpriteSpecies:: ; cd5d
	ds 1

wLeftGBMonSpecies:: ; cd5e
; in the trade animation, the mon that leaves the left gameboy
	ds 1

wRightGBMonSpecies:: ; cd5f
; in the trade animation, the mon that leaves the right gameboy
	ds 1

; cd60  
; bit 0: `TrainerEngage`でプレイヤーがトレーナーに見つかったか (複数のトレーナーに同時に見つかった時は発見されてないことにする)  
; bit 1: かいりきのアニメーション再生を待機中  
; bit 2: 1 ならトレーナーに発見されたかの判定を OverworldLoopで行う  
; bit 3: 普通のPCを使っているか (0ならマサキのパソコンを使用している)  
; bit 4: 1 -> .skipMovingSprites  
; bit 5: 1なら menu で A/Bボタンが押された時にサウンドをならさない  
; bit 6: 一度かいりきの岩を押してみた状態か (you need to push twice before it will move)  
wFlags_0xcd60::
	ds 1

	ds 9

; cd6a  
; This has overlapping related uses.  
; プレイヤーが道具かフィールド技を使う時は、その結果が成功なら 1、失敗なら 0 になる  
; 
; In addition, some items store 2 for certain types of failures, but this
; cannot happen in battle.
; 
; In battle, a non-zero value indicates the player has taken their turn using
; something other than a move (e.g. using an item or switching pokemon).
; 
; So, when an item is successfully used in battle, this value becomes non-zero
; and the player is not allowed to make a move and the two uses are compatible.
wActionResultOrTookBattleTurn::
	ds 1

; cd6b  
; [↓, ↑, ←, →, Start, Select, B, A] でビットが1のボタンはキー入力が無視される
wJoyIgnore::
	ds 1

wDownscaledMonSize:: ; cd6c
; size of downscaled mon pic used in pokeball entering/exiting animation
; $00 = 5Ã—5
; $01 = 3Ã—3

wNumMovesMinusOne:: ; cd6c
; FormatMovesString stores the number of moves minus one here
	ds 1

UNION

; cd6d  
; 様々なデータを格納する 4byte のバッファ
wcd6d:: ds 4

wStatusScreenCurrentPP:: ; cd71
; temp variable used to print a move's current PP on the status screen
	ds 1

	ds 6

wNormalMaxPPList:: ; cd78
; list of normal max PP (without PP up) values
	ds 9

NEXTU

wEvosMoves:: ds MAX_EVOLUTIONS * EVOLUTION_SIZE + 1
.end::

ENDU

wSerialOtherGameboyRandomNumberListBlock:: ; cd81
; buffer for transferring the random number list generated by the other gameboy

wTileMapBackup2:: ; cd81
; second buffer for temporarily saving and restoring current screen's tiles (e.g. if menus are drawn on top)
	ds 20 * 18

; cee9
wNamingScreenNameLength::

wEvoOldSpecies:: ; cee9

; cee9  
; 30バイトの汎用的なバッファ
wBuffer::
; Temporary storage area of 30 bytes.

; cee9  
; 下位ニブルが x, 上位ニブルが y  
wTownMapCoords::

; cee9  
; whether WriteMonMoves is being used to make a mon learn moves from day care  
; non-zero if so  
wLearningMovesFromDayCare::

wChangeMonPicEnemyTurnSpecies:: ; cee9

wHPBarMaxHP:: ; cee9
	ds 1

; ceea  
; プレイヤーが提出する名前を選択しているときに0以外の値をとる
; non-zero when the player has chosen to submit the name
wNamingScreenSubmitName::

wChangeMonPicPlayerTurnSpecies:: ; ceea

wEvoNewSpecies:: ; ceea
	ds 1

; ceeb  
; 0 = upper case  
; 1 = lower case  
wAlphabetCase::

wEvoMonTileOffset:: ; ceeb

wHPBarOldHP:: ; ceeb
	ds 1

wEvoCancelled:: ; ceec
	ds 1

; ceed
wNamingScreenLetter::

wHPBarNewHP:: ; ceed
	ds 2
wHPBarDelta:: ; ceef
	ds 1

wHPBarTempHP:: ; cef0
	ds 2

	ds 11

wHPBarHPDifference:: ; cefd
	ds 1
	ds 7

; cf05  
; the item that the AI used  
wAIItem::
	ds 1

wUsedItemOnWhichPokemon:: ; cf06
	ds 1

wAnimSoundID:: ; cf07
; sound ID during battle animations
	ds 1

wBankswitchHomeSavedROMBank:: ; cf08
; used as a storage value for the bank to return to after a BankswitchHome (bankswitch in homebank)
	ds 1

wBankswitchHomeTemp:: ; cf09
; used as a temp storage value for the bank to switch to
	ds 1

; cf0a  
; 0 = pokemartに何も買うものや売るものがない  
; 1 = pokemartに何か買うものや売るものがある  
; この値は特に使用されている様子はない
wBoughtOrSoldItemInMart::
	ds 1

; cf0b  
; $00: win  
; $01: lose  
; $02: draw  
wBattleResult::
	ds 1

; cf0c  
; bit0が1なら、DisplayTextIDで自動的にテキストボックスが描画される
wAutoTextBoxDrawingControl::
	ds 1

wcf0d:: ds 1 ; used with some overworld scripts (not exactly sure what it's used for)

wTilePlayerStandingOn:: ; cf0e
; used in CheckForTilePairCollisions2 to store the tile the player is on
	ds 1

; cf0f
wNPCNumScriptedSteps:: ds 1

; cf10  
; which script function within the pointer table indicated by wNPCMovementScriptPointerTableNum  
wNPCMovementScriptFunctionNum::
	ds 1

; cf11  
; bit 0: DisplayTextIDで現在のマップのバンクにスイッチしないようにPredefテキストを表示するときにセットされる
wTextPredefFlag::
	ds 1

; cf12  
wPredefParentBank::
	ds 1

; cf13  
; スプライトのオフセットが入る  
wSpriteIndex::
	ds 1

; cf14  
; 現在処理中のスプライトの movement byte 2
wCurSpriteMovement2::
	ds 1

	ds 2

; cf17  
; NPC movement script によって制御されるスプライトのオフセット
wNPCMovementScriptSpriteOffset::
	ds 1

; cf18
wScriptedNPCWalkCounter::
	ds 1

	ds 1

; cf1a  
; GBなら 0 に、GBCなら 1 になる?  
; - - -  
; みたところ 0 しか入らない  
wGBC::
	ds 1

; cf1b  
; SGB上でプレイされているとき1、それ以外は0
wOnSGB::
	ds 1

; cf1c  
; SGBのときに利用するパレットを識別するためのIDを格納する  
wDefaultPaletteCommand:: 
	ds 1

wPlayerHPBarColor:: ; cf1d

wWholeScreenPaletteMonSpecies:: ; cf1d
; species of the mon whose palette is used for the whole screen
	ds 1

wEnemyHPBarColor:: ; cf1e
	ds 1

; cf1f  
; パーティの各ポケモンのHPゲージの色を格納しておく6バイトの領域(6匹なので6バイト)  
; 0: green
; 1: yellow
; 2: red
wPartyMenuHPBarColors::
	ds 6

wStatusScreenHPBarColor:: ; cf25
	ds 1

	ds 7

wCopyingSGBTileData:: ; cf2d

; cf2d  
; 手持ちのどのポケモンのHPゲージを処理しているか
wWhichPartyMenuHPBar::

; cf2d
wPalPacket::
	ds 1

; cf2e  
; 手持ち一覧の画面で使うパレットのデータが格納される？  
; - - -  
; wPalPacketと合わせて合計30バイト  
wPartyMenuBlkPacket::
	ds 29

; cf4b
; 2-byte big-endian number
; the total amount of exp a mon gained
wExpAmountGained::

; 2バイトの様々な文字を格納しておくバッファ
wcf4b:: ds 2

wGainBoostedExp:: ; cf4d
	ds 1

	ds 17

; cf5f  
; 現在の街の名前が入る(ジムがある街のみ)  
wGymCityName::
	ds 17

; cf70  
; 現在の街のジムリーダーの名前が入る
wGymLeaderName::
	ds NAME_LENGTH

; cf7b
wItemList::
	ds 16

; cf8b  
; listの先頭のアドレスを格納する  
; e.g. OldManItemList, wPartyCount
wListPointer::
	ds 2

wUnusedCF8D:: ; cf8d
; 2 bytes
; used to store pointers, but never read
	ds 2

; cf8f  
wItemPrices::
	ds 2

; cf91  
; 様々な値を格納するのに使われる  
wcf91:: ds 1

; cf92  
; RemoveItemFromInventory の対象のオフセット(かばんの先頭を0, 1, 2, 3, 4, ...)  
wRemoveItemIndex::

; cf92  
; list menu で選択した項目のoffset (画面表示中のものではなく、list全体でのoffset)
wListMenuOffset::

; cf92
wFourTempCtr::

; cf92  
; どのポケモンがセレクトされているか  
wWhichPokemon::
	ds 1

; cf93  
; PrintListMenuEntriesで利用  
; 0でないときは、表示しているリストのアイテム価格を表示する  
wPrintItemPrices::
	ds 1

; cf94  
; DrawHP_で描画する HP bar のカテゴリ  
; $00 = enemy HUD in battle  
; $01 = player HUD in battle / status screen  
; $02 = party menu  
wHPBarType::

; cf94  
; DisplayListMenuIDで使われるID  
; list menu ID's以下のどれかを格納  
; PCPOKEMONLISTMENU  EQU $00  
; MOVESLISTMENU      EQU $01  
; PRICEDITEMLISTMENU EQU $02  
; ITEMLISTMENU       EQU $03  
; SPECIALLISTMENU    EQU $04  
wListMenuID::
	ds 1

; cf95  
; 0 = RemovePokemon で手持ちから削除  
; 1 = RemovePokemon でPCBoxから削除  
wRemoveMonFromBox::

; cf95  
; `MoveMon` の移動処理のタイプを決める変数  
; 0 = box -> party  
; 1 = party -> box  
; 2 = daycare -> party  
; 3 = party -> daycare  
wMoveMonType::
	ds 1

; cf96
wItemQuantity::
	ds 1

; cf97  
; list menu でかばんからアイテムを選んだ時のアイテムの個数  
wMaxItemQuantity::
	ds 1

; cf98  
; LoadMonData でロードした Pokemon Data がここに入る   
wLoadedMon:: party_struct wLoadedMon

; cfc4  
; bit 0:  プレイヤーやNPCの歩きモーションを保持するVRAM領域にフォントのタイルが格納されているときに立つフラグ  
; 歩きモーションのアニメーションがロードされていないのでこのフラグが立っているときはプレイヤーやNPCの動きは禁止される  
; 
; そのほかのbitは使われてない
wFontLoaded::
	ds 1

; cfc5  
; プレイヤーの歩きモーションカウンタ 最大8  
; 0 なら プレイヤーが現在歩きモーション中ではないことを表す
wWalkCounter::
	ds 1

; cfc6  
; プレイヤーの1歩 or 2歩前の座標のBGタイル番号
; background tile number in front of the player (either 1 or 2 steps ahead)
wTileInFrontOfPlayer::
	ds 1

; cfc7  
; `PlaySound` で新しいBGMを流すため現在のBGMを fade-out させるのにかかるフレーム数を格納する  
; ここに 0 を格納するとfade-outせず、すぐに次のBGMの再生が始まる  
; fade-out が終わった後はここに次に再生されるBGMの Sound ID が格納される  
; 
; `FadeOutAudio`はVBlankが来るたびにこの値が0でないかチェックし、0でないなら現在のBGMをfade-outさせる  
; BGMのfade-outが終了すると、この変数を0クリアして格納されたSound IDに対応するBGMの再生を始める  
wAudioFadeOutControl::
	ds 1

; cfc8  
; FadeOutAudio で wAudioFadeOutCounter が 0になったときこの値がセットされる
wAudioFadeOutCounterReloadValue::
	ds 1

; cfc9  
; VBlankごとに下がっていき、 0 になったときに現在の音量を 1落とす  
; fadeout 処理に利用される
wAudioFadeOutCounter::
	ds 1

wLastMusicSoundID:: ; cfca
; This is used to determine whether the default music is already playing when
; attempting to play the default music (in order to avoid restarting the same
; music) and whether the music has already been stopped when attempting to
; fade out the current music (so that the new music can be begin immediately
; instead of waiting).
; It sometimes contains the sound ID of the last music played, but it may also
; contain $ff (if the music has been stopped) or 0 (because some routines zero
; it in order to prevent assumptions from being made about the current state of
; the music).
	ds 1

; cfcb  
; $00 = スプライトを表示しなくして、そのあと$ffに変化する  
; $01 = `UpdateSprites` を有効化  
; $ff = `UpdateSprites` を無効化  
; それ以外の値は取らない
wUpdateSpritesEnabled::
	ds 1

wEnemyMoveNum:: ; cfcc
	ds 1
wEnemyMoveEffect:: ; cfcd
	ds 1
wEnemyMovePower:: ; cfce
	ds 1
wEnemyMoveType:: ; cfcf
	ds 1
wEnemyMoveAccuracy:: ; cfd0
	ds 1
wEnemyMoveMaxPP:: ; cfd1
	ds 1
wPlayerMoveNum:: ; cfd2
	ds 1
wPlayerMoveEffect:: ; cfd3
	ds 1
wPlayerMovePower:: ; cfd4
	ds 1
wPlayerMoveType:: ; cfd5
	ds 1
wPlayerMoveAccuracy:: ; cfd6
	ds 1
wPlayerMoveMaxPP:: ; cfd7
	ds 1


wEnemyMonSpecies2:: ; cfd8
	ds 1

; cfd9
wBattleMonSpecies2::
	ds 1

wEnemyMonNick:: ds NAME_LENGTH ; cfda

wEnemyMon:: battle_struct wEnemyMon ; cfe5

wEnemyMonBaseStats:: ds 5
wEnemyMonActualCatchRate:: ds 1
wEnemyMonBaseExp:: ds 1

wBattleMonNick:: ds NAME_LENGTH ; d009
wBattleMon:: battle_struct wBattleMon ; d014

; d031
wTrainerClass::
	ds 1

	ds 1

wTrainerPicPointer:: ; d033
	ds 2
	ds 1

wTempMoveNameBuffer:: ; d036

wLearnMoveMonName:: ; d036
; The name of the mon that is learning a move.
	ds 16

wTrainerBaseMoney:: ; d046
; 2-byte BCD number
; money received after battle = base money Ã— level of highest-level enemy mon
	ds 2

wMissableObjectCounter:: ; d048
	ds 1

	ds 1

wTrainerName:: ; d04a
; 13 bytes for the letters of the opposing trainer
; the name is terminated with $50 with possible
; unused trailing letters
	ds 13

; d057  
; バトル中かを管理するフラグ
; 
; - lost battle, this is -1
; - no battle, this is 0
; - wild battle, this is 1
; - trainer battle, this is 2
wIsInBattle::
	ds 1

wPartyGainExpFlags:: ; d058
; flags that indicate which party members should be be given exp when GainExperience is called
	flag_array 6

; d059  
; 戦闘中じゃない -> 0  
; 野生ポケモンの場合 -> ポケモンの種類  
; トレーナーの場合 -> trainer class + OPP_ID_OFFSET  
wCurOpponent::
	ds 1

; d05a  
; 通常のバトル -> 0  
; トキワシティの老人によるポケモン捕獲デモ -> 1  
; サファリゾーンでのバトル -> 2
wBattleType::
	ds 1

; d05b  
; bits 0-6: Effectiveness  
;  $0 = ダメージなし  
;  $5 = いまひとつ  
;  $a = ふつう  
; $14 = 効果抜群  
; 
; bit 7: STAB  
wDamageMultipliers::
	ds 1

wLoneAttackNo:: ; d05c
; which entry in LoneAttacks to use
wGymLeaderNo:: ; d05c
; it's actually the same thing as ^
	ds 1
wTrainerNo:: ; d05d
; which instance of [youngster, lass, etc] is this?
	ds 1

wCriticalHitOrOHKO:: ; d05e
; $00 = normal attack
; $01 = critical hit
; $02 = successful OHKO
; $ff = failed OHKO
	ds 1

wMoveMissed:: ; d05f
	ds 1

wPlayerStatsToDouble:: ; d060
; always 0
	ds 1

wPlayerStatsToHalve:: ; d061
; always 0
	ds 1

wPlayerBattleStatus1:: ; d062
; bit 0 - bide
; bit 1 - thrash / petal dance
; bit 2 - attacking multiple times (e.g. double kick)
; bit 3 - flinch
; bit 4 - charging up for attack
; bit 5 - using multi-turn move (e.g. wrap)
; bit 6 - invulnerable to normal attack (using fly/dig)
; bit 7 - confusion
	ds 1

wPlayerBattleStatus2:: ; d063
; bit 0 - X Accuracy effect
; bit 1 - protected by "mist"
; bit 2 - focus energy effect
; bit 4 - has a substitute
; bit 5 - need to recharge
; bit 6 - rage
; bit 7 - leech seeded
	ds 1

wPlayerBattleStatus3:: ; d064
; bit 0 - toxic
; bit 1 - light screen
; bit 2 - reflect
; bit 3 - transformed
	ds 1

wEnemyStatsToDouble:: ; d065
; always 0
	ds 1

wEnemyStatsToHalve:: ; d066
; always 0
	ds 1

wEnemyBattleStatus1:: ; d067
	ds 1
wEnemyBattleStatus2:: ; d068
	ds 1
wEnemyBattleStatus3:: ; d069
	ds 1

wPlayerNumAttacksLeft::
; when the player is attacking multiple times, the number of attacks left
	ds 1

wPlayerConfusedCounter:: ; d06b
	ds 1

wPlayerToxicCounter:: ; d06c
	ds 1

wPlayerDisabledMove:: ; d06d
; high nibble: which move is disabled (1-4)
; low nibble: disable turns left
	ds 1

	ds 1

wEnemyNumAttacksLeft:: ; d06f
; when the enemy is attacking multiple times, the number of attacks left
	ds 1

wEnemyConfusedCounter:: ; d070
	ds 1

wEnemyToxicCounter:: ; d071
	ds 1

wEnemyDisabledMove:: ; d072
; high nibble: which move is disabled (1-4)
; low nibble: disable turns left
	ds 1

	ds 1

wPlayerNumHits:: ; d074
; number of hits by player in attacks like Double Slap, etc.

wPlayerBideAccumulatedDamage:: ; d074
; the amount of damage accumulated by the player while biding (2 bytes)

wUnknownSerialCounter2:: ; d074
; 2 bytes

	ds 4

wEscapedFromBattle::
; non-zero when an item or move that allows escape from battle was used
	ds 1

wAmountMoneyWon:: ; d079
; 3-byte BCD number

wObjectToHide:: ; d079
	ds 1

wObjectToShow:: ; d07a
	ds 1

	ds 1

wDefaultMap:: ; d07c
; the map you will start at when the debug bit is set

wMenuItemOffset:: ; d07c

wAnimationID:: ; d07c
; ID number of the current battle animation
	ds 1

; d07d  
; 0: NAME_PLAYER_SCREEN  
; 1: NAME_RIVAL_SCREEN  
; 2: NAME_MON_SCREEN
wNamingScreenType::

; d07d  
; menuType(x < $F0のとき) or messageID(x >= $F0のとき)  
; 
; 00: normal pokemon menu (e.g. Start menu)  
; 01: use healing item on pokemon menu  
; 02: in-battle switch pokemon menu  
; 03: learn TM/HM menu  
; 04: swap pokemon positions menu  
; 05: use evolution stone on pokemon menu  
; 
; f0: poison healed  
; f1: burn healed  
; f2: freeze healed  
; f3: sleep healed  
; f4: paralysis healed  
; f5: HP healed  
; f6: health returned  
; f7: revitalized  
; f8: leveled up  
wPartyMenuTypeOrMessageID::

wTempTilesetNumTiles:: ; d07d
; temporary storage for the number of tiles in a tileset
	ds 1

; d07e  
; pokemartのNPCに話しかけたときに現在のwListScrollOffsetを保存しておく領域   
; pokemart NPCとの会話が終わった後にwListScrollOffsetに復帰される
wSavedListScrollOffset::
	ds 1

	ds 2

; base coordinates of frame block
wBaseCoordX:: ; d081
	ds 1
wBaseCoordY:: ; d082
	ds 1

; low health alarm counter/enable
; high bit = enable, others = timer to cycle frequencies
wLowHealthAlarm:: ds 1 ; d083

; d084  
; counts how many tiles of the current frame block have been drawn
wFBTileCounter::
	ds 1

; d085
wMovingBGTilesCounter2::
	ds 1

wSubAnimFrameDelay:: ; d086
; duration of each frame of the current subanimation in terms of screen refreshes
	ds 1
wSubAnimCounter:: ; d087
; counts the number of subentries left in the current subanimation
	ds 1

; d088  
; 1 = セーブデータが存在しない or セーブデータが壊れている  
; 2 = 正常なセーブデータが存在  
wSaveFileStatus::
	ds 1

wNumFBTiles:: ; d089
; number of tiles in current battle animation frame block
	ds 1

wFlashScreenLongCounter:: ; d08a

wSpiralBallsBaseY:: ; d08a

wFallingObjectMovementByte:: ; d08a
; bits 0-6: index into FallingObjects_DeltaXs array (0 - 8)
; bit 7: direction; 0 = right, 1 = left

wNumShootingBalls:: ; d08a

wTradedMonMovingRight:: ; d08a
; $01 if mon is moving from left gameboy to right gameboy; $00 if vice versa

; d08a
wOptionsInitialized::

wNewSlotMachineBallTile:: ; d08a

; d08a  
; `AdjustOAMBlockXPos2`や`AdjustOAMBlockYPos2` で OAMの X/Y coord にどれだけ値を加えるか(変化量)
wCoordAdjustmentAmount::

wUnusedD08A:: ; d08a
	ds 1

wSpiralBallsBaseX:: ; d08b

wNumFallingObjects:: ; d08b

wSlideMonDelay:: ; d08b

; d08b  
; 様々なアニメーションで使われるカウンター
wAnimCounter::

wSubAnimTransform:: ; d08b
; controls what transformations are applied to the subanimation
; 01: flip horizontally and vertically
; 02: flip horizontally and translate downwards 40 pixels
; 03: translate base coordinates of frame blocks, but don't change their internal coordinates or flip their tiles
; 04: reverse the subanimation
	ds 1

; d08c  
; プレイヤーがトレーナーに勝った時にトレーナーの言うテキストを格納  
wEndBattleWinTextPointer::
	ds 2

; d08e  
; プレイヤーがトレーナーに負けた時にトレーナーの言うテキストを格納  
wEndBattleLoseTextPointer::
	ds 2

	ds 2

; d092  
; プレイヤーがトレーナーに勝った/負けた時にトレーナーの言うテキストのあるバング番号 
wEndBattleTextRomBank::
	ds 1

	ds 1

wSubAnimAddrPtr:: ; d094
; the address _of the address_ of the current subanimation entry
	ds 2

wSlotMachineAllowMatchesCounter:: ; d096
; If non-zero, the allow matches flag is always set.
; There is a 1/256 (~0.4%) chance that this value will be set to 60, which is
; the only way it can increase. Winning certain payout amounts will decrement it
; or zero it.

wSubAnimSubEntryAddr:: ; d096
; the address of the current subentry of the current subanimation
	ds 2

	ds 2

wOutwardSpiralTileMapPointer:: ; d09a
	ds 1

; d09b  
wPartyMenuAnimMonEnabled::

; d09b  
; タウンマップのカーソルを開いた時に1を入れて、Exitするときに 0になる  
; この値にかかわらずタウンマップ時にはカーソルが点滅している  
wTownMapSpriteBlinkingEnabled::

wUnusedD09B:: ; d09b
	ds 1

wFBDestAddr:: ; d09c
; current destination address in OAM for frame blocks (big endian)
	ds 2

wFBMode:: ; d09e
; controls how the frame blocks are put together to form frames
; specifically, after finishing drawing the frame block, the frame block's mode determines what happens
; 00: clean OAM buffer and delay
; 02: move onto the next frame block with no delay and no cleaning OAM buffer
; 03: delay, but don't clean OAM buffer
; 04: delay, without cleaning OAM buffer, and do not advance [wFBDestAddr], so that the next frame block will overwrite this one
	ds 1

wLinkCableAnimBulgeToggle:: ; d09f
; 0 = small
; 1 = big

wIntroNidorinoBaseTile:: ; d09f

wOutwardSpiralCurrentDirection:: ; d09f

wDropletTile:: ; d09f

wNewTileBlockID:: ; d09f

wWhichBattleAnimTileset:: ; d09f

wSquishMonCurrentDirection:: ; d09f
; 0 = left
; 1 = right

wSlideMonUpBottomRowLeftTile:: ; d09f
; the tile ID of the leftmost tile in the bottom row in AnimationSlideMonUp_
	ds 1

wDisableVBlankWYUpdate:: ds 1 ; if non-zero, don't update WY during V-blank

wSpriteCurPosX:: ; d0a1
	ds 1
wSpriteCurPosY:: ; d0a2
	ds 1
wSpriteWidth:: ; d0a3
	ds 1
wSpriteHeight:: ; d0a4
	ds 1
wSpriteInputCurByte:: ; d0a5
; current input byte
	ds 1

; d0a6  
; wSpriteInputPtrのバイトデータを 1bit読み進める ReadNextInputBit関数 で最後に呼んだbitのoffset  
; - - -  
; offsetが0のときに ReadNextInputBit関数 を呼ぶと次のバイトのbitを読む  
wSpriteInputBitCounter::
	ds 1

; d0a7  
; WriteSpriteBitsToBuffer で 読み取った 2bit の値を output buffer にどのように書き込むかを決定する  
; output buffer の各byteは 2bppフォーマットのためのものであり、4つの列に分けられる  
; MoveToNextBufferPosition で 読み進めるとデクリメントされる  
; 
; 3 -> XX000000   1st column  
; 2 -> 00XX0000   2nd column  
; 1 -> 0000XX00   3rd column  
; 0 -> 000000XX   4th column  
wSpriteOutputBitOffset::
	ds 1

; d0a8  
; bit 0: 使用するbufferを選択する (0 -> sSpriteBuffer1, 1 -> sSpriteBuffer2)  
; bit 1: 最後のスプライトの最後のチャンクをロードするかを決めるフラグ(0:ロードする 1:しない)(各ロード操作では最大2チャンクしかロードしない)
wSpriteLoadFlags::
	ds 1

; d0a9  
; 0   -> mode 0  
; 1 0 -> mode 1  
; 1 1 -> mode 2  
wSpriteUnpackMode::
	ds 1

; d0aa  
; 対象のスプライトが左右反転しているかのフラグ
wSpriteFlipped::
	ds 1

; d0ab  
; pointer to next input byte  
wSpriteInputPtr::
	ds 2

; d0ad  
; pointer to current output byte
wSpriteOutputPtr::
	ds 2

; d0af  
; used to revert pointer for different bit offsets  
wSpriteOutputPtrCached::
	ds 2

; d0b1  
; pointer to differential decoding table (assuming initial value 0)  
; differential decoding の デコード方法を格納するテーブル(最初の値は0)  
wSpriteDecodeTable0Ptr::
	ds 2

; d0b3  
; pointer to differential decoding table (assuming initial value 1)  
; differential decoding の デコード方法を格納するテーブルその2(最初の値は1)  
wSpriteDecodeTable1Ptr::
	ds 2

; d0b5  
; ポケモンの種類(ID)を一時的に格納する場所として使われる他、戦闘に関するデータを保持したりする  
wd0b5:: ds 1

; d0b6  
; GetName でどのカテゴリの名前を取得するかを決める変数  
; 
; MONSTER_NAME  EQU 1  
; MOVE_NAME     EQU 2  
; ???_NAME      EQU 3  
; ITEM_NAME     EQU 4  
; PLAYEROT_NAME EQU 5  
; ENEMYOT_NAME  EQU 6  
; TRAINER_NAME  EQU 7  
wNameListType::
	ds 1

wPredefBank:: ; d0b7
	ds 1

wMonHeader:: ; d0b8

; d0b8  
; 元は図鑑番号が入っているがポケモンヘッダがWRAMにコピーされたときはポケモンの内部番号(ポケモンID)が入る
wMonHIndex::
	ds 1

wMonHBaseStats:: ; d0b9
wMonHBaseHP:: ; d0b9
	ds 1
wMonHBaseAttack:: ; d0ba
	ds 1
wMonHBaseDefense:: ; d0bb
	ds 1
wMonHBaseSpeed:: ; d0bc
	ds 1
wMonHBaseSpecial:: ; d0bd
	ds 1

wMonHTypes:: ; d0be
wMonHType1:: ; d0be
	ds 1
wMonHType2:: ; d0bf
	ds 1

wMonHCatchRate:: ; d0c0
	ds 1
wMonHBaseEXP:: ; d0c1
	ds 1
wMonHSpriteDim:: ; d0c2
	ds 1
wMonHFrontSprite:: ; d0c3
	ds 2
wMonHBackSprite:: ; d0c5
	ds 2

wMonHMoves:: ; d0c7
	ds NUM_MOVES

; d0cb
wMonHGrowthRate::
	ds 1

; d0cc  
; ds 7 (56bit)  
; 初代の技マシンは秘伝マシン含めて 55 (50 + 5)  
; 
; 各bitがそのポケモンがその技マシンを覚えられるかのフラグになっている(1bitは余り)  
wMonHLearnset::
	flag_array 50 + 5	; 初代の技マシンの数は 50, 秘伝マシンは 5
	ds 1

wSavedTilesetType:: ; d0d4
; saved at the start of a battle and then written back at the end of the battle
	ds 1

	ds 2


wDamage:: ; d0d7
	ds 2

	ds 2

wRepelRemainingSteps:: ; d0db
	ds 1

wMoves:: ; d0dc
; list of moves for FormatMovesString
	ds 4

; d0e0  
; 引数として技マシンの番号を格納する領域  
; CanLearnTM などで使われる  
; 秘伝マシンは 1 -> 51, 2 -> 52, ...
wMoveNum::
	ds 1

wMovesString:: ; d0e1
	ds 56

wUnusedD119:: ; d119
	ds 1

; d11a  
; wWalkBikeSurfState の値がしばしばここにコピーされるが、特に使われている様子はない
wWalkBikeSurfStateCopy::
	ds 1

wInitListType:: ; d11b
; the type of list for InitList to init
	ds 1

; d11c  
; 0 if no mon was captured  
wCapturedMonSpecies::
	ds 1

wFirstMonsNotOutYet:: ; d11d
; Non-zero when the first player mon and enemy mon haven't been sent out yet.
; It prevents the game from asking if the player wants to choose another mon
; when the enemy sends out their first mon and suppresses the "no will to fight"
; message when the game searches for the first non-fainted mon in the party,
; which will be the first mon sent out.
	ds 1

wPokeBallCaptureCalcTemp:: ; d11e

; d11e  
; upper nybble: ボールで捕まえるまでに行うアニメーションの数  
; lower nybble: ボールで捕まえるまでに行う判定の回数(ゆれ1, ゆれ2, ゆれ3, 捕獲)  
wPokeBallAnimData::

wUsingPPUp:: ; d11e

wMaxPP:: ; d11e

; 0 for player, non-zero for enemy
wCalculateWhoseStats:: ; d11e

wTypeEffectiveness:: ; d11e

wMoveType:: ; d11e

wNumSetBits:: ; d11e

; used as a Pokemon and Item storage value. Also used as an output value for CountSetBits  
; ポケモンやアイテムストレージの値として使われる。またCountSetBitsの結果を格納するのにも利用される
wd11e:: ds 1

; d11f  
; この値が 1 なら、プレイヤーは手持ち画面を Bボタンで抜けることができない
wForcePlayerToChooseMon::
	ds 1

wNumRunAttempts::
; number of times the player has tried to run from battle
	ds 1

wEvolutionOccurred:: ; d121
	ds 1

wVBlankSavedROMBank:: ; d122
	ds 1

	ds 1

wIsKeyItem:: ; d124
	ds 1

; d125  
; `DisplayTextBoxID_` で描画するテキストボックスのタイプを格納する  
; MESSAGE_BOX                       EQU $01  
; FIELD_MOVE_MON_MENU               EQU $04  
; JP_MOCHIMONO_MENU_TEMPLATE        EQU $05  
; USE_TOSS_MENU_TEMPLATE            EQU $06  
; JP_SAVE_MESSAGE_MENU_TEMPLATE     EQU $08  
; JP_SPEED_OPTIONS_MENU_TEMPLATE    EQU $09  
; BATTLE_MENU_TEMPLATE              EQU $0b  
; SWITCH_STATS_CANCEL_MENU_TEMPLATE EQU $0c  
; LIST_MENU_BOX                     EQU $0d  
; BUY_SELL_QUIT_MENU_TEMPLATE       EQU $0e  
; MONEY_BOX_TEMPLATE                EQU $0f  
; MON_SPRITE_POPUP                  EQU $11  
; JP_AH_MENU_TEMPLATE               EQU $12  
; MONEY_BOX                         EQU $13  
; TWO_OPTION_MENU                   EQU $14  
; BUY_SELL_QUIT_MENU                EQU $15  
; JP_POKEDEX_MENU_TEMPLATE          EQU $1a  
; SAFARI_BATTLE_MENU_TEMPLATE       EQU $1b  
wTextBoxID::
	ds 1

wCurrentMapScriptFlags:: ds 1 ; not exactly sure what this is used for, but it seems to be used as a multipurpose temp flag value

wCurEnemyLVL:: ; d127
	ds 1

; d128  
; $FFを終端記号とするアイテムのリストへのポインタ
wItemListPointer::
	ds 2

; d12a  
; リストのエントリの数(メニューアイテムのリスト?)  
wListCount::
	ds 1

wLinkState:: ; d12b
	ds 1

; d12c  
; bit0-3: TwoOptionMenuStrings の対象エントリ(0~7)を指定する  
; bit7 = select second menu item by default?  
wTwoOptionMenuID::
	ds 1

; d12d  
; プレイヤーが最終的に選んだアイテムのID
wChosenMenuItem::

wOutOfBattleBlackout:: ; d12d
; non-zero when the whole party has fainted due to out-of-battle poison damage
	ds 1

; d12e  
; ユーザーが menu からどのように抜けたかを記録している
; 
; buy/sell/quitメニューの場合  
; $01 = ユーザーがAボタンでアイテムを選択した  
; $02 = ユーザーがBボタンでキャンセルした  
; 
; 2択メニューの場合:  
; $01 = 上のアイテムでAボタンを押した  
; $02 = Bボタンを押したか、下のアイテムでAボタンを押した  
wMenuExitMethod::
	ds 1

wDungeonWarpDataEntrySize:: ; d12f
; the size is always 6, so they didn't need a variable in RAM for this

; d12f  
; 0 = museum guy  
; 1 = gym guy  
wWhichPewterGuy::

wWhichPrizeWindow:: ; d12f
; there are 3 windows, from 0 to 2

wGymGateTileBlock:: ; d12f
; a horizontal or vertical gate block
	ds 1

wSavedSpriteScreenY:: ; d130
	ds 1

wSavedSpriteScreenX:: ; d131
	ds 1

wSavedSpriteMapY:: ; d132
	ds 1

wSavedSpriteMapX:: ; d133
	ds 1

	ds 5

wWhichPrize:: ; d139
	ds 1

; d13a  
; このアドレスの値は各フレームごとにデクリメントされていく  
; 0になったとき、wd730[5](キー入力を無視するフラグ)がクリアされる  
wIgnoreInputCounter::
	ds 1

; d13b  
; counts down once every step
wStepCounter::
	ds 1

wNumberOfNoRandomBattleStepsLeft:: ; d13c
; after a battle, you have at least 3 steps before a random battle can occur
	ds 1

wPrize1:: ; d13d
	ds 1
wPrize2:: ; d13e
	ds 1
wPrize3:: ; d13f
	ds 1

	ds 1

wSerialRandomNumberListBlock:: ; d141
; the first 7 bytes are the preamble

wPrize1Price:: ; d141
	ds 2

wPrize2Price:: ; d143
	ds 2

wPrize3Price:: ; d145
	ds 2

	ds 1

wLinkBattleRandomNumberList:: ; d148
; shared list of 9 random numbers, indexed by wLinkBattleRandomNumberListIndex
	ds 10

wSerialPlayerDataBlock:: ; d152
; the first 6 bytes are the preamble

; d152  
; あなをほる は 内部処理ではあなぬけのひも を使ったことにしている  
; ここにはそのようなアクションをとったときに擬似的に使われたことにするアイテムIDを格納する  
; 
; 実際に道具を使った時はここには 0 が入る  
; 
; 例:  
; Dig -> ESCAPE_ROPE  
; Surf -> SURFBOARD("?????" という没アイテム)  
wPseudoItemID::
	ds 1

wUnusedD153:: ; d153
	ds 1

	ds 2

; d156
; `ItemUseEvoStone` で使う進化の石のアイテムIDを格納する
wEvoStoneItemID::
	ds 1

wSavedNPCMovementDirections2Index:: ; d157
	ds 1

; d158  
; プレイヤーの名前が入る  
; ゲーム内で名前が必要なときはここから読み取る  
wPlayerName::
	ds NAME_LENGTH


wPartyDataStart::

; d163  
; 現在の手持ちの数  
; 直下のwPartySpeciesと合わせてlist(各エントリにポケモンの内部ID=1バイト)を形成している  
wPartyCount::   ds 1
wPartySpecies:: ds PARTY_LENGTH	; d164 各エントリにはポケモンID(1バイト)が格納される [ID, ID, ID, ID, ID, ID]
wPartyEnd::     ds 1 ; d16a

; 手持ちのポケモンのPokemon Dataのテーブル(要素数6)
wPartyMons::
wPartyMon1:: party_struct wPartyMon1 ; d16b
wPartyMon2:: party_struct wPartyMon2 ; d197
wPartyMon3:: party_struct wPartyMon3 ; d1c3
wPartyMon4:: party_struct wPartyMon4 ; d1ef
wPartyMon5:: party_struct wPartyMon5 ; d21b
wPartyMon6:: party_struct wPartyMon6 ; d247

; d273    
; NAME_LENGTH * PARTY_LENGTH = 11 * 6 = 66バイトの領域  
wPartyMonOT::    ds NAME_LENGTH * PARTY_LENGTH

; d2b5  
; NAME_LENGTH * PARTY_LENGTH = 11 * 6 = 66バイトの領域  
wPartyMonNicks:: ds NAME_LENGTH * PARTY_LENGTH

wPartyDataEnd::


wMainDataStart::

; d30a  
; 151÷8 = 19(切り上げ)  
; ポケモンを捕まえていたら対応するbitが立つ
wPokedexOwned:: ; d2f7
	flag_array NUM_POKEMON
wPokedexOwnedEnd::

; d30a  
; 151÷8 = 19(切り上げ)
wPokedexSeen::
	flag_array NUM_POKEMON
wPokedexSeenEnd::

; d31d  
; バッグのアイテム数  
; そのあとにwBagItemsが続いているためバッグのインベントリのリストとしても使われる
wNumBagItems::
	ds 1

; d31e  
; かばんの中身を表す配列  
; 各要素は[アイテムID,　数量]で2バイト  
; 最後に終端記号用の1バイト
wBagItems::
	ds BAG_ITEM_CAPACITY * 2
	ds 1 ; end

; d347  
; BCDフォーマットでプレイヤーの所持金を表す
wPlayerMoney::
	ds 3 ; BCD

wRivalName:: ; d34a
	ds NAME_LENGTH

; d355  
; bit 7 = バトルアニメーション  
; 	0: On  
; 	1: Off  
; 
; bit 6 = せんとうスタイル  
; 	0: いれかえ  
; 	1: かちぬき  
; 
; bits 0-3 = 文字の速さ(一文字描画するごとに何フレーム遅延するか)  
; 	1: はやい  
; 	3: ふつう  
; 	5: おそい  
wOptions::
	ds 1

; d356  
; バッジの取得フラグ  
; 1byte で 各bit が1なら取得済み  
wObtainedBadges::
	flag_array 8

	ds 1

; d358  
; bit 0: 0なら1フレームの遅延 1は遅延無し  
; bit 1: 0なら遅延なし
wLetterPrintingDelayFlags:: 
	ds 1

; d359  
; プレイヤーのID  
wPlayerID::
	ds 2

; d35b
wMapMusicSoundID::
	ds 1

; d35c
wMapMusicROMBank::
	ds 1

; d35d  
; `LoadGBPal` で FadePal4 から差し引かれるオフセット  
; 通常は 0 だが、フラッシュが必要な暗いマップでは ここに 6 が入り、 `LoadGBPal`で FadePal4 ではなく FadePal2 が使用される  
wMapPalOffset::
	ds 1

; d35e  
; 現在のマップID
wCurMap::
	ds 1

; d35f  
; 現在の画面左上のブロックのポインタ(マップのブロックデータのどこかを指す)
wCurrentTileBlockMapViewPointer::
	ds 2

; d361  
; プレイヤーのマップ内のYCoord(16*16pxのタイルブロック単位)  
; 画面上ではない  
wYCoord::
	ds 1

; d362  
; プレイヤーのマップ内のXCoord(16*16pxのタイルブロック単位)  
; 画面上ではない  
wXCoord::
	ds 1

; d363  
; 現在のマップでのプレイヤーのY座標(ブロック単位)  
; マップ全体のブロックの一番上のブロックにいるとき0
wYBlockCoord::
	ds 1

; d364  
; 現在のマップでのプレイヤーのX座標(ブロック単位)  
; マップ全体のブロックの一番左のブロックにいるとき0
wXBlockCoord::
	ds 1

wLastMap:: ; d365
	ds 1

wUnusedD366:: ; d366
	ds 1

; d367  
; 現在のタイルセットのオフセット  
; タイルセットのオフセットは constants/tilesets.asm で定義されている  
; このアドレスを起点として下のアドレスに Map Header が次々と格納されていく  
wCurMapTileset::
	ds 1

; d368  
; マップの縦の長さ (32*32pxのブロック単位)
wCurMapHeight::
	ds 1

; d369  
; マップの長さ (32*32pxのブロック単位)
wCurMapWidth::
	ds 1

wMapDataPtr:: ; d36a
	ds 2

; d36c  
; 現在のマップのテキストテーブル(TextID -> テキスト のテーブル)を格納  
; e.g. PalletTown_TextPointers
wMapTextPtr::
	ds 2

; d36e  
; 現在のマップの map script  
; e.g. PalletTown_Script
wMapScriptPtr::
	ds 2

; d370  
; connection byte  
wMapConnections::
	ds 1

; d371  
; 現在のマップのコネクション情報(北)  
; 
; ここをベースアドレスとして 11byte 分マップのコネクションデータを格納する  
; コネクションデータの例 = `NORTH_MAP_CONNECTION PALLET_TOWN, ROUTE_1, 0, 0, Route1_Blocks`  
; 
; 0xff のときは コネクションがない つまり disabled
wMapConn1Ptr::
	ds 1

wNorthConnectionStripSrc:: ; d372
	ds 2

wNorthConnectionStripDest:: ; d374
	ds 2

wNorthConnectionStripWidth:: ; d376
	ds 1

wNorthConnectedMapWidth:: ; d377
	ds 1

wNorthConnectedMapYAlignment:: ; d378
	ds 1

wNorthConnectedMapXAlignment:: ; d379
	ds 1

wNorthConnectedMapViewPointer:: ; d37a
	ds 2

; d37c  
; 現在のマップのコネクション情報(南)
wMapConn2Ptr::
	ds 1

wSouthConnectionStripSrc:: ; d37d
	ds 2

wSouthConnectionStripDest:: ; d37f:
	ds 2

wSouthConnectionStripWidth:: ; d381
	ds 1

wSouthConnectedMapWidth:: ; d382
	ds 1

wSouthConnectedMapYAlignment:: ; d383
	ds 1

wSouthConnectedMapXAlignment:: ; d384
	ds 1

wSouthConnectedMapViewPointer:: ; d385
	ds 2

; d387  
; 現在のマップのコネクション情報(西)
wMapConn3Ptr::
	ds 1

wWestConnectionStripSrc:: ; d388
	ds 2

wWestConnectionStripDest:: ; d38a
	ds 2

wWestConnectionStripHeight:: ; d38c
	ds 1

wWestConnectedMapWidth:: ; d38d
	ds 1

wWestConnectedMapYAlignment:: ; d38e
	ds 1

wWestConnectedMapXAlignment:: ; d38f
	ds 1

wWestConnectedMapViewPointer:: ; d390
	ds 2

; d392  
; 現在のマップのコネクション情報(東)
wMapConn4Ptr::
	ds 1

wEastConnectionStripSrc:: ; d393
	ds 2

wEastConnectionStripDest:: ; d395
	ds 2

wEastConnectionStripHeight:: ; d397
	ds 1

wEastConnectedMapWidth:: ; d398
	ds 1

wEastConnectedMapYAlignment:: ; d399
	ds 1

wEastConnectedMapXAlignment:: ; d39a
	ds 1

wEastConnectedMapViewPointer:: ; d39b
	ds 2

; d39d  
; 現在のマップのスプライトセット (スプライトセットを構成する 11個の sprite picture ID)
wSpriteSet::
	ds 11

; d3a8  
; 現在のマップの sprite set ID
wSpriteSetID::
	ds 1

wObjectDataPointerTemp:: ; d3a9
	ds 2

	ds 2

; d3ad  
; マップの境界の外側に表示されるタイルのタイルID  
wMapBackgroundTile::
	ds 1

; d3ae  
; 現在のマップの warp の数
wNumberOfWarps::
	ds 1

; d3af  
; 現在のマップの warp のデータが格納されている  
; 各エントリは [y, x, destination warp id, destination map] の4バイト  
wWarpEntries::
	ds 128

wDestinationWarpID:: ; d42f
; if $ff, the player's coordinates are not updated when entering the map
	ds 1

	ds 128

wNumSigns:: ; d4b0
; number of signs in the current map (up to 16)
	ds 1

; d4b1  
; 現在のマップの signの coordを格納する  
; sign 1つにつき 2byte (Y, X)  
wSignCoords::
	ds 32

; d4d1  
; 現在のマップの signの TextID を格納する  
; wSignCoords の sign とオフセットが同じ  
wSignTextIDs::
	ds 16

; d4e1  
; 現在のマップのスプライトの数
wNumSprites::
	ds 1

; these two variables track the X and Y offset in blocks from the last special warp used
; they don't seem to be used for anything
wYOffsetSinceLastSpecialWarp:: ; d4e2
	ds 1
wXOffsetSinceLastSpecialWarp:: ; d4e3
	ds 1

; d4e4  
; スプライトごとに2バイト  
; [movement byte 2, テキストID]  
wMapSpriteData::
	ds 32

; d504  
; スプライトごとに2バイト  
; 
; スプライトがトレーナーの場合:  
; [trainer class, trainer number]  
; trainer number = trainer class内で スプライトを識別するためのID  
; 
; スプライトがアイテム(モンボアイコン)の場合:  
; [item ID, 0]  
; 
; 通常のスプライトの場合:  
; [0, 0]  
wMapSpriteExtraData::
	ds 32

; d524  
; マップの高さ (16*16pxのブロック単位)
wCurrentMapHeight2::
	ds 1

; d525
; マップの幅 (16*16pxのブロック単位)
wCurrentMapWidth2::
	ds 1

; d526  
; 画面の左上がVRAMのBGタイルマップでどこにあるか
wMapViewVRAMPointer::
	ds 2

; In the comments for the player direction variables below, "moving" refers to
; both walking and changing facing direction without taking a step.

; d528  
; もしプレイヤーが歩行中なら、現在歩行している方向 歩行中でないなら0  
; map scriptsはプレイヤーの向いている方向を変更するためにここに書き込みを行う  
wPlayerMovingDirection::
	ds 1

; d529  
; プレイヤーが最後に止まる前に動いていた方向
wPlayerLastStopDirection::
	ds 1

; d52a  
; プレイヤーが歩行中なら歩いている方向  
; プレイヤーが止まっているなら最後に歩いた方向  
; 
; PLAYER_DIR_RIGHT or PLAYER_DIR_LEFT or PLAYER_DIR_DOWN or PLAYER_DIR_UP   
wPlayerDirection::
	ds 1

; d52b  
; 現在のタイルセットの格納されているバンク  
wTilesetBank::
	ds 1

; d52c  
; ここから12バイトほどtileset headerを格納する領域が続く  
; タイルブロック(4*4のタイル=32*32px)からタイルへのマッピング
wTilesetBlocksPtr::
	ds 2

wTilesetGfxPtr:: ; d52e
	ds 2

; d530  
; プレイヤーが通行可能なタイルのリストのアドレスを格納する  
wTilesetCollisionPtr::
	ds 2

wTilesetTalkingOverTiles:: ; d532
	ds 3

; d535
wGrassTile::
	ds 1

	ds 4

wNumBoxItems:: ; d53a
	ds 1
wBoxItems:: ; d53b
; item, quantity
	ds PC_ITEM_CAPACITY * 2
	ds 1 ; end

; d5a0  
; bits 0-6: box number  
; bit 7: whether the player has changed boxes before  
wCurrentBoxNum::
	ds 2

; d5a2  
; number of HOF teams  
wNumHoFTeams::
	ds 1

wUnusedD5A3:: ; d5a3
	ds 1

; d5a4  
; プレイヤーのゲームコインの所持数を表すBCDフォーマットの数値
wPlayerCoins::
	ds 2

; d5a6  
; missable object の表示フラグを格納した bit列  
; bit が 1 なら非表示  
wMissableObjectFlags::
	ds 32
wMissableObjectFlagsEnd::

	ds 7

wd5cd:: ds 1 ; temp copy of c1x2 (sprite facing/anim)

; d5ce  
; 現在のマップの missable object(マップ上のアイテム) の情報を格納する  
; 
; 各エントリごとに2バイトのサイズ(最大17エントリ)  
; - スプライトのオフセット(現在のマップに依存)  
; - missable object の global offset (MapHS00を 0として対象の missable object が何番目のアイテムか)  
; 
; 終端記号として$FF  
wMissableObjectList::
	ds 17 * 2

; d5f0  
; ここから $c8 Byte ゲームを管理するフラグが続く
wGameProgressFlags::
wOaksLabCurScript:: ; d5f0
	ds 1

; d5f1  
; PalletTown_ScriptPointersのどの関数が実行されるかを決める
wPalletTownCurScript::
	ds 1
	ds 1
wBluesHouseCurScript:: ; d5f3
	ds 1
wViridianCityCurScript:: ; d5f4
	ds 1
	ds 2
wPewterCityCurScript:: ; d5f7
	ds 1
wRoute3CurScript:: ; d5f8
	ds 1
wRoute4CurScript:: ; d5f9
	ds 1
	ds 1
wViridianGymCurScript:: ; d5fb
	ds 1
wPewterGymCurScript:: ; d5fc
	ds 1
wCeruleanGymCurScript:: ; d5fd
	ds 1
wVermilionGymCurScript:: ; d5fe
	ds 1
wCeladonGymCurScript:: ; d5ff
	ds 1
wRoute6CurScript:: ; d600
	ds 1
wRoute8CurScript:: ; d601
	ds 1
wRoute24CurScript:: ; d602
	ds 1
wRoute25CurScript:: ; d603
	ds 1
wRoute9CurScript:: ; d604
	ds 1
wRoute10CurScript:: ; d605
	ds 1
wMtMoon1FCurScript:: ; d606
	ds 1
wMtMoonB2FCurScript:: ; d607
	ds 1
wSSAnne1FRoomsCurScript:: ; d608
	ds 1
wSSAnne2FRoomsCurScript:: ; d609
	ds 1
wRoute22CurScript:: ; d60a
	ds 1
	ds 1
wRedsHouse2FCurScript:: ; d60c
	ds 1
wViridianMartCurScript:: ; d60d
	ds 1
wRoute22GateCurScript:: ; d60e
	ds 1
wCeruleanCityCurScript:: ; d60f
	ds 1
	ds 7
wSSAnneBowCurScript:: ; d617
	ds 1
wViridianForestCurScript:: ; d618
	ds 1
wMuseum1FCurScript:: ; d619
	ds 1
wRoute13CurScript:: ; d61a
	ds 1
wRoute14CurScript:: ; d61b
	ds 1
wRoute17CurScript:: ; d61c
	ds 1
wRoute19CurScript:: ; d61d
	ds 1
wRoute21CurScript:: ; d61e
	ds 1
wSafariZoneGateCurScript:: ; d61f
	ds 1
wRockTunnelB1FCurScript:: ; d620
	ds 1
wRockTunnel1FCurScript:: ; d621
	ds 1
	ds 1
wRoute11CurScript:: ; d623
	ds 1
wRoute12CurScript:: ; d624
	ds 1
wRoute15CurScript:: ; d625
	ds 1
wRoute16CurScript:: ; d626
	ds 1
wRoute18CurScript:: ; d627
	ds 1
wRoute20CurScript:: ; d628
	ds 1
wSSAnneB1FRoomsCurScript:: ; d629
	ds 1
wVermilionCityCurScript:: ; d62a
	ds 1
wPokemonTower2FCurScript:: ; d62b
	ds 1
wPokemonTower3FCurScript:: ; d62c
	ds 1
wPokemonTower4FCurScript:: ; d62d
	ds 1
wPokemonTower5FCurScript:: ; d62e
	ds 1
wPokemonTower6FCurScript:: ; d62f
	ds 1
wPokemonTower7FCurScript:: ; d630
	ds 1
wRocketHideoutB1FCurScript:: ; d631
	ds 1
wRocketHideoutB2FCurScript:: ; d632
	ds 1
wRocketHideoutB3FCurScript:: ; d633
	ds 1
wRocketHideoutB4FCurScript:: ; d634
	ds 2
wRoute6GateCurScript:: ; d636
	ds 1
wRoute8GateCurScript:: ; d637
	ds 2
wCinnabarIslandCurScript:: ; d639
	ds 1
wPokemonMansion1FCurScript:: ; d63a
	ds 2
wPokemonMansion2FCurScript:: ; d63c
	ds 1
wPokemonMansion3FCurScript:: ; d63d
	ds 1
wPokemonMansionB1FCurScript:: ; d63e
	ds 1
wVictoryRoad2FCurScript:: ; d63f
	ds 1
wVictoryRoad3FCurScript:: ; d640
	ds 2
wFightingDojoCurScript:: ; d642
	ds 1
wSilphCo2FCurScript:: ; d643
	ds 1
wSilphCo3FCurScript:: ; d644
	ds 1
wSilphCo4FCurScript:: ; d645
	ds 1
wSilphCo5FCurScript:: ; d646
	ds 1
wSilphCo6FCurScript:: ; d647
	ds 1
wSilphCo7FCurScript:: ; d648
	ds 1
wSilphCo8FCurScript:: ; d649
	ds 1
wSilphCo9FCurScript:: ; d64a
	ds 1
wHallOfFameCurScript:: ; d64b
	ds 1
wChampionsRoomCurScript:: ; d64c
	ds 1
wLoreleisRoomCurScript:: ; d64d
	ds 1
wBrunosRoomCurScript:: ; d64e
	ds 1
wAgathasRoomCurScript:: ; d64f
	ds 1
wCeruleanCaveB1FCurScript:: ; d650
	ds 1
wVictoryRoad1FCurScript:: ; d651
	ds 1
	ds 1
wLancesRoomCurScript:: ; d653
	ds 1
	ds 4
wSilphCo10FCurScript:: ; d658
	ds 1
wSilphCo11FCurScript:: ; d659
	ds 1
	ds 1
wFuchsiaGymCurScript:: ; d65b
	ds 1
wSaffronGymCurScript:: ; d65c
	ds 1
	ds 1
wCinnabarGymCurScript:: ; d65e
	ds 1
wGameCornerCurScript:: ; d65f
	ds 1
wRoute16Gate1FCurScript:: ; d660
	ds 1
wBillsHouseCurScript:: ; d661
	ds 1
wRoute5GateCurScript:: ; d662
	ds 1
wPowerPlantCurScript:: ; d663
wRoute7GateCurScript:: ; d663
; overload
	ds 1
	ds 1
wSSAnne2FCurScript:: ; d665
	ds 1
wSeafoamIslandsB3FCurScript:: ; d666
	ds 1
wRoute23CurScript:: ; d667
	ds 1
wSeafoamIslandsB4FCurScript:: ; d668
	ds 1
wRoute18Gate1FCurScript:: ; d669
	ds 1

	ds 78
wGameProgressFlagsEnd::

	ds 56

; hidden itemが発見されているかを表すbitフラグ  
; bitが立っていたら発見済み
wObtainedHiddenItemsFlags::
	ds 14

; hidden coinが発見されているかを表すbitフラグ  
; bitが立っていたら発見済み
wObtainedHiddenCoinsFlags::
	ds 2

; d700  
; $00 = walking  
; $01 = biking  
; $02 = surfing  
wWalkBikeSurfState::
	ds 1

	ds 10

wTownVisitedFlag:: ; d70b
	flag_array 13

wSafariSteps:: ; d70d
; starts at 502
	ds 2

; d70f  
; cinnabar labに渡す化石のアイテムIDを格納
wFossilItem::
	ds 1

; d710  
; cinnabar labで渡した化石から復元されるポケモンのID
wFossilMon::
	ds 1

	ds 2

wEnemyMonOrTrainerClass:: ; d713
; trainer classes start at OPP_ID_OFFSET
	ds 1

; d714  
; 段差からジャンプするアニメーション(全体16フレーム) のうち何フレーム目かを表す  
wPlayerJumpingYScreenCoordsIndex::
	ds 1

wRivalStarter:: ; d715
	ds 1

	ds 1

wPlayerStarter:: ; d717
	ds 1

; d718  
; 主人公が押そうとしているかいりき岩の スプライトのオフセット ($C1X0のX)  
wBoulderSpriteIndex::
	ds 1

wLastBlackoutMap:: ; d719
	ds 1

wDestinationMap:: ; d71a
; destination map (for certain types of special warps, not ordinary walking)
	ds 1

wUnusedD71B:: ; d71b
	ds 1

; d71c  
; かいりきで岩を押そうとするときに岩の押した先のマスのタイル番号を格納するのに利用される  
; また、岩を押す先に壁などの障害物がないかをチェックする処理の結果の格納にも利用される (0xffなら障害物あり 0x00なら障害物なし)  
wTileInFrontOfBoulderAndBoulderCollisionResult::
	ds 1

wDungeonWarpDestinationMap:: ; d71d
; destination map for dungeon warps
	ds 1

; d71e  
; which dungeon warp within the source map was used  
; マップ内でどのダンジョンワープが使われたか
wWhichDungeonWarp::
	ds 1

wUnusedD71F:: ; d71f
	ds 1

	ds 8

; d728  
; bit 0: かいりき状態か  
; bit 1: set by IsSurfingAllowed when surfing's allowed, but the caller resets it after checking the result  
; bit 3: ボロの釣竿を受取済か  
; bit 4: いい釣竿を受取済か  
; bit 5: すごい釣竿を受取済か  
; bit 6: ヤマブキシティの警備員にすでに飲み物をわたしているか  
; bit 7: set by ItemUseCardKey, which is leftover code from a previous implementation of the Card Key  
wd728::
	ds 1

	ds 1

wBeatGymFlags:: ; d72a
; redundant because it matches wObtainedBadges
; used to determine whether to show name on statue and in two NPC text scripts
	ds 1

	ds 1

; d72c  
; bit 0: if not set, the 3 minimum steps between random battles have passed  
; bit 1: セットされているならオーディオのフェードアウトを防ぐ  
wd72c::
	ds 1

; d72d  
; この変数は一時的なフラグの格納に使用されたり、トレードセンターまたはコロシアムにワープするときdestination mapとして使用される  
; - bit 0: トレードセンターでスプライトの方向が初期化されているときに立つフラグ
; - bit 3: scripted warpを行うか（ポケモンタワーの上部からシオンタウンにワープするときに使用されます）
; - bit 4: ダンジョンワープ中か
; - bit 5: NPCが話しかけられたときにプレイヤーのほうを向かないようにするフラグ
; - bit 6: ストーリー上で主要なバトルの開始時にセットされるが特になんの効果もないように思われる 任意のバトル終了時にリセットされる
; - bit 7: トレーナーとのバトルの開始時にセットされるが特になんの効果もないように思われる バトル終了時にリセットされる
wd72d::
	ds 1

; d72e  
; 様々なフラグ管理のためのメモリ  
; - bit 0: シルフコーポレーションでラプラス受け取りイベントを済ませているか  
; - bit 1: 様々な場所で立っているフラグだが、用途は不明  
; - bit 2: 一度でもポケモンセンターを利用したか  
; - bit 3: オーキド博士からポケモンを受け取ったか  
; - bit 4: disable battles
; - bit 5: 戦闘終了時またはマップ上で毒によってパーティが全滅したときにセットされる
; - bit 6: using the link feature
; - bit 7: NPCのプログラム動作が初期化されているときに立つ  
wd72e::
	ds 1

	ds 1

; d730  
; bit 0: NPCスプライトがスクリプトによって動かされているか(scripted NPC)  
; bit 1: ???  
; bit 2: 方向キーが押されたかの判定に OverworldLoop で使われている  
; bit 5: キー入力を無視する  
; bit 6: 1なら テキスト出力時に文字ごとに遅延を生じない  
; bit 7: キー入力がゲーム内で勝手に入れられているか(simulated joypad)  
wd730::
	ds 1

	ds 1

; d732  
; - bit 0: プレイ時間がカウントされている
; - bit 1: デバッグモードで使っていたフラグを消し忘れた？とりあえずセットされる様子はない セットされているときは
;	- 1. オーキド博士の話がスキップされ、プレイヤーとライバルの名前にNINTENとSONYが入る
; 	- 2. プレイヤーのゲーム開始地点がプレイヤーの家の2階からではなく[wLastMap]のマップIDになる
; 	- 3. Bボタンを押していると野生のポケモンとのエンカウントが発生しなくなる
; - bit 2: 対象のワープが fly warp(blacked outじゃないならbit3も立つ) or dungeon warp(bit4も立つ)  
; - bit 3: fly warp中に立つフラグ
; - bit 4: dungeon warp中に立つフラグ
; - bit 5: 自転車に乗ることを強制されているときに立つフラグ
; - bit 6: このbitがセットされているならwarp先を [wLastBlackoutMap]\(最後に利用したポケモンセンターか主人公の家\) とする  
wd732::
	ds 1

; **wFlags_D733**  
; d733  
; - - -  
; bit 0: running a test battle  
; bit 1: このフラグが立っている時はマップが変わってもBGMを変えない  
; bit 2: skip the joypad check in CheckWarpsNoCollision (used for the forced warp down the waterfall in the Seafoam Islands)  
; bit 3: trainer wants to battle  
; bit 4: 次のフレームで実行されるmap scriptのインデックスとして[wCurMapScript]を使う(トレーナーに話しかけてバトルが始まる場合に利用される)  
; bit 7: フィールド上で空をとぶを使った時にセットされる  
wFlags_D733::
	ds 1

wBeatLorelei:: ; d734
; bit 1: set when you beat Lorelei and reset in Indigo Plateau lobby
; the game uses this to tell when Elite 4 events need to be reset
	ds 2

; d736  
; bit 0: check if the player is standing on a door and make him walk down a step if so  
; bit 1: 1ならプレイヤーは今、ドアから下に向かって歩いている状態である  
; bit 2: (0なら)プレイヤーが warpマスの上に立っている  
; bit 6: 段差をジャンプしているモーション中 / 釣りのモーション中に立つフラグ  
; bit 7: player sprite spinning due to spin tiles (Rocket hideout / Viridian Gym)  
wd736::
	ds 1

wCompletedInGameTradeFlags:: ; d737
	ds 2

	ds 2

wWarpedFromWhichWarp:: ; d73b
	ds 1

wWarpedFromWhichMap:: ; d73c
	ds 1

	ds 2

; d73f
wCardKeyDoorY::
	ds 1

wCardKeyDoorX:: ; d740
	ds 1

	ds 2

wFirstLockTrashCanIndex:: ; d743
	ds 1

wSecondLockTrashCanIndex:: ; d744
	ds 1

	ds 2

; d747  
; イベントフラグを管理する領域  
; イベント数は全部で$9ff => 2559なので 2560 = 320*8 で320バイト
wEventFlags::
	ds 320

; d887  
; linked game's trainer name  
wLinkEnemyTrainerName::

; d887  
; 現在のマップ(草むら)でのエンカウント率  
; 高いほどポケモンが出やすい 0ならポケモンは出ない  
wGrassRate::
	ds 1

; d888  
; 現在のマップの 野生ポケモンのデータ を格納する 20バイトの領域  
; 各エントリは [Level,ポケモンID] の2バイトで 10エントリ 必ず埋められる  
; 
; 現在のマップの 野生ポケモンのデータ = `data/wildPokemon/` のデータ
wGrassMons::
	ds 11	; wSerialEnemyDataBlock も含めて 20バイト

; Overload wGrassMons
wSerialEnemyDataBlock:: ; d893
	ds 9

wEnemyPartyCount:: ds 1     ; d89c
wEnemyPartyMons::  ds PARTY_LENGTH + 1 ; d89d

; Overload enemy party data
UNION

wWaterRate:: db ; d8a4
wWaterMons:: db ; d8a5

NEXTU

wEnemyMons:: ; d8a4
wEnemyMon1:: party_struct wEnemyMon1
wEnemyMon2:: party_struct wEnemyMon2
wEnemyMon3:: party_struct wEnemyMon3
wEnemyMon4:: party_struct wEnemyMon4
wEnemyMon5:: party_struct wEnemyMon5
wEnemyMon6:: party_struct wEnemyMon6

wEnemyMonOT::    ds NAME_LENGTH * PARTY_LENGTH ; d9ac
wEnemyMonNicks:: ds NAME_LENGTH * PARTY_LENGTH ; d9ee

ENDU


wTrainerHeaderPtr:: ; da30
	ds 2

	ds 6

wOpponentAfterWrongAnswer:: ; da38
; the trainer the player must face after getting a wrong answer in the Cinnabar
; gym quiz

wUnusedDA38:: ; da38
	ds 1

wCurMapScript:: ; da39
; index of current map script, mostly used as index for function pointer array
; mostly copied from map-specific map script pointer and written back later
	ds 1

	ds 7

wPlayTimeHours:: ; da41
	ds 1

; da42  
; プレイ時間がカンストしていることを表すフラグ
wPlayTimeMaxed::
	ds 1

wPlayTimeMinutes:: ; da43
	ds 1
wPlayTimeSeconds:: ; da44
	ds 1
wPlayTimeFrames:: ; da45
	ds 1

wSafariZoneGameOver:: ; da46
	ds 1

; da47  
; サファリゲーム時に、残りのサファリボールの数を記録するのに使われる  
wNumSafariBalls::
	ds 1


; da48  
; 0 -> 育て屋にポケモンがいない  
; 1 -> 育て屋にポケモンがいる  
wDayCareInUse::
	ds 1

wDayCareMonName:: ds NAME_LENGTH ; da49
wDayCareMonOT::   ds NAME_LENGTH ; da54

; da5f  
; 育て屋に預けているポケモンの `Pokemon Data`  
; `box_struct` と同じ構造
wDayCareMon:: box_struct wDayCareMon

wMainDataEnd::

; da80  
; wNumInBoxとwBoxSpeciesでlistを形成している
wBoxDataStart::

; da80  
; ボックスに入っているポケモンの数 e.g. 2匹- > 2  
; 直下のwBoxSpeciesと合わせてlist(各エントリ1バイト)を形成している
wNumInBox::  ds 1
wBoxSpecies:: ds MONS_PER_BOX + 1	; 各エントリにはポケモンID(1バイト)が格納される [ID, ID, ID, ID, ...]

wBoxMons::
wBoxMon1:: box_struct wBoxMon1 ; da96
wBoxMon2:: ds box_struct_length * (MONS_PER_BOX + -1) ; dab7

; dd2a  
; 220バイトの領域でポケモンの親(最初のトレーナー)を格納  
wBoxMonOT::    ds NAME_LENGTH * MONS_PER_BOX

; de06  
; ボックスのポケモンのニックネームのリストを格納する220バイトの領域  
wBoxMonNicks:: ds NAME_LENGTH * MONS_PER_BOX
wBoxMonNicksEnd:: ; dee2

; dee2
wBoxDataEnd::

; dee2

SECTION "Stack", WRAM0
wStack:: ; dfff


INCLUDE "sram.asm"
