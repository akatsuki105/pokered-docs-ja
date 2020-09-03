# NPC movement script

プレイヤーやNPCを動かすための関数のうち、`RunNPCMovementScript` によって実行される特殊な関数を `NPC movement script` という

これが使われるのは

- マサラタウンで、オーキド博士に研究所に連行されるイベント
- ニビシティでジムバッジを持っていないとニビジムに連行されるイベント
- ニビ科学博物館での連行イベント

とどれも連行イベントに関するものである

`NPC movement script` とあるが、プレイヤーも動くことには注意

## RunNPCMovementScript

`RunNPCMovementScript` ではまず内部の `.NPCMovementScriptPointerTables`  テーブルから `[wNPCMovementScriptPointerTableNum]` に対応するエントリを選ぶ

```asm
.NPCMovementScriptPointerTables
	dw PalletMovementScriptPointerTable             ; [wNPCMovementScriptPointerTableNum] = 1
	dw PewterMuseumGuyMovementScriptPointerTable    ; [wNPCMovementScriptPointerTableNum] = 2
	dw PewterGymGuyMovementScriptPointerTable       ; [wNPCMovementScriptPointerTableNum] = 3
```

エントリの中にはさらに、`NPC movement script` のアドレスのテーブルがあるので、次はそこから `[wNPCMovementScriptFunctionNum]` に対応する `NPC movement script` を選んで実行する

```asm
PalletMovementScriptPointerTable:
	dw PalletMovementScript_OakMoveLeft             ; [wNPCMovementScriptFunctionNum] = 0
	dw PalletMovementScript_PlayerMoveLeft          ; [wNPCMovementScriptFunctionNum] = 1
	dw PalletMovementScript_WaitAndWalkToLab        ; [wNPCMovementScriptFunctionNum] = 2
	dw PalletMovementScript_WalkToLab               ; [wNPCMovementScriptFunctionNum] = 3
	dw PalletMovementScript_Done
```

実行された`NPC movement script`では、NPCの移動には [`scripted NPC`](./update.md) が、プレイヤーの移動には [`simulated joypad`](../simulated_joypad.md) が使われている

