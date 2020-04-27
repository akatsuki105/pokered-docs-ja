# 1bppフォーマット

GameBoyのグラフィックフォーマット

1bitで1pxを表すことから1bpp(1 Bits Per Pixel)と呼ぶ。

1bitなので1*2=2パターンの色が最大で使用可能

1bppでは1タイルが8byteで表される。  
(1タイル = 8*8px = 64px なので 64\*1 = 64bit = 8\*8bit = 8byte)  

タイルの各行は1byteずつで表され、

```
Byte -> 色のビット情報(nbit目 -> 左から(7-n)pxの色)
```

を表す。

## 関連

[2bpp](./2bpp.md)