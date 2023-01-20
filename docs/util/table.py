# ファイル一覧テーブルを作る際のutilスクリプト
import glob

asms = [asm.lstrip(".\\") for asm in glob.glob("./*.asm")]

table = ""
for asm in asms:
    table += "{} | null\n".format(asm)
print(table)
