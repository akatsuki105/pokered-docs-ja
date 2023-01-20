; hlが示すアドレスからdeが示すアドレスに NAME_LENGTHバイト だけコピー
CopyFixedLengthText:
	ld bc, NAME_LENGTH
	jp CopyData

SetDefaultNamesBeforeTitlescreen:
	; [wPlayerName] = "NINTEN@"
	ld hl, NintenText
	ld de, wPlayerName
	call CopyFixedLengthText
	; [wRivalName] = "SONY@"
	ld hl, SonyText
	ld de, wRivalName
	call CopyFixedLengthText

	; 各種変数を0クリア
	xor a
	ld [hWY], a	; [hWY] = 0
	ld [wLetterPrintingDelayFlags], a ; 遅延を無効化
	ld hl, wd732
	ld [hli], a ; [wd732] = 0
	ld [hli], a ; [wFlags_D733] = 0
	ld [hl], a	; [wBeatLorelei] = 0

	ld a, BANK(Music_TitleScreen)
	ld [wAudioROMBank], a
	ld [wAudioSavedROMBank], a

; **DisplayTitleScreen**  
; タイトル画面を表示する処理  
DisplayTitleScreen:
	call GBPalWhiteOut

	; 自動的なBG転送を有効化
	ld a, $1
	ld [H_AUTOBGTRANSFERENABLED], a

	; 花、水のアニメーションをoff
	xor a
	ld [hTilesetType], a

	; scroll = ($0, $40) = (0, 64)
	ld [hSCX], a
	ld a, $40
	ld [hSCY], a

	; ウィンドウを無効化
	ld a, $90
	ld [hWY], a

	; タイトル画面表示の準備
	call ClearScreen
	call DisableLCD
	call LoadFontTilePatterns

	; 以後VRAMのタイルデータ格納場所にタイトル画面のグラフィックデータをコピーしていく
	
	; Nintendo のコピーライト
	ld hl, NintendoCopyrightLogoGraphics
	ld de, vTitleLogo2 + $100
	ld bc, $50
	ld a, BANK(NintendoCopyrightLogoGraphics)
	call FarCopyData2

	; Gamefreak のロゴ
	ld hl, GamefreakLogoGraphics
	ld de, vTitleLogo2 + $100 + $50
	ld bc, $90
	ld a, BANK(GamefreakLogoGraphics)
	call FarCopyData2

	; ポケモンのロゴ
	ld hl, PokemonLogoGraphics
	ld de, vTitleLogo
	ld bc, $600
	ld a, BANK(PokemonLogoGraphics)
	call FarCopyData2          ; first chunk
	ld hl, PokemonLogoGraphics+$600
	ld de, vTitleLogo2
	ld bc, $100
	ld a, BANK(PokemonLogoGraphics)
	call FarCopyData2          ; second chunk

	; バージョンデータ(赤版/青版)
	ld hl, Version_GFX
	ld de, vChars2 + $600 - (Version_GFXEnd - Version_GFX - $50)
	ld bc, Version_GFXEnd - Version_GFX
	ld a, BANK(Version_GFX)
	call FarCopyDataDouble

	; BGMapをクリアする
	call ClearBothBGMaps

	; ここまででVRAMのtile Data領域に必要なアセットをロードし、BGMapはクリアした
	; これからBGMapにタイトル画面のアセットを配置してタイトル画面を描画していく

	; タイトルロゴを配置する(タイトルロゴの最後の行は除く)
	coord hl, 2, 1
	ld a, $80 ; $80+x -> タイトルロゴのタイル番号
	ld de, SCREEN_WIDTH
	ld c, 6 ; タイル6行分
	; タイトルロゴを1行ずつ配置するループ
.pokemonLogoTileLoop
	ld b, $10 ; タイル16枚分(16px -> 144pxまで配置)
	push hl
	; タイトルロゴを現在処理中の行に1タイルずつ配置する
.pokemonLogoTileRowLoop
	ld [hli], a
	inc a
	dec b
	jr nz, .pokemonLogoTileRowLoop
	; 次の行へ
	pop hl
	add hl, de
	dec c
	jr nz, .pokemonLogoTileLoop

; タイトルロゴの最後の行を配置する
	coord hl, 2, 7
	ld a, $31
	ld b, $10
.pokemonLogoLastTileRowLoop
	ld [hli], a
	inc a
	dec b
	jr nz, .pokemonLogoLastTileRowLoop

	; 主人公のスプライトをタイトル画面に配置する
	call DrawPlayerCharacter

	; 主人公の手とモンスターボールを配置
	ld hl, wOAMBuffer + $28
	ld a, $74
	ld [hl], a

	; タイトル画面の最下部にコピーライトのタイルを配置する
	coord hl, 2, 17
	ld de, .tileScreenCopyrightTiles
	ld b, $10
.tileScreenCopyrightTilesLoop
	ld a, [de]
	ld [hli], a
	inc de
	dec b
	jr nz, .tileScreenCopyrightTilesLoop

	jr .next

.tileScreenCopyrightTiles
	db $41,$42,$43,$42,$44,$42,$45,$46,$47,$48,$49,$4A,$4B,$4C,$4D,$4E ; ©'95.'96.'98 GAME FREAK inc.

.next
	; 配置したタイトル画面のデータを wTileMapBackup2 を保存する
	; このときタイトル画面には  
	; - ポケモンのロゴ
	; - 主人公
	; - コピーライト
	; が表示されている
	call SaveScreenTilesToBuffer2
	call LoadScreenTilesFromBuffer2
	call EnableLCD

	; a = CHARMANDER or SQUIRTLE = タイトル画面で最初に表示されるポケモン
IF DEF(_RED)
	ld a, CHARMANDER
ENDC
IF DEF(_BLUE)
	ld a, SQUIRTLE
ENDC
	; ポケモンのグラフィックを(5, 10)に配置
	ld [wTitleMonSpecies], a
	call LoadTitleMonSprite

	; wTileMapに配置したグラフィックデータをVRAM($9b00~)に転送する
	ld a, (vBGMap0 + $300) / $100
	call TitleScreenCopyTileMapToVRAM

	call SaveScreenTilesToBuffer1 ; ポケモン有りのタイトル画面を保存

	; WY = 64
	ld a, $40
	ld [hWY], a
	
	; ポケモン無しのタイトル画面を$9800に配置する
	call LoadScreenTilesFromBuffer2
	ld a, vBGMap0 / $100
	call TitleScreenCopyTileMapToVRAM

	; パレットを通常のパレットにする
	ld b, SET_PAL_TITLE_SCREEN
	call RunPaletteCommand
	call GBPalNormal
	ld a, %11100100
	ld [rOBP0], a

	; ポケモンのロゴを上下にバウンドさせる
	ld bc, hSCY ; background scroll Y
	ld hl, .TitleScreenPokemonLogoYScrolls
.bouncePokemonLogoLoop
	ld a, [hli] ; a = yスクロール量
	
	; .TitleScreenPokemonLogoYScrollsの終わりに来たら終了
	and a
	jr z, .finishedBouncingPokemonLogo
	
	; d = yスクロール量
	ld d, a
	; yスクロール量 == -3のとき、SFX_INTRO_CRASHを鳴らす
	cp -3
	jr nz, .skipPlayingSound
	ld a, SFX_INTRO_CRASH
	call PlaySound

.skipPlayingSound
	ld a, [hli]
	ld e, a ; e = スクロール回数
	call .ScrollTitleScreenPokemonLogo
	; 次のバウンス処理へ
	jr .bouncePokemonLogoLoop
	; バウンス処理が終わったなら.finishedBouncingPokemonLogo へジャンプされる

; ポケモンのロゴがタイトル画面で上下にバウンドする処理を制御するテーブル  
; 各エントリ = yスクロール量, スクロールする回数  
.TitleScreenPokemonLogoYScrolls:
	db -4,16 ; 最初のロゴが降りてくる処理
	db 3,4
	db -3,4
	db 2,2
	db -2,2
	db 1,2
	db -1,2
	db 0      ; terminate list with 0

; 上下にバウンドするエフェクトのためにポケモンのロゴをスクロールさせる  
; dピクセルのスクロールをe回する(つまり合計でd*eピクセル動く)  
.ScrollTitleScreenPokemonLogo:
	call DelayFrame
	ld a, [bc] ; background scroll Y
	add d
	ld [bc], a
	dec e
	jr nz, .ScrollTitleScreenPokemonLogo
	ret

; タイトル画面でポケモンのロゴのバウンド処理が終わった後にここに来る  
.finishedBouncingPokemonLogo
	call LoadScreenTilesFromBuffer1 ; ポケモン有りのタイトル画面を復帰
	; 36フレーム遅延させた後、SFX_INTRO_WHOOSH を流す
	ld c, 36
	call DelayFrames
	ld a, SFX_INTRO_WHOOSH
	call PlaySound

; 右からバージョン情報(Red Version)をスクロールさせる
	call PrintGameVersionOnTitleScreen
	ld a, SCREEN_HEIGHT_PIXELS
	ld [hWY], a ; ウィンドウを無効化
	ld d, 144
.scrollTitleScreenGameVersionLoop
	; Yが64~80までのSCXをdに変更
	ld h, d
	ld l, 64
	call ScrollTitleScreenGameVersion
	ld h, 0
	ld l, 80
	call ScrollTitleScreenGameVersion
	; バージョン情報を徐々に左にスクロールさせる
	ld a, d
	add 4
	ld d, a
	and a
	jr nz, .scrollTitleScreenGameVersionLoop

	; タイトル画面のinit処理を終えた (ポケモンのロゴを降らせる処理やバージョン情報をスクロールさせる処理)
	; これからは通常のタイトルスクリーンの処理を始める
	ld a, vBGMap1 / $100
	call TitleScreenCopyTileMapToVRAM
	call LoadScreenTilesFromBuffer2 ; ポケモンロゴ、主人公、コピーライトが配置されたタイトル画面(VRAMではなくwTileMapなので画面には反映されない？)
	call PrintGameVersionOnTitleScreen ; バージョン情報を描画
	; タイトルのBGMを再生する
	call Delay3
	call WaitForSoundToFinish
	ld a, MUSIC_TITLE_SCREEN
	ld [wNewSoundID], a
	call PlaySound
	xor a
	ld [wUnusedCC5B], a

; ユーザーのキー入力があるまでポケモンを横スクロールで切り替える処理を行う
.awaitUserInterruptionLoop
	;  200フレームの間、キー入力をチェック -> キー入力があった場合は .finishedWaiting
	ld c, 200
	call CheckForUserInterruption
	jr c, .finishedWaiting

	; キー入力がなかった場合 
	call TitleScreenScrollInMon ; 最初のポケモンをスクロールout
	;  一瞬キー入力をチェック -> キー入力があった場合は .finishedWaiting
	ld c, 1
	call CheckForUserInterruption
	jr c, .finishedWaiting

	callba TitleScreenAnimateBallIfStarterOut
	call TitleScreenPickNewMon ; 新しいポケモンをスクロールin
	jr .awaitUserInterruptionLoop

; キー入力があったとき
.finishedWaiting
	; 現在タイトル画面のポケモンの鳴き声を鳴らす
	ld a, [wTitleMonSpecies]
	call PlayCry
	call WaitForSoundToFinish
	; 画面を真っ白に
	call GBPalWhiteOutWithDelay3
	call ClearSprites
	xor a
	ld [hWY], a
	inc a
	ld [H_AUTOBGTRANSFERENABLED], a
	call ClearScreen
	ld a, vBGMap0 / $100
	call TitleScreenCopyTileMapToVRAM
	ld a, vBGMap1 / $100
	call TitleScreenCopyTileMapToVRAM
	call Delay3
	call LoadGBPal
	; キー入力を受け取る
	ld a, [hJoyHeld]
	ld b, a
	; 押されたボタンが↑+Select+B ならセーブデータを削除するダイアログ表示
	and D_UP | SELECT | B_BUTTON
	cp D_UP | SELECT | B_BUTTON
	jp z, .doClearSaveDialogue
	; それ以外のボタン(Start or A) ならメインメニューへ
	jp MainMenu

.doClearSaveDialogue
	jpba DoClearSaveDialogue

TitleScreenPickNewMon:
	ld a, vBGMap0 / $100
	call TitleScreenCopyTileMapToVRAM

; 現在のポケモンと違うポケモンが見つかるまでループを続ける
.loop
	; bc = ランダム値($00~$f)
	call Random
	and $f
	ld c, a
	ld b, 0

	; a = ランダムに選んだポケモンID
	; hl = 現在のポケモンIDのポインタ
	ld hl, TitleMons
	add hl, bc
	ld a, [hl]
	ld hl, wTitleMonSpecies

	; 次のポケモンが現在のポケモンと同じなら .loop
	cp [hl]
	jr z, .loop

	; 新しいポケモンを画面に配置
	ld [hl], a
	call LoadTitleMonSprite

	ld a, $90
	ld [hWY], a
	ld d, 1 ; scroll out
	callba TitleScroll ; 新しいポケモンをスクロールin?
	ret

; ポケモンをスクロールinさせる処理???
TitleScreenScrollInMon:
	ld d, 0 ; scroll in
	callba TitleScroll
	xor a
	ld [hWY], a
	ret

; バージョン情報をスクロールさせる  
; INPUT:  
; - h = SCXにセットする値
; - l = スクロールさせるY座標(pixel)
ScrollTitleScreenGameVersion:
	; LY == l になるまで待機
.wait
	ld a, [rLY]
	cp l
	jr nz, .wait

	; SCX = h
	ld a, h
	ld [rSCX], a

	; LY != h ならリターン
.wait2
	ld a, [rLY]
	cp h
	jr z, .wait2
	ret

; プレイヤーのグラフィックデータをOAMに配置する
DrawPlayerCharacter:
	; プレイヤーのグラフィックデータをVRAMのタイルデータ領域に配置する
	ld hl, PlayerCharacterTitleGraphics
	ld de, vSprites
	ld bc, PlayerCharacterTitleGraphicsEnd - PlayerCharacterTitleGraphics
	ld a, BANK(PlayerCharacterTitleGraphics)
	call FarCopyData2

	call ClearSprites
	xor a
	ld [wPlayerCharacterOAMTile], a
	ld hl, wOAMBuffer
	ld de, $605a ; Y=$60 X=$5a
	ld b, 7 ; loopのループ回数 = 7
	; 主人公のスプライトを1行ずつ配置するループ
.loop
	push de
	ld c, 5 ; innerLoopのループ回数 = 5
	; 現在処理中の行に主人公のスプライトを1タイルずつ配置するループ
.innerLoop
	; OAMにYを配置
	ld a, d
	ld [hli], a
	; OAMにXを配置して 次のループのために+8
	ld a, e
	ld [hli], a
	add 8
	ld e, a
	; OAMにタイル番号を配置して [wPlayerCharacterOAMTile]++ する
	ld a, [wPlayerCharacterOAMTile]
	ld [hli], a
	inc a
	ld [wPlayerCharacterOAMTile], a
	; 次のループ(OAM)
	inc hl
	dec c
	jr nz, .innerLoop
	; 次の行
	pop de
	ld a, 8
	add d
	ld d, a
	dec b
	jr nz, .loop
	ret

; **ClearBothBGMaps**  
; BGMap全体をクリアする  
; - - -  
; BGMap全体($9800-$9fff)を空白のタイル番号で埋め尽くしてクリアする
ClearBothBGMaps:
	ld hl, vBGMap0
	ld bc, $400 * 2
	ld a, " "
	jp FillMemory

; **LoadTitleMonSprite**  
; (5, 10)のBGMapにポケモンのグラを配置する  
; - - -  
; INPUT: a = 表示するポケモンのID  
LoadTitleMonSprite:
	ld [wcf91], a
	ld [wd0b5], a
	coord hl, 5, 10
	call GetMonHeader
	jp LoadFrontSpriteByMonIndex ; hl = (5, 10)のBGMapアドレス
	; LoadFrontSpriteByMonIndexでretされる

; **TitleScreenCopyTileMapToVRAM**  
; コピーライトをVRAMに配置する  
; - - -  
; 転送先にaをセットして終了(Delay3の中でreturn)  
; INPUT: a = 転送先のVRAMアドレス  
TitleScreenCopyTileMapToVRAM:
	ld [H_AUTOBGTRANSFERDEST + 1], a
	jp Delay3

; **LoadCopyrightAndTextBoxTiles**  
; コピーライトとテキストボックスのタイルをVRAMに転送する関数  
; - - -  
; テキストボックスは後の LoadCopyrightTiles で使う  
LoadCopyrightAndTextBoxTiles:
	xor a
	ld [hWY], a
	call ClearScreen
	call LoadTextBoxTilePatterns

; **LoadCopyrightTiles**  
; コピーライトのタイルをVRAMにロードした後、  
; 
; ©'95.'96.'98 Nintendo  
; ©'95.'96.'98 Creatures inc.  
; ©'95.'96.'98 GAME FREAK inc.  
; 
; を画面に描画する  
LoadCopyrightTiles:
	; コピーライトのタイルをVRAMにロード
	ld de, NintendoCopyrightLogoGraphics
	ld hl, vChars2 + $600
	lb bc, BANK(NintendoCopyrightLogoGraphics), (GamefreakLogoGraphicsEnd - NintendoCopyrightLogoGraphics) / $10
	call CopyVideoData

	; CopyrightTextString を描画
	coord hl, 2, 7
	ld de, CopyrightTextString
	jp PlaceString

; ©'95.'96.'98 Nintendo  
; ©'95.'96.'98 Creatures inc.  
; ©'95.'96.'98 GAME FREAK inc.  
CopyrightTextString:
	db   $60,$61,$62,$61,$63,$61,$64,$7F,$65,$66,$67,$68,$69,$6A             ; ©'95.'96.'98 Nintendo
	next $60,$61,$62,$61,$63,$61,$64,$7F,$6B,$6C,$6D,$6E,$6F,$70,$71,$72     ; ©'95.'96.'98 Creatures inc.
	next $60,$61,$62,$61,$63,$61,$64,$7F,$73,$74,$75,$76,$77,$78,$79,$7A,$7B ; ©'95.'96.'98 GAME FREAK inc.
	db   "@"

INCLUDE "data/title_mons.asm"

; wTileMap の (7, 8) にバージョン情報(Red, Blue)を配置する  
PrintGameVersionOnTitleScreen:
	coord hl, 7, 8
	ld de, VersionOnTitleScreenText
	jp PlaceString

; これらのテキストはバージョン情報を表示する目的でしか使われない特別なタイルデータを指す  
; "Red Version" or "Blue Version"  
VersionOnTitleScreenText:
IF DEF(_RED)
	db $60,$61,$7F,$65,$66,$67,$68,$69,"@" ; "Red Version"
ENDC
IF DEF(_BLUE)
	db $61,$62,$63,$64,$65,$66,$67,$68,"@" ; "Blue Version"
ENDC

; "NINTEN@"
NintenText: db "NINTEN@"
; "SONY@"
SonyText:   db "SONY@"
