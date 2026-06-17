# 6. alkalom — SQL + AI: lekérdezésírás, magyarázat, validálás

## Csomag tartalma

| Fájl | Típus | Leírás |
|------|-------|--------|
| `webshop.db` | SQLite adatbázis | orders (50 sor) + customers (45 sor) — DBeaver-rel nyitható |
| `orders_clean.csv` | Adatszett | B terv / Excel pálya |
| `customers.csv` | Adatszett | B terv / Excel pálya |
| `telepitesi_utmutato.md` | Setup guide | DBeaver + SQLite telepítés, táblaszerkezet, B terv |
| `demo_instrukciok.md` | Oktatói puska | Teljes 90 perces menetterv, 5 query minta, JOIN + orphan check |
| `sql_puskak.md` | Referencia | 5 alap query minta, Excel-analógiák, tipikus AI hibák, SQLite-specifikus szintaxis |

## Előfeltételek

- ChatGPT / Claude / Copilot (bármelyik)
- DBeaver Community + webshop.db VAGY Excel/Sheets (B terv)
- Telepítési útmutató: `telepitesi_utmutato.md`

## Rejtett tanulságok

1. LEFT JOIN → 2 order nem joinol (orphan C999 + NULL customer_id) → **COUNT before/after JOIN**
2. Az AI hajlamos MySQL szintaxist adni → **„SQLite-compatible" kérés**
3. INNER JOIN sorvesztés → ha nem ellenőrzöd, nem veszed észre
4. Revenue: bruttó vs nettó döntés → **returned sorok tudatos kezelése**
5. Returning vs new segment: kis minta → **ne általánosíts 50 sorból**

## Kapcsolat a többi alkalommal

- **Előzmény (5. alkalom):** EDA + insightok — pivot-ból most SQL-re váltunk
- **Következő (7. alkalom):** Dashboard — az SQL/pivot eredményeket vizualizáljuk
