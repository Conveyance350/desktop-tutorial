# -*- coding: utf-8 -*-
"""残業管理アプリ 共有サーバー（Python標準ライブラリのみ・追加インストール不要）
共用PCで動かし、各端末は http://【このPCの名前かIP】:PORT/ で開く。
"""
import glob, json, os, shutil, socket, threading, time, uuid
from datetime import datetime
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

# ===== 設定 =====
PORT = 8010                     # 部署ごとに変える（例：8011）。出荷作業スケジュールと同じ番号は使わない
BOOK_DIR = ''                   # 記録表（.xlsb）のあるフォルダ。空欄＝このファイルと同じフォルダ。例：r'\\サーバー名\共有\残業'
BACKUP_KEEP = 60                # バックアップを残す日数

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(HERE, 'zangyo_data.json')
BKDIR = os.path.join(HERE, 'zangyo_backup')
LOCK = threading.Lock()
DEVS = {}                       # 端末ごとの最終同期（保存しない）


def now_ms():
    return int(time.time() * 1000)


def newer(a, b):
    return b is None or a[1] > b[1] or (a[1] == b[1] and str(a[2]) > str(b[2]))


def valid(a):
    return isinstance(a, list) and len(a) == 3 and isinstance(a[1], (int, float))


def load():
    if os.path.exists(DATA):
        with open(DATA, encoding='utf-8') as f:
            d = json.load(f)
        d.setdefault('r', {})
        return d
    d = {'id': uuid.uuid4().hex, 'rev': 0, 'e': {}, 'r': {}}
    # 初回だけ：前の版の「zangyo_～.json」（共有フォルダ方式の各端末データ）を取り込む
    n = 0
    for p in glob.glob(os.path.join(HERE, 'zangyo_*.json')):
        try:
            with open(p, encoding='utf-8') as f:
                j = json.load(f)
            for k, a in (j.get('e') or {}).items():
                if valid(a) and newer(a, d['e'].get(k)):
                    d['rev'] += 1
                    d['e'][k] = a
                    d['r'][k] = d['rev']
                    n += 1
        except Exception:
            pass
    if n:
        print('前の版のデータを取り込みました：%d件' % n)
    save(d)
    return d


def save(d):
    os.makedirs(BKDIR, exist_ok=True)
    bk = os.path.join(BKDIR, 'zangyo_data_%s.json' % datetime.now().strftime('%Y%m%d'))
    if os.path.exists(DATA) and not os.path.exists(bk):
        shutil.copy2(DATA, bk)          # その日の最初の保存前に1日1回バックアップ
        for old in sorted(glob.glob(os.path.join(BKDIR, 'zangyo_data_*.json')))[:-BACKUP_KEEP]:
            os.remove(old)
    tmp = DATA + '.tmp'
    with open(tmp, 'w', encoding='utf-8') as f:
        json.dump(d, f, ensure_ascii=False, separators=(',', ':'))
    for i in range(10):                 # ウイルス対策ソフト等で一瞬つかまれている時は少し待つ
        try:
            os.replace(tmp, DATA)
            return
        except PermissionError:
            time.sleep(0.2)
    raise RuntimeError('zangyo_data.json に保存できません')


D = load()


def app_file():
    L = [p for p in glob.glob(os.path.join(HERE, '残業管理アプリ*.html'))]
    return max(L, key=os.path.getmtime) if L else None


def book_dir():
    return BOOK_DIR or HERE


def books():
    out = []
    for p in glob.glob(os.path.join(book_dir(), '*')):
        n = os.path.basename(p)
        if os.path.isfile(p) and n.lower().endswith(('.xlsb', '.xlsx', '.xlsm')):
            out.append({'name': n, 't': int(os.path.getmtime(p) * 1000)})
    return out


class H(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def send(self, code, body, ctype='application/json; charset=utf-8'):
        if isinstance(body, (dict, list)):
            body = json.dumps(body, ensure_ascii=False).encode('utf-8')
        self.send_response(code)
        self.send_header('Content-Type', ctype)
        self.send_header('Content-Length', str(len(body)))
        self.send_header('Cache-Control', 'no-store')
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        u = urlparse(self.path)
        if u.path in ('/', '/index.html'):
            p = app_file()
            if not p:
                return self.send(404, '残業管理アプリ～.html が同じフォルダにありません'.encode('utf-8'), 'text/plain; charset=utf-8')
            with open(p, 'rb') as f:
                return self.send(200, f.read(), 'text/html; charset=utf-8')
        if u.path == '/api/books':
            return self.send(200, books())
        if u.path == '/api/book':
            name = (parse_qs(u.query).get('name') or [''])[0]
            if name not in [b['name'] for b in books()]:
                return self.send(404, {'err': 'not found'})
            with open(os.path.join(book_dir(), name), 'rb') as f:
                return self.send(200, f.read(), 'application/octet-stream')
        self.send(404, {'err': 'not found'})

    def do_POST(self):
        if urlparse(self.path).path != '/api/sync':
            return self.send(404, {'err': 'not found'})
        try:
            q = json.loads(self.rfile.read(int(self.headers.get('Content-Length', 0))).decode('utf-8'))
        except Exception:
            return self.send(400, {'err': 'bad request'})
        dev = str(q.get('dev', ''))
        off = now_ms() - int(q.get('now') or now_ms())    # 端末の時計のずれを直す
        since = int(q.get('since') or 0)
        with LOCK:
            ch = 0
            for k, a in (q.get('e') or {}).items():
                if not valid(a):
                    continue
                if a[2] == dev:
                    a = [a[0], a[1] + off, a[2]]
                if newer(a, D['e'].get(k)):
                    D['rev'] += 1
                    D['e'][k] = a
                    D['r'][k] = D['rev']
                    ch += 1
            if ch:
                save(D)
            DEVS[dev] = {'dev': dev, 'name': str(q.get('name', '')), 't': now_ms(), 'ip': self.client_address[0]}
            e = {k: D['e'][k] for k, r in D['r'].items() if r > since}
            res = {'id': D['id'], 'rev': D['rev'], 'e': e, 'devs': list(DEVS.values())}
        self.send(200, res)


def addrs():
    """この PC の IP アドレス（社内LAN 用）。通信に使う IP を先頭にする"""
    s = []
    try:
        u = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        u.connect(('10.255.255.255', 1))   # 実際には送信しない。使う IP を調べるだけ
        s.append(u.getsockname()[0])
        u.close()
    except Exception:
        pass
    try:
        s += socket.gethostbyname_ex(socket.gethostname())[2]
    except Exception:
        pass
    out = []
    for a in s:
        if not a.startswith(('127.', '169.254.')) and a not in out:
            out.append(a)
    return out


if __name__ == '__main__':
    print('残業管理サーバーを起動しました（この画面を閉じると止まります）')
    print('このPCで開く　：http://localhost:%d/' % PORT)
    A = addrs()
    if A:
        print('他の端末で開く：http://%s:%d/' % (A[0], PORT))
        for a in A[1:]:
            print('　（つながらない時）http://%s:%d/' % (a, PORT))
    else:
        print('他の端末で開く：IPアドレスが取れませんでした。コマンドプロンプトで ipconfig を実行し、IPv4 アドレスを確認してください')
    print('データ：%s（件数 %d）' % (DATA, len(D['e'])))
    ThreadingHTTPServer(('0.0.0.0', PORT), H).serve_forever()
