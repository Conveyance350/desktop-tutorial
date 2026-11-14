// 穴あけ治具 2穴版（パイプφ28・φ32共用・2つ割りクランプ式）
// 1回の締付けで複数の穴をあけ、穴ピッチを治具で決める。
// V溝で受けるのでパイプ径が変わっても穴はパイプ中心を通る。
// 部品: top=上ブロック（ゲージ側） / bottom=下ブロック / knob=ノブ（2個印刷）
// 使い方: part を切り替えて F6 → STL出力。寸法は下の変数で変更。

part = "assy";     // "assy"（組立確認用） / "top" / "bottom" / "knob"

// ---- 相手・穴 ----
pipe_d    = 32;    // パイプ径（組立確認の表示用。28でもSTLは同じ）
n_holes   = 2;     // 穴の数
pitch     = 120;   // 穴ピッチ（穴中心～穴中心）。添付ゲージの実測値
edge      = 20;    // ブロック端から最初の穴中心まで
drill_d   = 9;     // ドリル径（M8貫通ボルト用のきり穴）
use_bush  = true;  // true=ドリルブッシュを圧入 / false=樹脂の穴で直接案内
bush_hole = 15.0;  // ブッシュ圧入穴（ブッシュ外径に合わせる）
stop_dist = 0;     // パイプ端から1つ目の穴中心までの距離。0=端当てなし（edge以上で指定）
// ---- ブロック ----
width     = 80;    // 幅
h_top     = 28;    // 上ブロックの高さ
h_bot     = 26;    // 下ブロックの高さ
bolt_x    = 27;    // 中心から締付ボルトまで
v_w       = 28;    // V溝の幅
v_ang     = 120;   // V溝の開き角
relief_d  = 12;    // 下ブロックのドリル逃がし穴
// ---- M8ボルト・ナット ----
bolt_d    = 8.6;
nut_af    = 13.4;  // ナット二面幅 13 + すきま
nut_t     = 6.9;   // ナット厚み 6.5 + すきま
nut_z     = 8;     // 下ブロック外面からナット溝まで
// ---- ノブ ----
knob_d    = 30;
knob_h    = 12;
head_af   = 13.3;
head_h    = 6;
// ---- 合わせ線 ----
mark_w    = 0.8;
mark_d    = 0.6;

$fn = 72;

v_dep = (v_w/2) / tan(v_ang/2);                       // V溝の深さ
off   = (pipe_d/2) / sin(v_ang/2) - v_dep;            // パイプ中心からブロック合わせ面まで
guide = use_bush ? bush_hole : drill_d + 0.3;
len   = pitch * (n_holes - 1) + 2 * edge;             // パイプ方向の長さ
bolt_ys = len > 200 ? [edge, len - edge] : [len/2];   // 締付ボルトの位置（200超は2列）
function hole_y(i) = edge + i * pitch;

module v_cut(l) {
    linear_extrude(l, center = true)
        polygon([[0, 0], [v_w/2 + 1, (v_w/2 + 1) / tan(v_ang/2)],
                 [-v_w/2 - 1, (v_w/2 + 1) / tan(v_ang/2)]]);
}

module block(h) {                                     // 外面が下（z=0）、V溝が上
    difference() {
        translate([-width/2, 0, 0]) cube([width, len, h]);
        translate([0, len/2, h - v_dep]) rotate([90, 0, 0]) v_cut(len + 2);
        for (s = [-1, 1], y = bolt_ys) translate([s * bolt_x, y, -1]) cylinder(d = bolt_d, h = h + 2);
    }
}

module top() {
    difference() {
        union() {
            block(h_top);
            if (stop_dist > 0) {                      // パイプ端当て
                e = stop_dist - edge;
                translate([-15, -e - 5, 0]) cube([30, e + 5, 10]);
                translate([-15, -e - 5, 0]) cube([30, 5, h_top + off]);
            }
        }
        for (i = [0 : n_holes - 1]) {
            translate([0, hole_y(i), -1]) cylinder(d = guide, h = h_top + 2);
            // 合わせ線（各穴中心）: 外面・両側面
            translate([-width/2 - 1, hole_y(i) - mark_w/2, -0.01]) cube([width + 2, mark_w, mark_d]);
            for (s = [-1, 1]) translate([s > 0 ? width/2 - mark_d + 0.01 : -width/2 - 0.01,
                                         hole_y(i) - mark_w/2, -1]) cube([mark_d, mark_w, h_top + 2]);
        }
        translate([-mark_w/2, -0.01, -0.01]) cube([mark_w, len + 0.02, mark_d]);
        for (y = [-0.01, len - mark_d + 0.01]) translate([-mark_w/2, y, -1]) cube([mark_w, mark_d, h_top + 2]);
    }
}

module bottom() {
    difference() {
        block(h_bot);
        for (i = [0 : n_holes - 1]) translate([0, hole_y(i), -1]) cylinder(d = relief_d, h = h_bot + 2);
        for (s = [-1, 1], y = bolt_ys) {                           // ナット差し込み溝（側面から）
            x0 = bolt_x - nut_af/sqrt(3) - 0.3;
            translate([s > 0 ? x0 : -width/2 - 1, y - nut_af/2, nut_z])
                cube([width/2 + 1 - x0, nut_af, nut_t]);
        }
    }
}

module knob() {                                       // 六角穴が上
    difference() {
        cylinder(d = knob_d, h = knob_h);
        for (a = [0 : 60 : 300])
            rotate([0, 0, a + 30]) translate([knob_d/2 + 3, 0, -1]) cylinder(d = 11, h = knob_h + 2);
        translate([0, 0, -1]) cylinder(d = bolt_d, h = knob_h + 2);
        translate([0, 0, knob_h - head_h]) cylinder(d = head_af / cos(30), h = head_h + 1, $fn = 6);
    }
}

if (part == "top") top();
else if (part == "bottom") bottom();
else if (part == "knob") knob();
else {                                                // 組立状態（パイプ中心が原点）
    translate([0, 0, -off - h_bot]) bottom();
    translate([0, 0, off + h_top]) mirror([0, 0, 1]) top();
    for (s = [-1, 1], y = bolt_ys) translate([s * bolt_x, y, off + h_top]) knob();
    color("silver") translate([0, -40, 0]) rotate([-90, 0, 0])
        difference() { cylinder(d = pipe_d, h = len + 80); translate([0, 0, -1]) cylinder(d = pipe_d - 4, h = len + 82); }
}
