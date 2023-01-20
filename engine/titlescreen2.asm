; モンスターボールが跳ねるのを待つ処理を定義したテーブル  
; 各エントリ = high:low = スクロール速度:スクロール期間  
; スクロール速度が0なので、このテーブルの処理は待機処理を表している  
TitleScroll_WaitBall:
	db $05, $05, 0

; タイトル画面のポケモンを画面右からスクロールさせてくる処理の内容  
; 各エントリ = high:low = スクロール速度:スクロール期間  
TitleScroll_In:
	db $a2, $94, $84, $63, $52, $31, $11, 0

; タイトル画面のポケモンを画面左にスクロールさせて画面外に出す処理の内容  
; 各エントリ = high:low = スクロール速度:スクロール期間  
TitleScroll_Out:
	db $12, $22, $32, $42, $52, $62, $83, $93, 0

; タイトル画面のポケモンを スクロールin or スクロールout する処理  
; INPUT: d = 0(in) or 1(out)
TitleScroll:
	; bc = TitleScroll_In or TitleScroll_Out
	; d = $88 or $00
	; e = $0
	ld a, d

	ld bc, TitleScroll_In
	ld d, $88
	ld e, 0 ; don't animate titleball

	and a
	jr nz, .ok

	ld bc, TitleScroll_Out
	ld d, $00
	ld e, 0 ; don't animate titleball
.ok ; そのまま_TitleScrollへ続く

; INPUT:  
; - [bc] = スクロール速度:スクロール期間  
; - e = 0(モンスターボールを跳ねさせる) or 1(跳ねさせない)
_TitleScroll:
	; TitleScroll_In or TitleScroll_Out の終わりに来た -> 終了
	ld a, [bc] ; a = スクロール速度:スクロール期間 
	and a
	ret z

	inc bc ; 次のエントリ
	push bc

	; c = スクロール期間
	ld b, a
	and $f
	ld c, a
	; b = スクロール速度
	ld a, b
	and $f0
	swap a
	ld b, a

.loop
	; $48~の間をdだけスクロールさせる
	ld h, d
	ld l, $48
	call .ScrollBetween
	; $88~をスクロールしないようにする
	ld h, $00
	ld l, $88
	call .ScrollBetween

	; d += b(スクロール速度)
	ld a, d
	add b
	ld d, a

	call GetTitleBallY ; モンスターボールが跳ねる処理をリセット(e = 0なので)
	dec c
	jr nz, .loop ;　スクロール期間が残っているとき -> .loop

	pop bc
	jr _TitleScroll ; テーブル TitleScroll_In or TitleScroll_Out を次のエントリに

; Y座標(pixel)が l より下の画面をを h だけスクロールさせる
.ScrollBetween:
.wait
	ld a, [rLY] ; rLY
	cp l
	jr nz, .wait

	ld a, h
	ld [rSCX], a

.wait2
	ld a, [rLY] ; rLY
	cp h
	jr z, .wait2
	ret

; タイトル画面で主人公が持っているモンスターボールのY座標(pixel)の座標変化を表した配列  
; 始点と終点が0で埋められており、ボールが跳ねる処理を行う場合は$71から始める
TitleBallYTable:
	db 0, $71, $6f, $6e, $6d, $6c, $6d, $6e, $6f, $71, $74, 0

; starterが画面外にスクロールしたときモンスターボールを跳ねさせる処理を行う  
; starter = タイトル画面に最初にでるポケモン(ヒトカゲ or ゼニガメ or フシギダネ)
TitleScreenAnimateBallIfStarterOut:
	; [wTitleMonSpecies] が ヒトカゲ or ゼニガメ or フシギダネ => .ok
	ld a, [wTitleMonSpecies]
	cp STARTER1
	jr z, .ok
	cp STARTER2
	jr z, .ok
	cp STARTER3
	ret nz
.ok
	ld e, 1 ; animate titleball
	ld bc, TitleScroll_WaitBall
	ld d, 0
	jp _TitleScroll

; TitleBallYTableのエントリeを取得する  
; 取得した値は aと[wOAMBuffer + $28](モンスターボールのOAM)に格納
GetTitleBallY:
	push de
	push hl
	; d = 0
	xor a
	ld d, a
	; hl = TitleBallYTable + e
	ld hl, TitleBallYTable
	add hl, de
	; a = TitleBallYTableのエントリe
	ld a, [hl]
	pop hl
	pop de
	; a == 0 -> 終了
	and a
	ret z
	; a != 0のとき
	; モンスターボールのOAM(Buffer)のY座標を更新して終了
	ld [wOAMBuffer + $28], a
	inc e ; e++
	ret
