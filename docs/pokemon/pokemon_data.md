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

