# PythonAnywhere'ga joylash (bepul) — qadam-baqadam

Natija: sayt `https://LOGIN.pythonanywhere.com` manzilida ishlaydi (HTTPS bepul).
Quyida `LOGIN` so'zini o'zingizning PythonAnywhere loginingiz bilan almashtiring.

---

## 1. Ro'yxatdan o'tish
1. https://www.pythonanywhere.com → **Pricing & signup** → **Create a Beginner account**.
2. **Username** tanlang. U sayt manzili bo'ladi: `username.pythonanywhere.com`. Masalan, `malumotnoma` → `malumotnoma.pythonanywhere.com`.
3. Emailni tasdiqlang.

## 2. Loyihani yuklash
1. Yuqori menyuda **Files** ni bosing.
2. **Upload a file** → `malumotnoma.zip` ni tanlang. Fayl `/home/LOGIN/` papkasiga tushadi.

## 3. Bash konsolda o'rnatish
**Consoles** → **Bash** ni bosing va buyruqlarni ketma-ket bajaring:

```bash
cd ~
unzip malumotnoma.zip
cd malumotnoma

# Virtual muhit (python versiyasi 4-qadamda tanlanadigan bilan BIR XIL bo'lsin)
python3.11 -m venv ~/.virtualenvs/malumotnoma
source ~/.virtualenvs/malumotnoma/bin/activate
pip install -r requirements.txt
```

> `python3.11` topilmasa, `ls /usr/bin/python3*` bilan mavjud versiyalarni ko'ring. 3.10 yoki undan yangisini tanlang.

### .env faylini sozlash
```bash
cp .env.example .env
python -c "import secrets; print(secrets.token_urlsafe(50))"   # chiqqan kalitni nusxalang
nano .env
```
`nano` ichida quyidagilarni o'zgartiring:
- `DJANGO_SECRET_KEY=` → hozir nusxalagan kalit
- `LOGIN` → o'z loginingiz (2 joyda)
- `SITE_TITLE=`, `ORG_NAME=` → sayt nomi va universitet nomi

Saqlash: **Ctrl+O** → **Enter** → chiqish **Ctrl+X**.

### Baza, admin va statik fayllar
```bash
python manage.py migrate
python manage.py createsuperuser      # panel uchun login va parol (kuchli parol qo'ying!)
python manage.py collectstatic --noinput
```

## 4. Web app yaratish
1. Yuqori menyuda **Web** → **Add a new web app** → **Next**.
2. **Manual configuration** ni tanlang (**"Django" emas!**).
3. 3-qadamdagi bilan bir xil Python versiyasini tanlang, masalan **Python 3.11** → **Next**.

## 5. Web app sozlamalari (o'sha **Web** sahifasida)
**Code** bo'limi:
- **Source code:** `/home/LOGIN/malumotnoma`
- **Working directory:** `/home/LOGIN/malumotnoma`

**Virtualenv** bo'limi:
- `/home/LOGIN/.virtualenvs/malumotnoma` ni yozing va ✓ ni bosing.

**WSGI configuration file** havolasini (`/var/www/LOGIN_pythonanywhere_com_wsgi.py`) bosing. Ichidagi **hamma narsani o'chirib**, quyidagini qo'ying:

```python
import os
import sys

path = "/home/LOGIN/malumotnoma"
if path not in sys.path:
    sys.path.insert(0, path)

os.environ["DJANGO_SETTINGS_MODULE"] = "config.settings"

from django.core.wsgi import get_wsgi_application
application = get_wsgi_application()
```
**Save** bosing va **Web** sahifasiga qayting.

**Static files** bo'limi → **Enter URL / Enter path**:
| URL | Directory |
|-----|-----------|
| `/static/` | `/home/LOGIN/malumotnoma/staticfiles` |

**Security** bo'limi → **Force HTTPS** → **Enabled**.

## 6. Ishga tushirish
1. Sahifa tepasidagi yashil **Reload LOGIN.pythonanywhere.com** tugmasini bosing.
2. Brauzerda `https://LOGIN.pythonanywhere.com` ni oching. Bosh sahifa chiqishi kerak.
3. `https://LOGIN.pythonanywhere.com/panel/` → 3-qadamda yaratgan login bilan kiring.
4. **Fakultet va guruhlar** bo'limida fakultet va guruhlarni qo'shing. Shundan keyin talabalarga havolani tarqating.

---

## Muhim eslatmalar
- ⚠️ **Bepul tarifda sayt 3 oydan keyin o'chadi.** Uni ushlab turish uchun **Web** sahifasida vaqti-vaqti bilan **Run until 3 months from today** tugmasini bosing. PythonAnywhere muddat tugashidan oldin email yuboradi.
- Bepul tarifda: 1 ta sayt, 512 MB joy, kunlik CPU limiti bor. Bir necha yuz talaba uchun yetadi.
- **Zaxira nusxa:** vaqti-vaqti bilan **Files** → `malumotnoma/db.sqlite3` → **Download**. Barcha ma'lumotlar shu faylda.
- **Xato chiqsa:** **Web** sahifasidagi **Log files** → **Error log** ni oching, oxirgi qatorlarga qarang.

## Kodni yangilash (keyinchalik yangi versiya chiqsa)
```bash
cd ~ && unzip -o malumotnoma.zip      # .env va db.sqlite3 zip ichida yo'q — ular saqlanib qoladi
cd malumotnoma && source ~/.virtualenvs/malumotnoma/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py collectstatic --noinput
```
Keyin **Web** → **Reload**.

## ⚠️ Shaxsiy ma'lumotlar qonunchiligi haqida
O'zbekiston qonunchiligiga ko'ra ("Shaxsga doir ma'lumotlar to'g'risida"gi Qonun, 27¹-modda) O'zbekiston fuqarolarining shaxsiy ma'lumotlari
**O'zbekiston hududidagi serverlarda** qayta ishlanishi va saqlanishi kerak. PythonAnywhere serverlari esa xorijda (AQSh/Yevropa).
Shuning uchun PythonAnywhere'ni **sinov va namoyish** uchun ishlating. Haqiqiy talabalar ma'lumotlarini yig'ishdan oldin
universitet/tashkilot serveriga yoki O'zbekistondagi hostingga ko'chiring. Loyiha istalgan Linux serverda xuddi shu qadamlar bilan ishlaydi.
