#!/bin/bash
set -e

BASE="/root/ultraiptv"
APP="$BASE/app"
HLS="$BASE/hls"
DB="$BASE/db"

echo "===== ULTRA IPTV CORE INSTALL ====="

apt update -y
apt install -y ffmpeg nginx python3 python3-pip sqlite3 curl

pip3 install flask psutil

# yt-dlp atualizado
curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp \
-o /usr/local/bin/yt-dlp
chmod +x /usr/local/bin/yt-dlp

mkdir -p "$APP" "$HLS" "$DB"

# ---------------- NGINX ----------------

cat > /etc/nginx/sites-enabled/default << EOF
server {
    listen 80;

    location /hls {
        root $BASE;
        add_header Cache-Control no-cache;
        types {
            application/vnd.apple.mpegurl m3u8;
            video/mp2t ts;
        }
    }

    location / {
        proxy_pass http://127.0.0.1:5000;
    }
}
EOF

systemctl restart nginx

# ---------------- DATABASE ----------------

sqlite3 "$DB/users.db" << SQL
CREATE TABLE IF NOT EXISTS users (
id INTEGER PRIMARY KEY,
username TEXT,
password TEXT
);
INSERT OR IGNORE INTO users VALUES (1,'admin','admin123');
SQL

# ---------------- SERVER ----------------

cat > "$APP/server.py" << 'PY'
from flask import Flask, request, redirect
import subprocess, os, psutil

BASE="/root/ultraiptv"
HLS=f"{BASE}/hls"

app=Flask(__name__)
streams={}

@app.route("/")
def panel():
    cpu=psutil.cpu_percent()
    ram=psutil.virtual_memory().percent

    html=f"""
    <h1>ULTRA IPTV CORE</h1>
    CPU:{cpu}% RAM:{ram}%<br>
    Streams:{list(streams.keys())}<br><br>

    <form action='/add'>
    Nome:<input name='name'>
    Link:<input name='link' size='60'>
    <button>Add</button>
    </form><br>

    <a href='/playlist'>Exportar Playlist</a>
    """

    return html

@app.route("/add")
def add():
    name=request.args.get("name")
    link=request.args.get("link")

    cmd=f"""
while true; do
URL=$(yt-dlp -f b -g "{link}")
ffmpeg -re -i "$URL" \
-c:v libx264 -preset veryfast -tune zerolatency \
-c:a aac -ar 44100 -ac 2 \
-f hls -hls_time 4 -hls_list_size 5 \
-hls_flags delete_segments \
{HLS}/{name}.m3u8
sleep 2
done
"""

    p=subprocess.Popen(cmd, shell=True, executable="/bin/bash")
    streams[name]=p.pid

    return redirect("/")

@app.route("/stop")
def stop():
    name=request.args.get("name")
    if name in streams:
        os.system(f"kill {streams[name]}")
        del streams[name]
    return redirect("/")

@app.route("/playlist")
def playlist():
    ip=os.popen("hostname -I | awk '{print $1}'").read().strip()

    out="#EXTM3U\n"
    for f in os.listdir(HLS):
        if f.endswith(".m3u8"):
            n=f.replace(".m3u8","")
            out+=f"#EXTINF:-1,{n}\nhttp://{ip}/hls/{f}\n"

    return out,200,{"Content-Type":"application/vnd.apple.mpegurl"}

app.run(host="0.0.0.0",port=5000)
PY

# ---------------- SYSTEMD ----------------

cat > /etc/systemd/system/ultraiptv.service << EOF
[Unit]
Description=Ultra IPTV Core
After=network.target

[Service]
ExecStart=python3 $APP/server.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ultraiptv
systemctl start ultraiptv

echo ""
echo "====================================="
echo " ULTRA IPTV CORE INSTALADO ✔"
echo "====================================="
echo "Painel: http://SEU_IP"
echo "Login: admin"
echo "Senha: admin123"
echo ""
