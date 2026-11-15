// L字フック 40x40（ビス穴2か所）  単位：mm
// 横板が底面（z=0）、縦板が背面（y=0）。丸棒は縦板の内側から出て、先端が上へ立ち上がる。

// ---- 板（L字） ----
w = 30;        // 幅
h = 40;        // 縦板の高さ
d = 40;        // 横板の奥行
t = 4;         // 板厚

// ---- 丸棒（フック） ----
rod_d   = 6;   // 丸棒の太さ（直径）
rod_len = 20;  // 縦板の面から先端までの長さ
rod_z   = 20;  // 底面から丸棒の中心までの高さ
up_top  = 37;  // 立ち上がりの上端の高さ（底面から）
root    = 1.5; // 付け根の補強（0で補強なし）

// ---- ビス穴（底面に2か所、丸棒の左右） ----
hole_d = 4.5;  // 穴の直径（M4ビス想定）
hole_x = 5;    // 板の端から穴の中心まで
hole_y = 22;   // 縦板の外面から穴の中心まで

$fn = 64;

bend_y = t + rod_len - rod_d/2;  // 丸棒が上へ曲がる位置

difference() {
  union() {
    cube([w, t, h]);   // 縦板
    cube([w, d, t]);   // 横板
    // 丸棒（水平部）
    translate([w/2, t/2, rod_z]) rotate([-90, 0, 0])
      cylinder(d = rod_d, h = bend_y - t/2);
    // 付け根の補強
    if (root > 0)
      translate([w/2, t, rod_z]) rotate([-90, 0, 0])
        cylinder(d1 = rod_d + 2*root, d2 = rod_d, h = root);
    // 曲がり部
    translate([w/2, bend_y, rod_z]) sphere(d = rod_d);
    // 立ち上がり
    translate([w/2, bend_y, rod_z])
      cylinder(d = rod_d, h = up_top - rod_z);
  }
  // ビス穴
  for (x = [hole_x, w - hole_x])
    translate([x, hole_y, -1]) cylinder(d = hole_d, h = t + 2);
}
