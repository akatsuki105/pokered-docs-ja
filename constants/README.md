# constants

定数データのマクロ定義を行っている

マクロなのでROMデータには直接関係ないが可読性をあげるために定数データのマクロ定義をここでは行っている

## マクロについて

### EQUマクロ

再定義不可能な定数シンボルの定義に用いる

```asm
SCREEN_WIDTH   equ 160 ; In pixels
SCREEN_HEIGHT  equ 144
```

### SETマクロ

定数シンボルの定義に用いる  
EQUと違って再定義が可能

```asm
ARRAY_SIZE EQU 4
COUNT      SET 2                    ; COUNT = 2
COUNT      SET ARRAY_SIZE+COUNT     ; COUNT = 4 + 2
COUNT      = COUNT + 1              ; COUNT += 1
```

### constマクロ

このレポジトリで定義されているマクロ  
定数の列挙に使うマクロでgolangのiotaみたいなもの  
詳しくは[data_macros.asm](../macros/data_macros.asm)参照

## 各ファイルについて

各ファイル先頭のコメントを参照
