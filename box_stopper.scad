// ボックスストッパー小型版　3Dプリント試作用データ
// 単位 mm。part を切り替えて部品ごとに STL を書き出す。
// 注意：樹脂の試作は「組付け・動きの確認用」。実機の箱止めには鋼材品を使うこと。

part = "assembly";   // "assembly" / "base" / "stopper" / "spacer" / "cover" / "backplate"
hole_extra = 0.4;    // 穴径の追加分（3Dプリントは穴が小さく仕上がるため）。鋼材図面どおりにするなら 0
stroke_pos = 0;      // 組立表示のストッパー位置：0=上昇（止め）、-20=下降（解除）
$fn = 64;

t  = 4.5;   // 板厚（ベース板・ストッパー板・押さえ板・当て板）
ts = 6;     // スペーサー厚

module hole(x, y, d, h) { translate([x, y, -1]) cylinder(d = d + hole_extra, h = h + 2); }

// ① ベース板 150×65×4.5　4-φ7、2-φ9
module base() {
  difference() {
    cube([150, 65, t]);
    for (x = [34, 116]) for (y = [15, 55]) hole(x, y, 7, t);   // 上端から10・50（下端から55・15）
    for (x = [15, 135]) hole(x, 32.5, 9, t);
  }
}

// ②＋⑤ ストッパー板（65×95×4.5）と踏み板（幅32、突出60）の一体品
//   裏面（z=0）を下にして造形する。サポート不要。
module stopper() {
  difference() {
    union() {
      cube([65, 95, t]);
      // 踏み板：側面形状（y=板の長さ方向、u=前面からの突出）を幅32で押し出す
      translate([16.5, 0, t]) rotate([90, 0, 90]) linear_extrude(32)
        difference() {
          polygon([[95 - 4, -0.5], [95 - 4, 0], [95 - 24, 60], [95 - 28.5, 60], [95 - 44.5, 0], [95 - 44.5, -0.5]]);
          polygon([[95 - 8.74, 0], [95 - 26, 51.8], [95 - 39.84, 0]]);
        }
    }
    for (x = [7.5, 57.5]) {
      hole(x, 10, 6.6, t);                                                   // ばね掛けボルト M6
      translate([x, 10, -0.01]) cylinder(d1 = 13 + hole_extra, d2 = 6.6 + hole_extra, h = 3.2);  // 裏面 皿もみ
    }
  }
}

// ③ スペーサー 60×16×6　2-φ7（2個造形）
module spacer() {
  difference() { cube([60, 16, ts]); for (x = [10, 50]) hole(x, 8, 7, ts); }
}

// ④ 押さえ板 60×25×4.5　2-φ7（外側の端から8）（2個造形）
module cover() {
  difference() { cube([60, 25, t]); for (x = [10, 50]) hole(x, 8, 7, t); }
}

// ⑪ 当て板 150×25×4.5　2-φ9
module backplate() {
  difference() { cube([150, 25, t]); for (x = [15, 135]) hole(x, 12.5, 9, t); }
}

// 組立表示（確認用。x=幅、y=上下、z=台車側）
module assembly() {
  color("lightgray") translate([-75, -65, 0]) base();
  color("lightgray") translate([-75, -45, -32.5]) backplate();
  for (s = [1, -1]) scale([s, 1, 1]) {
    color("silver") translate([49, -60, t]) rotate([0, 0, 90]) spacer();
    color("gainsboro") translate([49, -60, t + ts]) rotate([0, 0, 90]) cover();
  }
  color("royalblue") translate([-32.5, -75 + stroke_pos, t + 0.3]) stopper();
  %translate([-150, -32.5, -14]) rotate([0, 90, 0]) cylinder(d = 28, h = 300);   // パイプ φ28（参考）
}

if (part == "base") base();
else if (part == "stopper") stopper();
else if (part == "spacer") spacer();
else if (part == "cover") cover();
else if (part == "backplate") backplate();
else assembly();
