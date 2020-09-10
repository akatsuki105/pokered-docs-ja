# Pokemon Data

ここではポケモンのデータのうち動的に変わるデータ(`Pokemon Data`)についての解説を行う

## PCボックスのポケモン

ボックス内のポケモンが保持している Pokemon Data は `box_struct` というデータ構造に従う

```asm
box_struct: MACRO
\1Species::    db
\1HP::         dw
\1BoxLevel::   db
\1Status::     db
\1Type::
\1Type1::      db
\1Type2::      db
\1CatchRate::  db
\1Moves::      ds NUM_MOVES
\1OTID::       dw
\1Exp::        ds 3
\1HPExp::      dw
\1AttackExp::  dw
\1DefenseExp:: dw
\1SpeedExp::   dw
\1SpecialExp:: dw
\1DVs::        ds 2
\1PP::         ds NUM_MOVES
END
```

#### DV

個体値(Individual Values)のこと

\1DVs(2バイトの領域)に以下のフォーマットで格納されている

```
1 byte: 0bAAAABBBB (A=攻撃, B=防御)
2 byte: 0bCCCCDDDD (C=素早さ, D=特殊)
```

- 初代は特攻と特防が 特殊という1つのステータスで扱われている点
- HPの個体値は 攻撃、防御、素早さ、特殊の個体値の偶奇から算出される点

に注意

WRAM上で、PCボックスのポケモンがどのように扱われているのかについては [PCボックスのポケモン](./box.md)参照

## 手持ちのポケモン

手持ちのポケモンが保持している Pokemon Data は `party_struct` というデータ構造に従う

基本的にはボックスのポケモンと同じ情報を保持しているが、加えてレベルや努力力計算されたステータス情報を保持する

```asm
party_struct: MACRO
	box_struct \1
\1Level::      db
\1Stats::
\1MaxHP::      dw
\1Attack::     dw
\1Defense::    dw
\1Speed::      dw
\1Special::    dw
ENDM
```

WRAM上で、手持ちのポケモンがどのように扱われているのかについては[手持ちのポケモン](./party.md)参照

## 育て屋のポケモン

育て屋に預けているポケモンが保持している Pokemon Data はPCボックスのポケモンと同じ `box_struct` というデータ構造に従う

WRAM上で、手持ちのポケモンがどのように扱われているのかについては[育て屋のポケモン](./daycare.md)参照

## 戦闘中のポケモン

戦闘中のポケモンが保持している Pokemon Data は `battle_struct` というデータ構造に従う

技のPPなど戦闘中に必要なデータを保持する

```asm

battle_struct: MACRO
\1Species::    db
\1HP::         dw
\1PartyPos::
\1BoxLevel::   db
\1Status::     db
\1Type::
\1Type1::      db
\1Type2::      db
\1CatchRate::  db
\1Moves::      ds NUM_MOVES
\1DVs::        ds 2
\1Level::      db
\1Stats::
\1MaxHP::      dw
\1Attack::     dw
\1Defense::    dw
\1Speed::      dw
\1Special::    dw
\1PP::         ds NUM_MOVES
ENDM

```

## 関連

- [Pokemon Header](./pokemon_header.md)

