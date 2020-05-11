# simulated joypad

ポケモン赤にシミュレートされたキー入力のこと  
つまりゲームによって勝手にキー入力をされている状態

pewter guyなどNPCの強制連行イベントなどでこの状態になる

## description

- wSimulatedJoypadStatesEnd
- wSimulatedJoypadStatesIndex

の2種類のアドレスの値が`simulated joypad`と関連している

プレイヤーの`simulated joypad`によるキー入力は`wSimulatedJoypadStatesEnd + [wSimulatedJoypadStatesIndex]`の値となる

simulated joypadの1入力のたびに`wSimulatedJoypadStatesIndex`の値がデクリメントされ、`wSimulatedJoypadStatesEnd + [wSimulatedJoypadStatesIndex]`の値が`wSimulatedJoypadStatesEnd`と等しいとき、つまり`[wSimulatedJoypadStatesIndex]`が0のときに`simulated joypad`状態は終了する

## 関連

- [pewter guy](./pewter_guys.md)
