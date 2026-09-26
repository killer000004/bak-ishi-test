# Serverga o'rnatish (yangi VM + domen)

```
Internet ──► Cloudflare (DNS / Access) ──► pfSense WAN :443 ──► SafeLine WAF 10.166.115.10
                                                                     │  HTTPS tugaydi
                                                                     ▼
                                                  tg-manager VM 10.166.115.20:8000 (Web subnet)
                                                                     │
                                                                     ▼
                                                              Telegram (MTProto)
```

Quyidagi misollarda `10.166.115.20` va `tg.uzkip.com` ishlatilgan. O'zingizning IP va domeningizni qo'ying.

## ⚠️ Xavfsizlik

Bu panel internetdan ochiladi va Telegram akkauntingizni to'liq boshqaradi. Shuning uchun:
- **ADMIN_TOKEN** ni faqat parol menejerida saqlang. Uni chatga yoki email'ga yozmang.
- **8-qadam (Cloudflare Access)** ni o'tkazib yubormang. U tokendan oldin email orqali ikkinchi tekshiruv qo'shadi.
- **Backup:** Veeam VM'ni har kecha backup qiladi, backup ichida `.session` fayli ham bor. Backup'ga kirish huquqi ham akkauntingizga kirish huquqi degani.
- **Oldin yakunlash:** agar sizib chiqdi deb gumon qilsangiz, avval telefondan seansni yakunlang: `Settings > Devices > TG Manager > Terminate Session`. Keyin `.session` faylini o'chiring.

## 1. ESXi'da VM yaratish

1. ESXi Host Client (`https://10.166.134.254`) oching: **Virtual Machines > Create / Register VM**.
2. **Create a new virtual machine** ni tanlang:
   - Name: `tg-manager`
   - Guest OS family: `Linux`, Guest OS version: `Ubuntu Linux (64-bit)`
3. **Customize settings**:
   - CPU: `1`, Memory: `2 GB`, Hard disk: `20 GB` (Thin provisioned)
   - Network Adapter 1: pfSense `vmx1` (**Web**, 10.166.115.0/24) ga ulangan port group
   - CD/DVD: Ubuntu Server 24.04 ISO
4. Ubuntu o'rnatilayotganda:
   - Network: **Manual (static)**, Subnet `10.166.115.0/24`, Address `10.166.115.20`, Gateway `10.166.115.1`, Name servers `10.166.113.24`
   - **Install OpenSSH server** ni belgilang
   - IP bo'sh ekanini oldindan tekshiring: `ping 10.166.115.20` javob bermasligi kerak

VM WAF bilan bir subnet'da bo'lgani uchun pfSense'da yangi qoida kerak emas. Internetga chiqish (Telegram) Web interfeysidagi mavjud qoida orqali ishlaydi.

## 2. GitHub'dan olish (deploy key)

Repo private, shuning uchun serverga faqat o'qish huquqi bor kalit beriladi:

```bash
sudo ssh-keygen -t ed25519 -N "" -f /root/.ssh/id_ed25519 -C "tg-manager-vm"
sudo cat /root/.ssh/id_ed25519.pub
```

1. Chiqqan qatorni nusxalang.
2. GitHub'da repo'ni oching: **Settings > Deploy keys > Add deploy key**.
3. Title: `tg-manager-vm`, Key: nusxalangan qator. **Allow write access** belgilanmasin.
4. **Add key** tugmasini bosing, keyin serverda:

```bash
sudo git clone git@github.com:OWNER/REPO.git /opt/tg-manager
```

## 3. O'rnatish skripti

```bash
sudo bash /opt/tg-manager/deploy/install.sh
```

Skript `API_ID` va `API_HASH` ni so'raydi (https://my.telegram.org > **API development tools**). Keyin quyidagilarni qiladi:
- Python venv yaratadi va kutubxonalarni o'rnatadi.
- `backend/.env` faylini yaratadi. **ADMIN_TOKEN** ekranga chiqadi: uni darhol parol menejeriga saqlang.
- `tgmanager` tizim foydalanuvchisini va systemd servisini yaratadi.
- ufw'ni sozlaydi:
  - `8000` port: faqat WAF (`10.166.115.10`) dan.
  - `22` port: faqat VPN (`10.10.10.0/24`) dan va skriptni ishga tushirgan paytdagi IP'dan.

## 4. Telegram'ga login

```bash
sudo -u tgmanager /opt/tg-manager/venv/bin/python /opt/tg-manager/backend/login.py
```

Tartib bilan quyidagilarni kiritasiz:
1. Telefon raqam (`+998...`)
2. Telegram'ga kelgan kod
3. 2FA paroli (agar yoqilgan bo'lsa)

## 5. Servisni ishga tushirish

```bash
sudo systemctl start tg-manager
sudo journalctl -u tg-manager -n 20 --no-pager
```

Logda `Telegram'ga ulandi: ...` qatori chiqishi kerak. Lokal tekshiruv:

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8000/          # 200
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8000/api/me    # 401 (tokensiz)
```

## 6. SafeLine WAF

SafeLine web UI'ni oching (`https://10.166.115.10:9443`) va yangi sayt qo'shing:
- **Domain:** `tg.uzkip.com`
- **Port:** `443` (SSL yoqilgan) va `80`
- **Upstream:** `http://10.166.115.20:8000`
- **SSL sertifikat:** Let's Encrypt orqali oling yoki Cloudflare Origin sertifikatini yuklang.

Menyu nomlari SafeLine versiyasiga qarab biroz farq qilishi mumkin. Mavjud saytlaringiz (masalan `api.uzkip.com`) qanday sozlangan bo'lsa, xuddi shunday qo'shing.

## 7. Cloudflare DNS

Cloudflare'da quyidagi yozuvni qo'shing: **uzkip.com > DNS > Records > Add record**.
- Type: `A`, Name: `tg`, IPv4 address: `87.192.234.116` (pfSense WAN)
- Proxy status: **Proxied** (to'q sariq bulut). 8-qadam uchun shart.

## 8. Cloudflare Access (qattiq tavsiya etiladi)

Access yoqilgach, panel sahifasiga faqat siz ruxsat bergan email egasi yeta oladi. Kirishda email'ga bir martalik kod keladi, token esa undan keyin so'raladi.

1. **Zero Trust > Access > Applications > Add an application > Self-hosted** ni oching.
2. Application name: `TG Manager`, Application domain: `tg.uzkip.com`.
3. Policy qo'shing:
   - Action: `Allow`
   - Include > **Emails**: o'zingizning email manzilingiz
4. Login methods: **One-time PIN**. Keyin saqlang.

## 9. Panelga kirish

`https://tg.uzkip.com` ni oching. **Tizim Sozlamalari** sahifasida `Access token` ga ADMIN_TOKEN ni kiriting va **Saqlash va ulanish** tugmasini bosing.

## Yangilash

GitHub'ga yangi kod push qilingandan keyin:

```bash
sudo bash /opt/tg-manager/deploy/update.sh
```

## Muammolar

| Belgi | Tekshiring |
|---|---|
| `Telegram sessiyasi topilmadi` | 4-qadam bajarilmagan yoki login `sudo -u tgmanager` siz qilingan (fayl root'ga tegishli bo'lib qolgan) |
| `database is locked` | Login servis ishlab turgan paytda qilingan: `sudo systemctl stop tg-manager` qilib, login'ni qaytaring |
| Domen 502 qaytaradi | VM'da `sudo ufw status` ni tekshiring: 8000-port `10.166.115.10` ga ochiq bo'lishi kerak. WAF'dan `curl http://10.166.115.20:8000/` ham ishlashi kerak |
| `Juda ko'p noto'g'ri urinish` | 15 daqiqada 10 marta noto'g'ri token kiritilgan. 15 daqiqa kuting |
| Logda `Noto'g'ri token` ko'p | Kimdir token topishga urinmoqda: 8-qadamni yoqing |
| Logda hamma IP `10.166.115.10` | WAF `X-Forwarded-For` header'ini yubormayapti, uni SafeLine'da yoqing |
