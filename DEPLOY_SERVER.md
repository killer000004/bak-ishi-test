# Serverga joylash va rasman ishga tushirish

Yo'riqnoma ishxona infratuzilmasiga moslab yozilgan:

```
Internet ─► pfSense (87.192.234.116, 80/443 port forward) ─► SafeLine WAF 10.166.115.10 (HTTPS)
                                                               │  http :80
                                                               ▼
                                                 Yangi VM "malumotnoma" (Web VLAN)
                                                 nginx :80 ─► gunicorn 127.0.0.1:8001 ─► Django + SQLite
```

Natijada sayt `https://DOMEN` manzilida ishlaydi. Ma'lumotlar O'zbekistondagi o'z serveringizda saqlanadi
(shaxsga doir ma'lumotlarni mahalliylashtirish talabiga mos).

> Quyida `malumotnoma.uzkip.com` va `10.166.115.20` — **misol**. O'zingiz tanlagan domen va bo'sh IP'ni yozing.

---

## 0. Oldindan hal qilinadigan 2 narsa
1. **Domen nomi.** Masalan: `malumotnoma.uzkip.com` yoki universitet domenidagi subdomen.
2. **VM uchun bo'sh IP.** Tavsiya: **Web** VLAN (10.166.115.0/24). WAF ham shu tarmoqda turadi, shuning uchun pfSense'da yangi qoida ochish shart emas.
   IP bandligini tekshirish uchun pfSense'da **Diagnostics > ARP Table** ni oching yoki `ping 10.166.115.20` qilib ko'ring.

---

## 1. ESXi'da VM yaratish

**1.1. Ubuntu ISO yuklash** (agar datastore'da hali yo'q bo'lsa)
- Ubuntu Server 24.04 LTS ISO'sini yuklab oling: https://ubuntu.com/download/server
- ESXi web (`https://10.166.134.254`) → **Storage** → datastore (**Date**) → **Datastore browser** → **Upload** → ISO faylni tanlang.

**1.2. VM yaratish**
1. **Virtual Machines** → **Create / Register VM** → **Create a new virtual machine** → **Next**.
2. **Name:** `malumotnoma`, **Guest OS family:** Linux, **Guest OS version:** Ubuntu Linux (64-bit) → **Next**.
3. **Storage:** `Date` → **Next**.
4. **Customize settings:**
   | Sozlama | Qiymat |
   |---|---|
   | CPU | 2 |
   | Memory | 2 GB |
   | Hard disk 1 | 20 GB, **Thin provisioned** |
   | Network Adapter 1 | **Web** VLAN port group'i |
   | CD/DVD Drive 1 | **Datastore ISO file** → Ubuntu ISO, **Connect at power on** ✓ |
5. **Next** → **Finish** → VM'ni yoqing (**Power on**) → **Console**.

**1.3. Ubuntu o'rnatish (installer)**
- Til: English. **Network** qadamida `ens192` → **Edit IPv4** → **Manual**:
  | Maydon | Qiymat |
  |---|---|
  | Subnet | `10.166.115.0/24` |
  | Address | `10.166.115.20` |
  | Gateway | `10.166.115.1` |
  | Name servers | `10.166.113.24` |
- **Profile:** server nomi `malumotnoma`, foydalanuvchi (masalan `aduzkip`), kuchli parol.
- **SSH Setup:** **Install OpenSSH server** ✓.
- O'rnatish tugagach **Reboot Now**. Agar ISO "bosib qolsa", **Edit settings** orqali CD/DVD'ni uzing.

**1.4. Tekshirish** (VM konsolida yoki SSH orqali)
```bash
ping -c2 10.166.115.1      # gateway
ping -c2 google.com        # internet (apt va pip uchun kerak)
```
Internet ishlamasa: pfSense → **Firewall > Rules > WEB** da DNS (10.166.113.24:53) va Internet'ga ruxsat bor-yo'qligini tekshiring.

---

## 2. Loyihani serverga yuklash va o'rnatish

VPN'ga ulangan kompyuteringizdan (OpenVPN barcha subnetlarga ruxsat beradi):

```bash
scp malumotnoma.zip aduzkip@10.166.115.20:~
ssh aduzkip@10.166.115.20
```

Serverda:
```bash
sudo apt-get update && sudo apt-get install -y unzip
unzip malumotnoma.zip
cd malumotnoma
sudo bash deploy/install.sh
```

Skript beradigan savollar:
| Savol | Javob |
|---|---|
| Sayt domeni | `malumotnoma.uzkip.com` |
| Rejim | `proxy` (Enter) |
| WAF IP | `10.166.115.10` (Enter) |
| Ichki tarmoqlar | `10.166.0.0/16` (Enter) |
| Sayt nomi | masalan `Talabalar ma'lumotnomasi` |
| Tashkilot nomi | footerda ko'rinadigan nom |
| UFW firewall | `yes` (Enter) |
| Administrator (oxirida) | panel uchun login, email, **kuchli parol** |

Skript taxminan 2–3 daqiqada quyidagilarni avtomatik qiladi:
- Python muhitini tayyorlaydi;
- tasodifiy `SECRET_KEY` yaratadi (`/etc/malumotnoma/env`);
- bazani yaratadi (`/var/lib/malumotnoma/`);
- gunicorn systemd xizmatini sozlaydi (alohida cheklangan foydalanuvchi nomidan ishlaydi);
- nginx'ni sozlaydi: parol tanlash va spamga qarshi cheklov, xavfsizlik sarlavhalari;
- UFW yoqadi: 80-portga faqat WAF va ichki tarmoq kira oladi, SSH ochiq qoladi;
- har kuni 00:30 da baza zaxirasini oladi. Bu Veeam'dan (01:00) oldin, ya'ni Veeam ham yangi nusxani oladi.

Oxirida `✔ Sayt ishlayapti` yozuvi chiqishi kerak. Ichki tarmoqdan tekshirish: `http://10.166.115.20/` ochilsa — tayyor.

---

## 3. Cloudflare DNS
1. Cloudflare → `uzkip.com` → **DNS** → **Records** → **Add record**.
2. **Type:** `A`, **Name:** `malumotnoma`, **IPv4 address:** `87.192.234.116`.
3. **Proxy status:** `api.uzkip.com` qanday sozlangan bo'lsa, xuddi shunday qiling.
   > SafeLine sertifikatni Let's Encrypt orqali o'zi oladigan bo'lsa, sertifikat chiqquncha **DNS only** (kulrang bulut) qilib turing.
4. **Save**.

---

## 4. SafeLine WAF'da sayt qo'shish
`https://10.166.115.10:9443` ga kiring va **mavjud `api.uzkip.com` ilovasini namuna qilib** yangisini yarating:

1. **Applications** → **Add Application**.
2. **Domain:** `malumotnoma.uzkip.com`.
3. **Port:** `443` (**SSL** ✓) va `80`.
4. **Upstream:** `http://10.166.115.20:80`.
5. **SSL certificate:** bepul Let's Encrypt sertifikatini so'rang yoki mavjud wildcard sertifikatni (`*.uzkip.com`) tanlang.
6. HTTP → HTTPS yo'naltirishni yoqing.
7. **Submit**.

Tekshirish:
```bash
# serverda — haqiqiy foydalanuvchi IP'lari ko'rinishi kerak (WAF IP emas)
sudo tail -f /var/log/nginx/access.log
```
Brauzerda `https://malumotnoma.uzkip.com` ni oching.

> ⚠️ **WAF formani bloklab qo'yishi mumkin.** Talabalar `o'g'li`, `G'ozovot` kabi tutuq belgili matn yuboradi. Ba'zan WAF buni SQL injection deb o'ylaydi.
> Sinov paytida formani to'liq yuborib ko'ring. WAF bloklash sahifasi chiqsa, SafeLine'da shu ilova uchun **Detections/Attack logs** ni oching
> va `/toldirish/` yo'li uchun **whitelist rule** qo'shing.

---

## 5. Birinchi sozlash (panelda)
1. `https://malumotnoma.uzkip.com/panel/` → administrator logini bilan kiring.
2. **Fakultet va guruhlar** → fakultetlarni qo'shing, so'ng guruhlarni (har qatorga bitta).
3. Bosh sahifadan **o'zingiz bitta sinov ma'lumotnomasini to'ldiring** → panelda PDF'ni yuklab, tekshiring.
4. Sinov yozuvini oching → **O'chirish**.

---

## 6. Rasmiy ishga tushirishdan oldingi tekshiruv ro'yxati
- [ ] `https://` ochiladi, brauzerda qulf belgisi bor, `http://` o'zi `https://` ga o'tadi
- [ ] Telefondan to'liq to'ldirib, yuborib ko'rildi (WAF bloklamadi)
- [ ] Panelda PDF va ZIP yuklanadi
- [ ] Administrator paroli kuchli (kamida 12 belgi). Har bir xodimga **alohida** login berildi: `/admin/` → **Users** → **Add user** → **Staff status** ✓
- [ ] Zaxira ishlaydi: `sudo malumotnoma-backup` → `/var/backups/malumotnoma/` da fayl paydo bo'ladi
- [ ] Veeam: **malumotnoma** VM'i kechki backup job'ga qo'shildi
- [ ] (ixtiyoriy) Zabbix: **Web scenario** → `https://malumotnoma.uzkip.com/healthz`, **Required string:** `ok`
- [ ] Sinov yozuvlari o'chirildi
- [ ] Talabalarga havola tarqatildi: `https://malumotnoma.uzkip.com`

---

## 7. Kundalik boshqaruv

| Vazifa | Buyruq |
|---|---|
| Holat | `systemctl status malumotnoma` |
| Loglar (jonli) | `journalctl -u malumotnoma -f` |
| Qayta ishga tushirish | `sudo systemctl restart malumotnoma` |
| Yangi admin / xodim | `sudo malumotnoma-manage createsuperuser` |
| Qo'lda zaxira | `sudo malumotnoma-backup` |
| Sozlamalar (sayt nomi va h.k.) | `sudo nano /etc/malumotnoma/env` → `sudo systemctl restart malumotnoma` |

**Yangi versiya o'rnatish:**
```bash
scp malumotnoma.zip aduzkip@10.166.115.20:~
ssh aduzkip@10.166.115.20
rm -rf malumotnoma && unzip malumotnoma.zip && cd malumotnoma
sudo bash deploy/update.sh        # avval zaxira oladi, baza va sozlamalar saqlanadi
```

**Zaxiradan tiklash:**
```bash
sudo systemctl stop malumotnoma
ls /var/backups/malumotnoma/                                   # kerakli sanani tanlang
sudo sh -c 'gunzip -c /var/backups/malumotnoma/db-2026-10-04_0030.sqlite3.gz > /var/lib/malumotnoma/db.sqlite3'
sudo rm -f /var/lib/malumotnoma/db.sqlite3-wal /var/lib/malumotnoma/db.sqlite3-shm
sudo chown malumotnoma:malumotnoma /var/lib/malumotnoma/db.sqlite3
sudo systemctl start malumotnoma
```

---

## 8. Muammolar va yechimlar

| Belgi | Sababi | Yechim |
|---|---|---|
| **502 Bad Gateway** | gunicorn ishlamayapti | `journalctl -u malumotnoma -n 50` → xatoni o'qing, `sudo systemctl restart malumotnoma` |
| **400 Bad Request** | domen `ALLOWED_HOSTS` da yo'q | `/etc/malumotnoma/env` → `DJANGO_ALLOWED_HOSTS` ga domenni qo'shing → restart |
| **403 CSRF** (login yoki yuborishda) | domen `CSRF_TRUSTED_ORIGINS` da yo'q | `DJANGO_CSRF_TRUSTED_ORIGINS="https://domen"` → restart |
| **429 Too Many Requests** | bitta IP'dan juda ko'p login urinishi | 1 daqiqa kuting (parol tanlashdan himoya) |
| WAF'ning bloklash sahifasi | WAF qoidasi formani hujum deb o'yladi | 4-bo'limdagi whitelist |
| Sayt ichkaridan ochiladi, tashqaridan ochilmaydi | DNS / WAF / pfSense | `nslookup domen` → 87.192.234.116 chiqishi kerak; WAF upstream IP'sini tekshiring |
| WAF ishlaydi, lekin 502/timeout | VM boshqa VLAN'da, pfSense blokladi | **Firewall > Rules > WEB** → **Add**: TCP, source `10.166.115.10`, destination VM IP, port 80 |

---

## Xavfsizlik bo'yicha qisqacha
- Maxfiy kalit va sozlamalar `/etc/malumotnoma/env` da turadi (faqat root o'qiy oladi). Kod papkasida maxfiy narsa yo'q.
- Ilova alohida `malumotnoma` foydalanuvchisi nomidan ishlaydi. Faqat o'z bazasiga yoza oladi (systemd sandbox).
- Login urinishlari IP bo'yicha cheklangan: daqiqasiga 10 ta. Sahifalarni ochish cheklanmaydi, shuning uchun bitta IP ortidagi butun sinf bir vaqtda to'ldira oladi.
- PDF va talabalar ma'lumotlari faqat panelga kirgan xodimlarga ko'rinadi. Panel sahifalari qidiruv tizimlarida indekslanmaydi.
