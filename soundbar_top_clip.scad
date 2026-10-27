// サウンドバー上面クリップ（I-O DATA LCD-U651DX ＋ サンワ 400-SP092 用）
// 2個印刷して左右に掛ける。数値を変えて再出力できます。

/* [モニター] */
T        = 25;   // モニター上端の厚さ（前後方向）mm ★要実測
clr      = 0.6;  // クリップの遊び
front_d  = 6;    // 前側の爪の長さ（画面にかかる量）
back_d   = 45;   // 背面側の脚の長さ

/* [サウンドバー] */
bar_d    = 50;   // サウンドバー奥行
bar_clr  = 1;    // 受け台の遊び
tilt     = 8;    // 下向き角度（度）
lift     = 15;   // モニター上端から受け台までの高さ（放熱用）
lip_h    = 12;   // 前側の立ち上がり高さ
back_h   = 30;   // 後ろ壁の高さ

/* [本体] */
W        = 40;   // クリップ幅
wall     = 4;    // クリップの肉厚
front_t  = 3;    // 前爪の厚み
cw       = 3;    // 受け台の壁厚
base_t   = 7;    // 受け台の底厚（結束バンド穴を内蔵）
tie_w    = 7;    // 結束バンド穴の幅
tie_h    = 3;    // 結束バンド穴の高さ
test_only = false; // true でクリップ部だけの試し刷り（幅8mm）

D  = bar_d + 2*bar_clr + 2*cw;   // 受け台の全奥行
y0 = T/2 - D/2;                  // 受け台前端（モニター中心に合わせる）
zc = wall + lift;                // 受け台前端の底の高さ

module clip2d() {
  translate([-clr-front_t, 0]) square([T + 2*clr + front_t + wall, wall]); // 天板
  translate([-clr-front_t, -front_d]) square([front_t, front_d]);           // 前爪
  translate([T+clr, -back_d]) square([wall, back_d]);                      // 背面脚
}
module cradle2d() {
  translate([y0, zc]) rotate(tilt) {
    square([D, base_t]);                          // 底
    square([cw, base_t + lip_h]);                 // 前の立ち上がり
    translate([D-cw, 0]) square([cw, base_t + back_h]); // 後ろ壁
  }
}
module support2d() {
  hull() {
    translate([-clr-front_t, wall-1]) square([T + 2*clr + front_t + wall, 1]);
    translate([y0, zc]) rotate(tilt) square([D, 1]);
  }
}
module part() {
  if (test_only) {
    linear_extrude(8) clip2d();
  } else {
    difference() {
      linear_extrude(W) union() { clip2d(); support2d(); cradle2d(); }
      // 結束バンド穴（受け台の底を前後に貫通）
      translate([0, 0, W/2]) linear_extrude(tie_w, center=true)
        translate([y0, zc]) rotate(tilt)
          translate([-5, (base_t - tie_h)/2]) square([D + 10, tie_h]);
    }
  }
}
// 横倒し（側面形状がベッドに乗る向き）で出力。層方向に割れにくい。
part();
