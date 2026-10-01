// ===== マイクスタンド（縦置き・4本 / 2x2配置） =====
// 寸法はすべてmm。数値を変えてOpenSCADで再出力可能。

// --- マイク受け穴（テーパー形状：有線/ワイヤレス両対応） ---
hole_top_d    = 45;   // 穴の上端径
hole_bottom_d = 24;   // 穴の底径
hole_depth    = 60;   // 穴の深さ

// --- カップ（穴の外壁） ---
cup_top_d     = 53;   // カップ上端外径
cup_bottom_d  = 62;   // カップ下端外径
floor_t       = 3;    // 穴底の厚み

// --- 配置・ベース ---
pitch         = 72;   // マイク中心間距離
base_w        = 150;  // ベース一辺
base_t        = 5;    // ベース厚
corner_r      = 12;   // ベース角R

$fn = 128;
cup_h = hole_depth + floor_t;

module base_plate() {
  translate([-base_w/2 + corner_r, -base_w/2 + corner_r, 0])
    linear_extrude(base_t)
      offset(r = corner_r) square(base_w - 2*corner_r);
}

module cup()  { cylinder(h = cup_h, d1 = cup_bottom_d, d2 = cup_top_d); }
module hole() {
  translate([0, 0, floor_t]) cylinder(h = hole_depth + 0.01, d1 = hole_bottom_d, d2 = hole_top_d);
  // 上端の面取り
  translate([0, 0, cup_h - 2]) cylinder(h = 2.01, d1 = hole_top_d, d2 = hole_top_d + 4);
}

positions = [for (x = [-1, 1], y = [-1, 1]) [x * pitch/2, y * pitch/2]];

difference() {
  union() {
    base_plate();
    for (p = positions) translate([p[0], p[1], 0]) cup();
  }
  for (p = positions) translate([p[0], p[1], 0]) hole();
}
