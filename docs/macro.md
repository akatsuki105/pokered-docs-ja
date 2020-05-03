# マクロ

`rgbasm`では以下のようにしてマクロを定義できる

```asm
MyMacro: MACRO
        ld   a,80
        call MyFunc
        ENDM
```

