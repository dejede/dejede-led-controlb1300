#!/bin/sh

REPO="https://raw.githubusercontent.com/dejede/dejede-led-controlb1300/main"

echo "================================="
echo "  Dejede LED Control B1300"
echo "================================="

# 🔧 Create directories

mkdir -p /usr/lib/lua/luci/view/dejede
mkdir -p /usr/lib/lua/luci/controller/dejede

# 📥 Download files

echo "[+] Downloading files..."
wget -q --show-progress -O /usr/lib/lua/luci/view/dejede/control.htm $REPO/control.htm
wget -q --show-progress -O /usr/lib/lua/luci/controller/dejede/control.lua $REPO/control.lua

# ❌ Validasi

if [ ! -s /usr/lib/lua/luci/view/dejede/control.htm ]; then
echo "[ERROR] control.htm gagal download!"
exit 1
fi

# 🔧 Fix CRLF

sed -i 's/\r$//' /usr/lib/lua/luci/view/dejede/control.htm

# 🔄 Restart service

/etc/init.d/uhttpd restart
/etc/init.d/cron restart

# 🧹 Clear cache

rm -rf /tmp/luci-*

echo "================================="
echo "✅ INSTALL SUCCESS!"
echo "http://192.168.1.1/cgi-bin/luci/admin/system/control"
echo "================================="
