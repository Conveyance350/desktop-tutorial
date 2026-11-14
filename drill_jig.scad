// パイプ穴あけ治具（φ3 下穴ガイド）　3Dプリント用
// 単位 mm。パイプにかぶせ、前後の壁のガイド穴にφ3ドリルを通して、パイプの芯を貫通させる。
// 造形の向き：このまま（平らな面が下、溝が上向き）。サポート不要。

pipe_d  = 28;    // パイプ外径
fit     = 0.4;   // パイプとのすき間（きつい場合は増やす）
pitch   = 120;   // 穴ピッチ
guide_d = 3.4;   // ガイド穴径（φ3ドリル用。造形で小さくなる分を見込む）
wall    = 15;    // 前後の壁の厚み（＝ガイドの長さ）
top_t   = 8;     // 溝の底の厚み
end_m   = 15;    // 穴から端までの距離
$fn = 96;

r = (pipe_d + fit) / 2;
L = pitch + 2 * end_m;        // 全長 150
W = 2 * r + 2 * wall;         // 幅（穴あけ方向）
zc = top_t + r;               // パイプの芯の高さ
H = zc + pipe_d / 2;          // 高さ（パイプの下端まで）

difference() {
  cube([L, W, H]);
  // パイプが入る溝（底は半円、上は開放）
  translate([-1, W / 2, zc]) rotate([0, 90, 0]) cylinder(r = r, h = L + 2);
  translate([-1, W / 2 - r, zc]) cube([L + 2, 2 * r, H]);
  // ガイド穴（前後の壁を同軸で貫通）
  for (x = [end_m, end_m + pitch])
    translate([x, -1, zc]) rotate([-90, 0, 0]) cylinder(d = guide_d, h = W + 2);
  // 中心の合わせ線（外側3面）
  translate([L / 2 - 0.5, -1, -0.01]) cube([1, W + 2, 1]);
  translate([L / 2 - 0.5, -0.01, -1]) cube([1, 1, H + 2]);
  translate([L / 2 - 0.5, W - 0.99, -1]) cube([1, 1, H + 2]);
}
