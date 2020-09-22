# engine

ゲームシステムを構築するスクリプトが含まれる

## ファイル

 ファイル名  |  内容
---- | ----
battle/ | [battle](./battle/README.md)
items/ | [items](./items/README.md)
menu/ | [menu](./menu/README.md)
overworld/ | [overworld](./overworld/README.md)
add_mon.asm | Pokemon Data を新しい手持ちやPCなどのデータスロットに加える処理
bcd.asm | BCDフォーマットの数値計算を行う処理
black_out.asm | 『めのまえが まっくらに なった！』ときのゲームの状態を更新する処理
cable_club.asm | null
clear_save.asm | タイトル画面でのセーブデータ完全消去のダイアログ
debug1.asm | null
display_pokedex.asm | null
display_text_id_init.asm | null
evolution.asm | null
evolve_trade.asm | null
evos_moves.asm | null
experience.asm | 経験値からレベルを算出したりなど、経験値に関わる計算を行う
flag_action.asm | フラグアクションに関する処理
game_corner_slots.asm | null
game_corner_slots2.asm | null
gamefreak.asm | ゲーム起動時のゲーフリのロゴと流れ星のアニメーション
get_bag_item_quantity.asm | null
give_pokemon.asm | null
hall_of_fame.asm | null
heal_party.asm | ポケモンのHPとPPを回復させる
hidden_object_functions3.asm | null
hidden_object_functions7.asm | null
hidden_object_functions14.asm | null
hidden_object_functions17.asm | null
hidden_object_functions18.asm | null
HoF_room_pc.asm | null
hp_bar.asm | null
in_game_trades.asm | null
init_player_data.asm | ゲームを『はじめから』始めたときにプレイヤーデータを初期化する
intro.asm | ゲーム起動時のアニメーションを流す
joypad.asm | A,B,Start,Select を同時に押したときのリセット処理
learn_move.asm | null
load_mon_data.asm | ポケモンのデータが必要な時にそれを取得する処理
load_pokedex_tiles.asm | null
mon_party_sprites.asm | null
multiply_divide.asm | null
oak_speech.asm | 『さいしょからはじめる』を選んだ時のオーキド博士のスピーチ
oak_speech2.asm | オーキド博士のスピーチで使用されるユーティリティ関数などがまとめてある
oam_dma.asm | OAM DMA転送を行う処理
palettes.asm | SGBでのみ有効なので割愛
pathfinding.asm | NPCがプレイヤーのところに歩いてくるときに道順(Path)を決定する処理
play_time.asm | プレイ時間をフレーム単位でインクリメントする処理
pokedex_rating.asm | ポケモン図鑑の評価テキストを表示する処理
predefs.asm | predefに関するスクリプト <br/>predefについては[ドキュメント](../docs/predef.md)を参照
predefs7.asm | バンク7に属するpredef-routineを定義
predefs12.asm | バンク12に属するpredef-routineを定義
predefs17_2.asm | バンク17に属するpredef-routineを定義
predefs17.asm | バンク17に属するpredef-routineを定義 その2
print_waiting_text.asm | 『つうしんたいきちゅう!』を表示する関数を定義
random.asm | 乱数生成処理
remove_pokemon.asm | ポケモンを削除する処理
save.asm | null
slot_machine.asm | null
special_warps.asm | special warpを行う処理
status_ailments.asm | 瀕死じゃないポケモンの状態異常を文字として描画する
subtract_paid_money.asm | プレイヤーの支払った額をプレイヤーの所持金から引く処理
test_battle.asm | null
titlescreen.asm | タイトル画面に関する処理
titlescreen2.asm | タイトル画面に関する処理2
town_map.asm | null
trade.asm | null
trade2.asm | null
turn_sprite.asm | スプライトのグラフィックに現在の方向を反映させる
