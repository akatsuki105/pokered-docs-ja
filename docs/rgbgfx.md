# rgbgfx

png画像をGameBoyで利用できるグラフィックフォーマットにする変換ツール

## 概要

rgbgfxはpng画像をGameBoyで利用できるグラフィックフォーマットにする変換ツールである

入力で与えたpng画像の色によって、変換の結果生じる色やパレット番号は様々なものになる
 - もしpngファイルがファイル内にパレットデータを持っているなら、そのパレットカラーと順番が利用される
 - パレットデータを持っていないかつ画像がグレースケールなら、rgbgfxは画像に適切にパレット番号を割り当てる。未定のインデックスは、それぞれデフォルトの灰色の濃淡に設定される。たとえば、ビット深度が2で、画像に明るい灰色と黒色が含まれている場合、それらは2番目と4番目の色になり、1番目と3番目の色はデフォルトの白色と暗い灰色に設定される。 同じインデックスにマップする複数のシェードがイメージにある場合、代わりに、イメージにカラーがあるかのようにパレットが決定される。
 - もし画像がグレースケールでない色を持った画像なら、色は 明->暗 の順にソートされる

入力画像には、選択したビット深度が許可するよりも多くの色を含めることはできない。また透明ピクセルはパレット番号0に設定される。

## 使い方

```sh
rgbgfx	[-CDhmuVv] [-f | -F] [-a attrmap | -A] [-d depth] [-o out_file] [-p pal_file | -P] [-t tilemap | -T] [-x tiles] file
```

### オプション一覧

Note that options can be abbreviated as long as the abbreviation is unambiguous: --verb is - -verbose, but --ver is invalid because it could also be --version. The arguments are as follows:

オプションは一意に定まる範囲でなら省略が可能  
例: --verboseは --verbまでなら省略が可能だが--verは--versionとの識別ができないので不可能

 ショート | ロング |  内容
 ----  | ---- | ----
 -a  | --attr-map | Generate a file of tile mirroring attributes for OAM or (CGB-only) background tiles. For each tile in the input file, a byte is written representing the dimensions that the associated tile in the output file should be mirrored. Useful in combination with -m to keep track the mirror direction of mirrored duplicate tiles.
 -A  | --output-attr-map | Same as -a, but the attrmap file output name is made by taking the input filename, removing the file extension, and appending .attrmap.
 -C  | --color-curve | Use the color curve of the Game Boy Color when generating palettes.
 -D  | --debug | Debug features are enabled.
 -d  | --depth | 出力データのビット深度 デフォルトでは2(2ビットで1pxを表す)
 -f  | --fix | Fix the input PNG file to be a correctly indexed image.
 -F  | --fix-and-save | Same as -f, but additionally, the supplied command line parameters are saved within the PNG and will be loaded and automatically used next time.
 -h  | --horizontal | Lay out tiles horizontally rather than vertically.
 -m  | --mirror-tiles | Truncate tiles by checking for tiles that are mirrored versions of others and omitting these from the output file. Useful with tilemaps and attrmaps together to keep track of the duplicated tiles and the dimension mirrored. Tiles are checked for horizontal, vertical, and horizontal-vertical mirroring. Implies -u.
 -o  | --output | 出力先のファイル名
 -p  | --palette | Output the image's palette in standard GBC palette format: bytes (8 bytes for two bits per pixel, 4 bytes for one bit per pixel) containing the RGB15 values in little-endian byte order. If the palette contains too few colors, the remaining entries are set to black.
 -P  | --output-palette | Same as -p, but the palette file output name is made by taking the input PNG file's filename, removing the file extension, and appending .pal.
 -t  | --tilemap | Generate a file of tile indices. For each tile in the input file, a byte is written representing the index of the associated tile in the output file. Useful in combination with -u or -m to keep track of duplicate tiles.
 -T  | --output-tilemap | Same as -t, but the tilemap file output name is made by taking the input filename, removing the file extension, and appending .tilemap.
 -u  | --unique-tiles | Truncate tiles by checking for tiles that are exact duplicates of others and omitting these from the output file. Useful with tilemaps to keep track of the duplicated tiles.
 -V  | --version | rgbgfxのバージョンを出力
 -v  | --verbose | Verbose. Print errors when the command line parameters and the parameters in the PNG file don't match.
 -x  | --trim-end | Trim the end of the output file by this many tiles.

## 例

```sh
# 次のコマンドはpngファイルをビット深度1か2か8で解釈して2bppフォーマットに変換する
rgbgfx -o out.2bpp in.png

# 次のコマンドは一意のタイルのみを含む平面2bppファイルを作成し、out.tilemapにタイルマップを出力する
$ rgbgfx -T -u -o out.2bpp in.png

# The following creates a planar 2bpp file with only unique tiles accounting for tile mirroring and its associated tilemap out.tilemap and attrmap out.attrmap:
$ rgbgfx -A -T -m -o out.2bpp in.png

# 次のコマンドは何もしない
$ rgbgfx in.png
```

## 参考

[RGBGFX(1)](https://rednex.github.io/rgbds/rgbgfx.1.html)
[PNGの規格を簡単に説明する](https://dawn.hateblo.jp/entry/2017/10/22/205417)