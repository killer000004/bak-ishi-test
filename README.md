# Windows va Linux Maktabi — serverga joylash

Trafik yo'li:

```
Brauzer → Cloudflare DNS → pfSense (WAN 87.192.234.116:443)
        → SafeLine WAF 10.166.115.10 (HTTPS shu yerda tugaydi)
        → Ubuntu server :80 (Nginx, statik sayt)
```

Quyida misol uchun domen `os.uzkip.com`, server `10.166.113.22` (Dashboard VM, Ubuntu 24.04). O'zingizga kerakli domen va serverni qo'ying.

## Papkadagi fayllar

| Fayl | Vazifasi |
|---|---|
| `index.html` | Saytning o'zi (bitta fayl) |
| `nginx-os-maktabi.conf` | Nginx server bloki (shablon) |
| `deploy.sh` | O'rnatish va yangilash skripti |

## 1. Fayllarni serverga yuborish

Kompyuteringizdan (VPN ulangan holda):

```bash
scp -r os-maktabi javohir@10.166.113.22:~/
```

## 2. Serverda o'rnatish

```bash
ssh javohir@10.166.113.22
cd ~/os-maktabi
sudo bash deploy.sh os.uzkip.com 10.166.115.10
```

Serverning o'zida tekshirish:

```bash
curl -I -H 'Host: os.uzkip.com' http://127.0.0.1/
# HTTP/1.1 200 OK kutiladi
```

## 3. pfSense: WAF dan serverga ruxsat

Interfeyslar orasida trafik bloklangan. Shuning uchun WAF serverning 80-portiga yetib borishi kerak.

1. `Firewall > Rules > WEB` bo'limini oching.
2. `dash.uzkip.com` uchun 10.166.113.22 ga qoida allaqachon bor bo'lsa va u 80-portni ham qamrasa, bu qadamni o'tkazib yuboring.
3. Yo'q bo'lsa `Add` tugmasini bosing (block qoidalaridan YUQORIDA bo'lsin). Qiymatlar:
   - Action: `Pass`
   - Protocol: `TCP`
   - Source: `Address or Alias`, qiymati `10.166.115.10`
   - Destination: `Address or Alias`, qiymati `10.166.113.22`
   - Destination Port Range: `HTTP (80)`
   - Description: `WAF -> os-maktabi`
4. `Save`, keyin `Apply Changes`.

WAF serverdan tekshirish:

```bash
curl -I -H 'Host: os.uzkip.com' http://10.166.113.22/
```

## 4. Cloudflare: DNS yozuvi

1. `DNS > Records > Add record` ni oching.
2. Qiymatlar:
   - Type: `A`
   - Name: `os`
   - IPv4 address: `87.192.234.116`
   - Proxy status: `dash.uzkip.com` dagi bilan bir xil qo'ying.
3. Agar Proxied (to'q sariq bulut) bo'lsa, `SSL/TLS > Overview` da `Full (strict)` tanlangan bo'lishi kerak. `Flexible` rejimi redirect loop beradi.

## 5. SafeLine WAF: yangi ilova

Eng oson yo'l: mavjud `dash.uzkip.com` ilovasining sozlamalarini ochib, xuddi shunday yangisini yarating.

1. Applications bo'limida `Add Application` ni bosing.
2. Qiymatlar:
   - Domain: `os.uzkip.com`
   - Port: `443` (SSL yoqilgan) va `80`
   - Certificate: mavjud `*.uzkip.com` sertifikati, yoki Let's Encrypt orqali yangisini oling.
   - Upstream: `http://10.166.113.22:80`
3. HTTP dan HTTPS ga redirect'ni yoqing.

## 6. Tashqaridan tekshirish

```bash
curl -I https://os.uzkip.com
```

Keyin saytni telefonda mobil internet orqali ochib ko'ring.

## Yangilash

`index.html` ni almashtirib, yana skriptni ishga tushirasiz:

```bash
sudo bash deploy.sh os.uzkip.com 10.166.115.10
```

Eski versiya avtomatik `/var/www/os-maktabi/.index.html.bak-<sana>` nomi bilan saqlanadi.

## Diqqat

- pfSense'da 80/443 ni bu serverga to'g'ridan-to'g'ri port forward qilmang. Hamma trafik WAF orqali o'tishi kerak.
- Dashboard VM'da RAM yuqori ishlatilmoqda. Statik sayt uchun Nginx atigi bir necha MB oladi, lekin `free -h` bilan kuzatib boring.
- O'quvchi progressi (tugatilgan darslar) har bir foydalanuvchining o'z brauzerida saqlanadi. Qurilmalar orasida sinxron bo'lmaydi.
- Loglar: `/var/log/nginx/os-maktabi.access.log` va `/var/log/nginx/os-maktabi.error.log`.
