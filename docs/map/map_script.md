# Map Script

マップに紐づけられた処理

Map Script は `OverworldLoop` の `JoypadOverworld` の `RunMapScript` によって毎フレーム実行される

## RunMapScript

`RunMapScript` ではまず、かいりき岩を押す処理と、NPC Movement scriptが実行中かチェックし、実行中ならその処理をまず行う

その後、`wMapScriptPtr` に格納された Map Script を実行する

## wMapScriptPtr

`wMapScriptPtr` にはそのマップのMap Scriptの一番大元の処理(Root Map Script)が記述されている

例としてマサラタウンの Root Map Script を解説する

```asm
PalletTown_Script:
; オーキド博士からモンスターボールを5個もらうイベントを消化しているなら EVENT_PALLET_AFTER_GETTING_POKEBALLS フラグを立てる
	CheckEvent EVENT_GOT_POKEBALLS_FROM_OAK
	jr z, .next
	SetEvent EVENT_PALLET_AFTER_GETTING_POKEBALLS
.next

	; PalletTown_ScriptPointers の [wPalletTownCurScript]が指す map scriptを実行
	call EnableAutoTextBoxDrawing
	ld hl, PalletTown_ScriptPointers
	ld a, [wPalletTownCurScript]
	jp CallFunctionInTable
```

後半の処理で `PalletTown_ScriptPointers` の `[wPalletTownCurScript]` が指すMap Scriptを呼び出している

このように Root Map Script では、毎フレーム実行されるべき処理 + `wXXXXCurScript` が指す処理へのジャンプを行っている