; 一度しか使われてなさそう  
; hlレジスタに次の引数で指定したBGタイルマップの行と列のアドレスを入れる関数  
; 
; INPUT:  
; h = 行  
; l = 列  
; b = BGタイルマップの上位バイト e.g. $98 -> 0x9800  
GetRowColAddressBgMap::
	xor a
	srl h
	rr a
	srl h
	rr a
	srl h
	rr a
	or l
	ld l, a
	ld a, b
	or h
	ld h, a
	ret

; clears a VRAM background map with blank space tiles
; INPUT: h - high byte of background tile map address in VRAM
ClearBgMap::
	ld a, " "
	jr .next
	ld a, l
.next
	ld de, $400 ; size of VRAM background map
	ld l, e
.loop
	ld [hli], a
	dec e
	jr nz, .loop
	dec d
	jr nz, .loop
	ret

; **RedrawRowOrColumn**  
; BG1行(16px) or BG1列 (16px) を再描画する関数  
; - - -  
; この関数の主な用途としては、主人公が歩いた時にスクロールによって画面内に入った 行 or 列 を再描画することがある  
; 全画面を再描画するのではなく、新しく画面に入ったところだけを再描画することで、無駄なCPU消費を避けている  
; とはいえ、この関数は、交換時のアニメーションやエレベータの処理時などで画面全体の再描画にも利用されることがある  
; 
; INPUT:  
; [hRedrawRowOrColumnMode] = 0(無効) or 1(列) or 2(行)
RedrawRowOrColumn::

	; [hRedrawRowOrColumnMode] == 0 -> return
	ld a, [hRedrawRowOrColumnMode]
	and a
	ret z

	ld b, a ; b = [hRedrawRowOrColumnMode]

	; [hRedrawRowOrColumnMode] をクリア
	xor a
	ld [hRedrawRowOrColumnMode], a

	dec b
	jr nz, .redrawRow ; b == 2 -> .redrawRow

; [hRedrawRowOrColumnMode] == 1
.redrawColumn
	ld hl, wRedrawRowOrColumnSrcTiles
	ld a, [hRedrawRowOrColumnDest]
	ld e, a
	ld a, [hRedrawRowOrColumnDest + 1]
	ld d, a
	ld c, SCREEN_HEIGHT ; ループ回数

; ループにつき、縦に16px再描画 1列再描画を終えるまで続ける
.loop1
; {
	; [de] = [hl++] 列(1列=8px*2 なので その1枚目)
	ld a, [hli]
	ld [de], a
	inc de
	; 2枚目
	ld a, [hli]
	ld [de], a

	; 次の行へ
	ld a, BG_MAP_WIDTH - 1
	add e
	ld e, a
	jr nc, .noCarry
	inc d
.noCarry

	; 画面外の 4行(4*2*8=64px)部分にきてしまった時は次の行の先頭に移動しておく
	ld a, d
	and $03
	or $98
	ld d, a

	dec c
	jr nz, .loop1
; }

; 終了
	xor a
	ld [hRedrawRowOrColumnMode], a
	ret

; [hRedrawRowOrColumnMode] == 2
.redrawRow
	ld hl, wRedrawRowOrColumnSrcTiles
	ld a, [hRedrawRowOrColumnDest]
	ld e, a
	ld a, [hRedrawRowOrColumnDest + 1]
	ld d, a

	; 上半分(8px * 1行)再描画
	push de
	call .DrawHalf ; draw upper half
	pop de

	; 下半分(+8px)へ
	ld a, BG_MAP_WIDTH ; width of VRAM background map
	add e
	ld e, a

	; そのまま下に続いて下半分を再描画
.DrawHalf
	ld c, SCREEN_WIDTH / 2

; .loop1と同じような処理
.loop2
; {
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	ld a, e
	inc a
; the following 6 lines wrap us from the right edge to the left edge if necessary
	and $1f
	ld b, a
	ld a, e
	and $e0
	or b
	ld e, a
	dec c
	jr nz, .loop2
; }
	ret

; **AutoBgMapTransfer**  
; VBlank期間に自動的に wTileMapのタイルIDデータを VRAMに転送する関数  
; - - -  
; 1回のVBlankで全て転送するわけではなく VBlankごとに1/3ずつ転送することに注意  
; この関数による転送はプレイヤーがマップを歩いているときは offになり、スプライトと会話しているときや戦闘中、メニュー画面などでは onになる  
; マップ上を歩いているときは より効率的な `RedrawRowOrColumn` を使用する  
AutoBgMapTransfer::
	; H_AUTOBGTRANSFERENABLED で転送が無効になっているときは何もせず return
	ld a, [H_AUTOBGTRANSFERENABLED]
	and a
	ret z

	; spを退避
	ld hl, sp + 0
	ld a, h
	ld [H_SPTEMP], a
	ld a, l
	ld [H_SPTEMP + 1], a ; save stack pinter

	; [H_AUTOBGTRANSFERPORTION]の値によって分岐
	ld a, [H_AUTOBGTRANSFERPORTION]

	; [H_AUTOBGTRANSFERPORTION] == 0
	and a
	jr z, .transferTopThird

	; [H_AUTOBGTRANSFERPORTION] == 1
	dec a
	jr z, .transferMiddleThird

	; [H_AUTOBGTRANSFERPORTION] == 2
.transferBottomThird
	coord hl, 0, 12
	ld sp, hl
	; hl = 転送先
	ld a, [H_AUTOBGTRANSFERDEST + 1]
	ld h, a
	ld a, [H_AUTOBGTRANSFERDEST]
	ld l, a
	ld de, (12 * 32)
	add hl, de
	xor a ; TRANSFERTOP (00)
	jr .doTransfer

.transferTopThird
	coord hl, 0, 0
	ld sp, hl
	ld a, [H_AUTOBGTRANSFERDEST + 1]
	ld h, a
	ld a, [H_AUTOBGTRANSFERDEST]
	ld l, a
	ld a, TRANSFERMIDDLE ; (01)
	jr .doTransfer

.transferMiddleThird
	coord hl, 0, 6
	ld sp, hl
	ld a, [H_AUTOBGTRANSFERDEST + 1]
	ld h, a
	ld a, [H_AUTOBGTRANSFERDEST]
	ld l, a
	ld de, (6 * 32)
	add hl, de
	ld a, TRANSFERBOTTOM ; (02)
	
	; この時点で
	; a = 0(2/3のとき) or 1(0/3のとき) or 2(1/3のとき)
	; 
	; sp = 
	; wTileMap の (0, 0)
	; wTileMap の (0, 6)
	; wTileMap の (0, 12)
	; 
	; hl = 
	; 	0/3:	[H_AUTOBGTRANSFERDEST]  
	; 	1/3:	[H_AUTOBGTRANSFERDEST] + (6 * 32)  
	; 	2/3:    [H_AUTOBGTRANSFERDEST] + (12 * 32)  

.doTransfer
	ld [H_AUTOBGTRANSFERPORTION], a ; 次のステップ(n/3)にしておく
	ld b, 6	; (画面1/3)
	; 下に続く

; **TransferBgRows**  
; wTileMap から VRAM(H_AUTOBGTRANSFERDEST) に タイルIDを転送していく  
; - - -  
; VBlank中に行われるので、速度を考えて pop を使っている
; 
; INPUT:  
; sp = 転送元  
; hl = 転送先  
; b = 何行(1行=8px)転送するか  
TransferBgRows::
; {
	rept 20 / 2 - 1 ; 9 (1行分のタイル-1枚分)
	; de = [sp], sp++
	; sp には 転送する wTileMap のアドレスが入っている
	; pop により wTileMapからタイルIDが取り出され、 sp++ されることで 転送対象の wTileMap のアドレス進んでいく
	; 1度のコピーで 2回(横2枚)コピーする (縦には1枚)
	pop de
	; [H_AUTOBGTRANSFERDEST] = wTileMap の タイルID 
	ld [hl], e
	inc l	; 1枚目
	ld [hl], d
	inc l 	; 2枚目
	endr
	; 行の最後の1枚分
	pop de
	ld [hl], e
	inc l
	ld [hl], d

	; hl += 32 - (20 - 1) = (6*2)-1 見えてない部分
	ld a, 32 - (20 - 1) 
	add l
	ld l, a
	jr nc, .ok
	inc h	; carry

.ok
	dec b ; 6(画面の縦の1/3)から減っていく
	jr nz, TransferBgRows
; }

	; spを復帰して終了
	ld a, [H_SPTEMP]
	ld h, a
	ld a, [H_SPTEMP + 1]
	ld l, a
	ld sp, hl
	ret

; **VBlankCopyBgMap**  
; H_VBCOPYBGSRC から H_VBCOPYBGDEST に [H_VBCOPYBGNUMROWS]*行　コピーする  
; - - -  
; H_VBCOPYBGSRC のアドレスが 0xXX00なら転送は無効  
; 内部処理に `TransferBgRows` を用いている
VBlankCopyBgMap::
	
	; [H_VBCOPYBGSRC]の下位バイト * 2 == 0 -> return 
	ld a, [H_VBCOPYBGSRC]
	and a
	ret z

	; 現在の sp を退避
	ld hl, sp + 0
	ld a, h
	ld [H_SPTEMP], a
	ld a, l
	ld [H_SPTEMP + 1], a ; save stack pointer

	; sp = [H_VBCOPYBGSRC]
	ld a, [H_VBCOPYBGSRC]
	ld l, a
	ld a, [H_VBCOPYBGSRC + 1]
	ld h, a
	ld sp, hl

	; hl = [H_VBCOPYBGDEST]
	ld a, [H_VBCOPYBGDEST]
	ld l, a
	ld a, [H_VBCOPYBGDEST + 1]
	ld h, a

	; b = [H_VBCOPYBGNUMROWS]
	ld a, [H_VBCOPYBGNUMROWS]
	ld b, a

	xor a
	ld [H_VBCOPYBGSRC], a ; disable transfer so it doesn't continue next V-blank

	; [H_VBCOPYBGSRC] から [H_VBCOPYBGDEST] に [H_VBCOPYBGNUMROWS]行分転送
	jr TransferBgRows


; **VBlankCopyDouble**  
; H_VBCOPYDOUBLESRC から H_VBCOPYDOUBLEDEST に [H_VBCOPYDOUBLESIZE]タイル分の 2bppデータ(元は1bppデータ) を転送する
; 転送の際に 1bppデータ を 2bppデータ に　変換(2回同じ値を転送しているだけ) している
; 転送の詳細は VBlankCopy と似ているのでそちらを参照
VBlankCopyDouble::

	; [H_VBCOPYDOUBLESIZE] == 0 -> return
	ld a, [H_VBCOPYDOUBLESIZE]
	and a
	ret z

	; spを退避 (高速な転送が要求されるのでスタックを用いる)
	ld hl, sp + 0
	ld a, h
	ld [H_SPTEMP], a
	ld a, l
	ld [H_SPTEMP + 1], a

	; sp = 転送元
	ld a, [H_VBCOPYDOUBLESRC]
	ld l, a
	ld a, [H_VBCOPYDOUBLESRC + 1]
	ld h, a
	ld sp, hl

	; hl = 転送先
	ld a, [H_VBCOPYDOUBLEDEST]
	ld l, a
	ld a, [H_VBCOPYDOUBLEDEST + 1]
	ld h, a

	; [H_VBCOPYDOUBLESIZE] = 0 = 転送終了にしておく
	ld a, [H_VBCOPYDOUBLESIZE]
	ld b, a
	xor a ; transferred
	ld [H_VBCOPYDOUBLESIZE], a

.loop
; .loopのiter 1回で 1タイル(8*8px)分の 1bpp データ を 2bppデータにして転送する
; .loopを通して  [H_VBCOPYDOUBLESIZE]タイル分の 2bpp データを転送する
; {
	rept 3 ; {
	pop de ; sp++
	
	; 1bpp -> 2bpp にするために 2回 同じ値(e)を転送する必要がある
	ld [hl], e
	inc l
	ld [hl], e
	inc l
	; 1bpp -> 2bpp にするために 2回 同じ値(d)を転送する必要がある
	ld [hl], d
	inc l
	ld [hl], d
	inc l
	; }
	endr

	pop de ; sp++
	ld [hl], e
	inc l
	ld [hl], e
	inc l
	ld [hl], d
	inc l
	ld [hl], d
	inc hl
	dec b
	jr nz, .loop
; }

	; [H_VBCOPYDOUBLESIZE] の転送を終えたときの [H_VBCOPYDOUBLESRC], [H_VBCOPYDOUBLEDEST] の位置を記録しておく
	ld a, l
	ld [H_VBCOPYDOUBLEDEST], a
	ld a, h
	ld [H_VBCOPYDOUBLEDEST + 1], a
	ld hl, sp + 0
	ld a, l
	ld [H_VBCOPYDOUBLESRC], a
	ld a, h
	ld [H_VBCOPYDOUBLESRC + 1], a

	; spを復帰
	ld a, [H_SPTEMP]
	ld h, a
	ld a, [H_SPTEMP + 1]
	ld l, a
	ld sp, hl

	ret


; **VBlankCopy**  
; H_VBCOPYSRC から H_VBCOPYDEST に [H_VBCOPYSIZE]タイル分の 2bpp データを転送する (つまり 16 * [H_VBCOPYSIZE]バイト)  
; - - -  
; この関数は複数回に分けて呼びたい時があるので、 終了時に H_VBCOPYSRC と H_VBCOPYDEST は [H_VBCOPYSIZE]タイル分転送した時点での値に更新される  
; 
; INPUT:  
; [H_VBCOPYSRC] = 転送元  
; [H_VBCOPYDEST] = 転送先  
; [H_VBCOPYSIZE] = 何タイル分転送するか  
; 
; OUTPUT:  
; [H_VBCOPYSRC] = 転送を終えた後の値  
; [H_VBCOPYDEST] = 転送を終えた後の値  
; [H_VBCOPYSIZE] = 0(次に H_VBCOPYSIZE に値をセットすれば続きから転送ができる)  
VBlankCopy::

	; [H_VBCOPYSIZE] == 0 -> return
	ld a, [H_VBCOPYSIZE]
	and a
	ret z

	; spを退避 (高速な転送が要求されるのでスタックを用いる)
	ld hl, sp + 0
	ld a, h
	ld [H_SPTEMP], a
	ld a, l
	ld [H_SPTEMP + 1], a

	; sp = [H_VBCOPYSRC] = 転送元
	ld a, [H_VBCOPYSRC]
	ld l, a
	ld a, [H_VBCOPYSRC + 1]
	ld h, a
	ld sp, hl

	; hl = 転送先
	ld a, [H_VBCOPYDEST]
	ld l, a
	ld a, [H_VBCOPYDEST + 1]
	ld h, a

	; [H_VBCOPYSIZE] = 0 = 転送終了にしておく
	ld a, [H_VBCOPYSIZE]
	ld b, a
	xor a ; transferred
	ld [H_VBCOPYSIZE], a

.loop
; .loopのiter 1回で 1タイル(8*8px)分の 2bpp データを転送する
; .loopを通して  [H_VBCOPYSIZE]タイル分の 2bpp データを転送する
; {
	; [hl] = [sp] を2回 つまり グラフィックデータを転送
	rept 7
	pop de	; de = 転送する2bppグラフィックデータ([sp]) && sp++
	ld [hl], e
	inc l
	ld [hl], d
	inc l ; de = 2バイトなので l += 2
	endr

	; 最後の1回
	pop de
	ld [hl], e
	inc l
	ld [hl], d
	inc hl

	dec b
	jr nz, .loop
; }

	; [H_VBCOPYSIZE] の転送を終えたときの [H_VBCOPYSRC], [H_VBCOPYDEST] の位置を記録しておく
	ld a, l
	ld [H_VBCOPYDEST], a
	ld a, h
	ld [H_VBCOPYDEST + 1], a
	ld hl, sp + 0
	ld a, l
	ld [H_VBCOPYSRC], a
	ld a, h
	ld [H_VBCOPYSRC + 1], a

	; spを復帰
	ld a, [H_SPTEMP]
	ld h, a
	ld a, [H_SPTEMP + 1]
	ld l, a
	ld sp, hl

	ret

; マップ上での花や水のアニメーション処理を行う
UpdateMovingBgTiles::

	; [hTilesetType] == 0 -> return
	ld a, [hTilesetType]
	and a
	ret z ; 室内やメニュー画面では [hTilesetType] = 0 になる

	; [hMovingBGTilesCounter1]++
	ld a, [hMovingBGTilesCounter1]
	inc a
	ld [hMovingBGTilesCounter1], a
	
	; [hMovingBGTilesCounter1] < 20  -> return
	cp 20
	ret c
	; [hMovingBGTilesCounter1] == 21 -> .flower 
	cp 21
	jr z, .flower
	; [hMovingBGTilesCounter1] == 20  -> .water(fall through)

; water
; 2bpp の bitデータ を右や左にシフトさせることで波の動きを表現する
	ld hl, vTileset + $14 * $10
	ld c, $10 ; .right, .left での ループ回数 = 16

	; a = [wMovingBGTilesCounter2] = ([wMovingBGTilesCounter2] + 1)%8
	ld a, [wMovingBGTilesCounter2]
	inc a
	and 7 						; and 0b0111 つまり %8
	ld [wMovingBGTilesCounter2], a

	; [wMovingBGTilesCounter2] >= 4 のとき -> .left
	and 4
	jr nz, .left

; [wMovingBGTilesCounter2] < 4 のとき
.right
; 右シフト を 16回 = タイル1枚を 右に1bitシフト
; {
	ld a, [hl]
	rrca
	ld [hli], a
	dec c
	jr nz, .right
; }
	jr .done

.left	
; 左シフト を 16回 = タイル1枚を 左に1bitシフト
; {
	ld a, [hl]
	rlca
	ld [hli], a
	dec c
	jr nz, .left
; }

.done
	; c == 0 or c == 2 -> return
	ld a, [hTilesetType]
	rrca
	ret nc
	; c == 1 つまり 洞窟のとき [hMovingBGTilesCounter1] を 0にして 21にしないことで 花のアニメーションは行わないようにする
	xor a
	ld [hMovingBGTilesCounter1], a
	ret

.flower
	; [hMovingBGTilesCounter1] を 21 から 0 にリセット
	xor a
	ld [hMovingBGTilesCounter1], a

	; a = [wMovingBGTilesCounter2]%4
	ld a, [wMovingBGTilesCounter2]
	and 3

	; hl = FlowerTile1(0, 1) or FlowerTile2(2) or FlowerTile3(3)
	cp 2
	ld hl, FlowerTile1
	jr c, .copy
	ld hl, FlowerTile2
	jr z, .copy
	ld hl, FlowerTile3

.copy
	ld de, vTileset + $3 * $10
	ld c, $10	; ループ回数 = 16 = 2bppで1タイル

.loop
; VRAM に FlowerTileN の 2bppデータをコピー
; {
	; [de++] = [hl++]
	ld a, [hli]
	ld [de], a
	inc de
	dec c
	jr nz, .loop
; }
	ret

FlowerTile1: INCBIN "gfx/tilesets/flower/flower1.2bpp"
FlowerTile2: INCBIN "gfx/tilesets/flower/flower2.2bpp"
FlowerTile3: INCBIN "gfx/tilesets/flower/flower3.2bpp"
