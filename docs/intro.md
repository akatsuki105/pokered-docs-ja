# intro

ゲーム開始時のアニメーションのこと

<img src="./image/intro/intro.gif" />

`PlayIntro` から処理が始まる

## PlayShootingStar

コピーライト + ゲーフリロゴ のアニメーションを流す

<img src="./image/intro/gamefreak.gif" />

 処理の大半を内部の `AnimateShootingStar` で行っている  

 `AnimateShootingStar` では `CheckForUserInterruption` でユーザーのキー入力チェックを行っていて、特定のキーが押されたときは、アニメーションをスキップしている

## PlayIntroScene

ここでゲンガーとニドリーノが戦っているアニメーションを流す

ゲンガーは 背景として描画されているが、ニドリーノは スプライトとして配置されている
