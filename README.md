# Ma'lumotnoma (obyektivka) platformasi — Django

Talabalar ma'lumotnomani onlayn to'ldiradi. Ma'muriyat esa uni rasmiy namunadagi PDF ko'rinishida yuklab oladi.

| Sahifa | Manzil | Kim uchun |
|---|---|---|
| Bosh sahifa | `/` | hamma |
| Ma'lumotnoma to'ldirish (savollar bittadan) | `/toldirish/` | talaba |
| Boshqaruv paneli | `/panel/` | ma'muriyat (staff) |
| Kengaytirilgan admin (Django) | `/admin/` | superuser |

## Imkoniyatlar
**Talaba:** fakultet → guruh tanlaydi va 19 ta savolga ketma-ket javob beradi. Oxirida javoblarini tekshirib, **Yuborish** ni bosadi.
Javoblar to'ldirish davomida brauzerda saqlanadi.

**Panel:**
- **Bosh sahifa:** jami / bugun / 7 kunlik soni, guruhlar bo'yicha diagramma, oxirgi yuborilganlar.
- **Talabalar:** F.I.Sh. yonida **PDF yuklab olish** va **Ko'rish** tugmalari. Familiya/ism bo'yicha qidiruv (so'zlar tartibi muhim emas), fakultet va guruh filtri.
  Filtrlangan natijani **ZIP** qilib yuklash mumkin: PDF'lar guruhlar bo'yicha papkalarga joylanadi.
- **Talaba sahifasi:** barcha javoblar, PDF / DOCX / Tahrirlash / O'chirish.
- **Fakultet va guruhlar:** qo'shish (bir nechta guruhni birdan) va o'chirish. Ichida ma'lumotnoma bor guruhni o'chirib bo'lmaydi.

PDF asl DOC namunasidagi ko'rinishda chiqadi (rasm joyi bo'sh 3x4 ramka), shrift Times New Roman o'lchamida.

## Lokal ishga tushirish (sinov)
```bash
python -m venv venv
source venv/bin/activate            # Windows: venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
```
`http://127.0.0.1:8000/` va `http://127.0.0.1:8000/panel/` ni oching.

## Internetga chiqarish
- **O'z serveringiz (rasmiy ishga tushirish, tavsiya etiladi):** `DEPLOY_SERVER.md`. Bitta buyruq bilan o'rnatiladi: `sudo bash deploy/install.sh`.
- **PythonAnywhere (faqat sinov uchun):** `DEPLOY_PYTHONANYWHERE.md`.

Sozlamalar `.env` faylidan o'qiladi (namuna: `.env.example`). `.env` bo'lmasa, sayt sinov rejimida (DEBUG) ishlaydi.
`DJANGO_DEBUG=0` qo'yilib, `DJANGO_SECRET_KEY` berilmasa, sayt ishga tushmaydi. Bu xavfsizlik uchun ataylab qilingan.

## Panelga yangi xodim qo'shish
`/admin/` → **Users** → **Add user** → login va parol → **Save** → **Staff status** ni belgilang → **Save**.
Bunday xodim `/panel/` ga kira oladi. `/admin/` ga esa faqat superuser kiradi.
