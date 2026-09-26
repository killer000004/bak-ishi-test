#!/usr/bin/env bash
# Windows va Linux Maktabi — Ubuntu serverga o'rnatish / yangilash skripti
# Ishlatish:  sudo bash deploy.sh <domen> <WAF_IP>
# Misol:      sudo bash deploy.sh os.uzkip.com 10.166.115.10
set -euo pipefail

DOMAIN="${1:-}"
WAF_IP="${2:-}"
SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
WEB_ROOT="/var/www/os-maktabi"
SITE_FILE="/etc/nginx/sites-available/os-maktabi"

if [[ $EUID -ne 0 ]]; then echo "Xato: sudo bilan ishga tushiring."; exit 1; fi
if [[ -z "$DOMAIN" || -z "$WAF_IP" ]]; then
  echo "Ishlatish: sudo bash deploy.sh <domen> <WAF_IP>"; exit 1
fi
if [[ ! -f "$SRC_DIR/index.html" ]]; then echo "Xato: index.html topilmadi ($SRC_DIR)"; exit 1; fi

echo "==> 1/5 Nginx tekshirilmoqda"
if ! command -v nginx >/dev/null 2>&1; then
  apt-get update -y && apt-get install -y nginx
fi

echo "==> 2/5 Sayt fayllari: $WEB_ROOT"
mkdir -p "$WEB_ROOT"
if [[ -f "$WEB_ROOT/index.html" ]]; then
  cp "$WEB_ROOT/index.html" "$WEB_ROOT/.index.html.bak-$(date +%Y%m%d-%H%M%S)"
fi
install -m 644 "$SRC_DIR/index.html" "$WEB_ROOT/index.html"
chown -R root:www-data "$WEB_ROOT"
chmod 755 "$WEB_ROOT"

echo "==> 3/5 Nginx konfiguratsiyasi: $SITE_FILE"
sed -e "s/__DOMAIN__/$DOMAIN/g" -e "s/__WAF_IP__/$WAF_IP/g" \
    "$SRC_DIR/nginx-os-maktabi.conf" > "$SITE_FILE"
ln -sf "$SITE_FILE" /etc/nginx/sites-enabled/os-maktabi

echo "==> 4/5 Konfiguratsiya tekshiruvi (nginx -t)"
nginx -t

echo "==> 5/5 Nginx qayta yuklanmoqda"
systemctl reload nginx

echo
echo "Tayyor. Ichki tekshiruv:"
echo "  curl -I -H 'Host: $DOMAIN' http://127.0.0.1/"
