# overworld

プレイヤーがマップ上にいるときのゲームシステムを構築しているスクリプト

NPCの動きなどを定義している

## ファイル

 ファイル名  |  内容
---- | ----
cable_club_npc.asm | null 
card_key.asm | シルフカンパニーでカードキーを利用するときの処理       
cinnabar_lab.asm | グレンタウンの『ポケモンけんきゅうじょ』で化石を研究員に渡す処理   
clear_variables.asm | マップが切り替わるときにマップにかかわる変数を初期化する処理
cut.asm | null
cut2.asm | null
daycare_exp.asm | 育て屋のポケモンの経験値をインクリメントする処理    
doors.asm | ドアタイルから強制的に下に歩かせる処理
elevator.asm | エレベータを揺らす処理       
emotion_bubbles.asm | !マークなどの感情を表す吹き出しを表示させる処理
field_move_messages.asm | かいりきのテキストや、波乗りができない水辺のテキスト
healing_machine.asm | 回復マシンの稼働時のアニメーション+サウンド処理
hidden_items.asm | 隠しアイテム取得の処理
hidden_objects.asm | dungeon warp関連の処理とhidden objectに関連する処理
is_player_just_outside_map.asm | プレイヤーがマップの外側の1タイルにいるかどうかを判定する処理
item.asm | null
ledges.asm | 段差飛び降り処理を行う
map_sprites.asm | マップ上のスプライトのタイルデータをVRAMにロードする処理 
map_sprite_functions1.asm | null
missable_objects.asm | null
movement.asm | null
npc_movement.asm | null
oaks_aide.asm | 関所にいるオーキド博士の助手との会話処理を行う
oam.asm | 現在、可視化する必要がある スプライト(人や岩など)のOAMデータ を決定して、それを wOAMBuffer に書き込む関数<br/>VBlank中に実行される
pewter_guys.asm | ニビシティの強制連行イベント処理  
player_animations.asm | null
player_state.asm | null
poison.asm | マップ上で歩いているときに毒ダメージを与える処理 
pokecenter.asm | ポケモンセンターでジョーイさんに話しかけたときの処理
pokemart.asm | フレンドリーショップでのアイテム売買の処理
push_boulder.asm | null
saffron_guards.asm | ヤマブキシティのゲートの"のどが渇いた警備員"にドリンクを渡す処理
set_blackout_map.asm | null
ssanne.asm | null
tileset_header.asm | マップ切り替わり時にタイルセットを更新する処理
trainers.asm | null
update_map.asm | ブロックを書き換えたりマップの更新を行う処理
wild_mons.asm | null
