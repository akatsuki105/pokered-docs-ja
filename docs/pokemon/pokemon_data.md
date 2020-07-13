# Pokemon Data

ここではポケモンのデータのうち動的に変わるデータについての解説を行う

[`wram.asm`](../../wram.asm)で定義されている

## box_struct

ボックス内のポケモンが保持しているデータ

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
ENDM

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

## party_struct

パーティ内のポケモンが保持しているデータ

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

## battle_struct

戦闘中のポケモンが保持しているデータ

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

