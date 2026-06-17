# 6. alkalom — SQL + AI: lekérdezésírás, magyarázat, validálás

## Előfeltételek

- **ChatGPT / Claude / Copilot** — bármelyik
- **DBeaver Community** + **webshop.db** (SQLite) — lásd `telepitesi_utmutato.md`
- **Excel / Sheets** — B terv és validálás
- **Fájlok ebből a csomagból:**
  - `webshop.db` — SQLite adatbázis (orders: 50 sor, customers: 45 sor)
  - `orders_clean.csv` + `customers.csv` — B terv / Excel pálya
  - `sql_puskak.md` — 5 alap query minta referencia

---

## Rejtett tanulságok az adatban (oktatói infó — NE mutasd előre!)

| # | Mit fog felfedezni a SQL-lel | Tanulság |
|---|------------------------------|---------|
| 1 | LEFT JOIN → 2 order nem joinol (C999 orphan + NULL customer_id) | JOIN előtt mindig orphan check |
| 2 | COUNT before/after JOIN → 50 marad (nincs duplikáció, mert 1:N viszony, de a customer nem dupláz) | De ha 1:N lenne a másik irányból, duplikálna! |
| 3 | Revenue by segment → returning vs new, de kis minta | Ne általánosíts — a módszer a fontos |
| 4 | AI hajlamos MySQL/PostgreSQL szintaxist adni SQLite helyett | „SQLite-compatible" kérés fontossága |
| 5 | GROUP BY nélküli aggregáció → hibás eredmény | Az AI nem mindig írja oda a GROUP BY-t |

---

## Demó menetrendje (90 perc)

### 1. Nyitás (8 perc)

**Oktatói mondat:** _„AI írja gyorsan, mi ellenőrizzük gyorsan."_

Mondd: _„A pivot után a SQL az új szupererő. Nem kell fejlesztőnek lennetek — az AI megírja, ti megértitek és leellenőrzitek."_

**Cél:** 5 alap query minta + JOIN + orphan check + AI-val írt és validált lekérdezések.

---

### 2. Install / health check (12 perc)

Ha mindenki telepítette előre (lásd `telepitesi_utmutato.md`):

```sql
-- Teszt 1: fut-e?
SELECT 'Hello SQL!' AS greeting;

-- Teszt 2: van-e adat?
SELECT COUNT(*) AS orders_count FROM orders;
SELECT COUNT(*) AS customers_count FROM customers;

-- Teszt 3: lássuk az első 5 sort
SELECT * FROM orders LIMIT 5;
SELECT * FROM customers LIMIT 5;
```

**Ha install káosz van:** ne ragadj le! Demózd képernyőről, a résztvevők az AI chatbe írják a promptokat és az Excel pályán validálnak. _„A SQL-t 10 percben megtanuljátok otthon is — most a gondolkodás a fontos."_

---

### 3. Revenue szabály — közösen (10 perc)

Mielőtt bármit számolnánk, definiáljuk:

**AI prompt:**
```
Szerep: adatelemző.
Webshop rendelés adatunk van. Az orders tábla tartalmaz egy revenue oszlopot:
revenue = quantity × unit_price × (1 − discount)

Kérdések:
1. A returned soroknál (is_returned = 'yes') beleszámítsuk a revenue-t? Mi a pro/kontra?
2. A dq_flag-gel jelölt soroknál (orphan, missing_customer) beleszámítsuk? Mi a kockázat?
3. Adj 2 verziót: bruttó (mindent számol) és nettó (returned kihagyva) revenue SQL-ben.
4. Fontos: SQLite szintaxist használj!
```

**ELLENŐRZÉS — futtasd DBeaver-ben:**

```sql
-- Bruttó revenue (minden order)
SELECT SUM(revenue) AS brutto_revenue FROM orders;

-- Nettó revenue (returned nélkül)
SELECT SUM(revenue) AS netto_revenue FROM orders WHERE is_returned = 'no';

-- Különbség
SELECT 
    SUM(revenue) AS brutto,
    SUM(CASE WHEN is_returned = 'no' THEN revenue ELSE 0 END) AS netto,
    SUM(CASE WHEN is_returned = 'yes' THEN revenue ELSE 0 END) AS returned_revenue
FROM orders;
```

**Kérdezd a csoportot:** _„Nettó vs bruttó — melyiket használjuk a tréning során? Miért?"_

Döntés: a demó során **mindkettőt** mutatjuk, de a fő KPI a nettó revenue (returned nélkül).

**⚠️ Oktatói infó:** Az AI gyakran elfelejti a `WHERE is_returned = 'no'` szűrést, hacsak nem mondod kifejezetten. Ez egy jó „trust but verify" pillanat.

---

### 4. Alap query minták — 5 minta (15 perc)

Minden mintánál a workflow: **PROMPT → AI OUTPUT → FUTTATÁS → ELLENŐRZÉS**

#### Minta 1: SELECT + WHERE — Szűrés

**Üzleti kérdés:** _„Mely rendelések jöttek web csatornáról és 50 Ft feletti revenue-val?"_

**AI prompt:**
```
Írj SQLite query-t: az orders táblából azok a rendelések, ahol a channel = 'web' ÉS a revenue > 50.
Oszlopok: order_id, order_date, product_name, revenue.
Rendezd csökkenő revenue szerint.
```

**ELLENŐRZÉS — futtasd:**
```sql
SELECT order_id, order_date, product_name, revenue
FROM orders
WHERE channel = 'web' AND revenue > 50
ORDER BY revenue DESC;
```

Pivot-ellenőrzés: Excelben szűrd a web channel-t és revenue > 50 → ugyanannyi sor?

#### Minta 2: GROUP BY + SUM — Összesítés

**Üzleti kérdés:** _„Mennyi az összes revenue channel-enként?"_

**AI prompt:**
```
SQLite query: orders táblából channel-enkénti revenue összeg, rendelésszám, és átlag revenue.
Rendezd csökkenő revenue összeg szerint.
```

**ELLENŐRZÉS:**
```sql
SELECT 
    channel,
    COUNT(*) AS orders_count,
    ROUND(SUM(revenue), 2) AS total_revenue,
    ROUND(AVG(revenue), 2) AS avg_revenue
FROM orders
GROUP BY channel
ORDER BY total_revenue DESC;
```

Hasonlítsd a 5. alkalom pivot eredményéhez — stimmel?

#### Minta 3: GROUP BY + HAVING — Szűrt összesítés

**Üzleti kérdés:** _„Melyik category-ból jött 500 Ft-nál több revenue?"_

**AI prompt:**
```
SQLite query: category-nkénti revenue összeg, de csak azokat mutasd, ahol az összeg > 500.
```

**ELLENŐRZÉS:**
```sql
SELECT 
    category,
    ROUND(SUM(revenue), 2) AS total_revenue
FROM orders
GROUP BY category
HAVING total_revenue > 500
ORDER BY total_revenue DESC;
```

#### Minta 4: Több szint — Channel × Category

**Üzleti kérdés:** _„Melyik channel–category kombinációnál a legmagasabb a revenue?"_

**AI prompt:**
```
SQLite query: channel és category kombinációnkénti revenue összeg, rendelésszám.
Rendezd csökkenő revenue szerint. Top 5 elég.
```

**ELLENŐRZÉS:**
```sql
SELECT 
    channel,
    category,
    COUNT(*) AS orders_count,
    ROUND(SUM(revenue), 2) AS total_revenue
FROM orders
GROUP BY channel, category
ORDER BY total_revenue DESC
LIMIT 5;
```

#### Minta 5: CASE WHEN — Returned kezelés

**Üzleti kérdés:** _„Channel-enként hány returned van és mennyi a return rate?"_

**AI prompt:**
```
SQLite query: channel-enként az összes rendelés, a returned rendelések száma, és a return rate (%).
Kerekítsd 1 tizedesre.
```

**ELLENŐRZÉS:**
```sql
SELECT 
    channel,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN is_returned = 'yes' THEN 1 ELSE 0 END) AS returned_count,
    ROUND(100.0 * SUM(CASE WHEN is_returned = 'yes' THEN 1 ELSE 0 END) / COUNT(*), 1) AS return_rate_pct
FROM orders
GROUP BY channel
ORDER BY return_rate_pct DESC;
```

**Minden mintánál kérd 1 üzleti mondatban az eredményt:** _„Mit mond ez a szám? 1 mondat."_

---

### 5. JOIN + minőség: orphan check (15 perc)

Ez az alkalom legfontosabb „trust but verify" blokkja.

#### 5.1 COUNT before JOIN

**AI prompt:**
```
SQLite: számold meg az orders sorait JOIN előtt.
```

```sql
SELECT COUNT(*) AS orders_before_join FROM orders;
-- Várt: 50
```

#### 5.2 LEFT JOIN

**AI prompt:**
```
SQLite query: LEFT JOIN orders és customers tábla customer_id-vel.
Oszlopok: order_id, customer_id, customer_name, city, segment, channel, revenue.
```

**ELLENŐRZÉS:**
```sql
SELECT 
    o.order_id,
    o.customer_id,
    c.customer_name,
    c.city,
    c.segment,
    o.channel,
    o.revenue
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id;
```

#### 5.3 COUNT after JOIN

```sql
SELECT COUNT(*) AS orders_after_join
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id;
-- Várt: 50 (LEFT JOIN nem veszít sort)
```

**Kérdezd:** _„Miért 50 maradt? Mert LEFT JOIN-t használtunk. Mi lett volna INNER JOIN-nal?"_

```sql
SELECT COUNT(*) AS orders_inner_join
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id;
-- Várt: 48 (C999 orphan + NULL customer_id kiesik!)
```

**⚠️ Tanulság:** _„2 sort veszítettünk! Ha nem ellenőrizzük a COUNT-ot JOIN előtt és után, nem is vesszük észre."_

#### 5.4 Orphan check — ki hiányzik?

**AI prompt:**
```
SQLite query: mely orders soroknak NINCS match a customers táblában?
Mutasd az order_id-t, customer_id-t, és a revenue-t.
```

**ELLENŐRZÉS:**
```sql
SELECT o.order_id, o.customer_id, o.revenue, o.dq_flag
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;
```

Várt: order 1015 (C999 → orphan) és order 1045 (NULL → missing_customer).

**Kérdezd:** _„Mit csinálnátok ezekkel a sorokkal? Törölni? Megjegyezni? Vizsgálni?"_

#### 5.5 Revenue by segment (a JOIN gyümölcse)

**AI prompt:**
```
Most, hogy van LEFT JOIN-om az orders és customers között:
SQLite query: revenue összeg és átlag segment-enként (new vs returning).
Figyeld: a NULL segment sorokat külön mutasd.
```

**ELLENŐRZÉS:**
```sql
SELECT 
    COALESCE(c.segment, 'UNKNOWN') AS segment,
    COUNT(*) AS orders_count,
    ROUND(SUM(o.revenue), 2) AS total_revenue,
    ROUND(AVG(o.revenue), 2) AS avg_revenue
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.segment
ORDER BY total_revenue DESC;
```

**⚠️ Oktatói infó:** Az AI valószínűleg nem fogja a COALESCE-t használni → a NULL segment el fog tűnni. Ha nem teszi bele, kérdezd: _„Mi lett a 2 orphan sorral?"_

---

### 6. AI prompt: SQL + magyarázat + teszt (15 perc)

Most adjunk összetettebb feladatot az AI-nak, és nézzük meg, hogyan boldogul.

#### Összetett prompt:

```
Szerep: SQL tutor.
SQLite adatbázisom van, 2 tábla:
- orders (order_id, customer_id, order_date, channel, category, product_name, quantity, unit_price, discount, is_returned, payment_method, revenue, dq_flag)
- customers (customer_id, customer_name, city, signup_date, segment)

Feladat:
1. Írj egy query-t: top 5 város revenue alapján, de csak a nem-returned rendeléseket számold.
2. Magyarázd el a query-t soronként (magyarul).
3. Adj 1 validáló query-t, amivel ellenőrizhetem, hogy az eredmény helyes.
4. Mi a leggyakoribb hiba, amit ebben a query-ben elkövethetnék?

Fontos: SQLite szintaxist használj!
```

**ELLENŐRZÉS — futtasd az AI query-t:**

Várt helyes megoldás (hasonló):
```sql
SELECT 
    c.city,
    COUNT(*) AS orders_count,
    ROUND(SUM(o.revenue), 2) AS total_revenue
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
WHERE o.is_returned = 'no'
GROUP BY c.city
ORDER BY total_revenue DESC
LIMIT 5;
```

**⚠️ Oktatói infó — gyakori AI hibák:**
1. MySQL szintaxis (`LIMIT 5` rendben, de `TOP 5` nem SQLite!)
2. Elfelejti a `WHERE is_returned = 'no'` szűrést
3. Nem jelzi, hogy INNER JOIN kiszórja az orphan sorokat
4. Ha `DATE()` vagy `YEAR()` függvényt használ, az SQLite-ban más!

**Ha az AI hibázik:** _„Látjátok? Pont ezért futtatjuk le és ellenőrizzük. Az AI megírja 5 másodperc alatt, mi validálunk 30 másodperc alatt — együtt gyorsabbak vagyunk, mint bármelyik egyedül."_

#### Rossz dialektus javítás — iteráció:

Ha az AI MySQL-t ad:
```
A query-d MySQL szintaxist használ. Írd át SQLite-kompatibilisre.
Konkrétan: ne használj DATE_FORMAT-ot, YEAR()-t, vagy LIMIT/OFFSET-et MySQL módra.
SQLite-ban: strftime('%Y', order_date) a dátum évéhez.
```

---

### 7. Zárás + házi feladat (10 perc)

**Oktatói összefoglalás:**

_„Ma 3 dolgot tanultunk:"_
1. _„Az AI 5 másodperc alatt ír SQL-t — de a dialektus, a JOIN típus és a szűrések ellenőrzése rajtunk áll."_
2. _„COUNT before/after JOIN — a legfontosabb 10 másodperces ellenőrzés."_
3. _„Ha az AI rossz SQL dialektust ad: ne javítsd kézzel, hanem mondd meg az AI-nak, hogy SQLite-ot akarsz."_

**Két pálya a házihoz:**
- **A pálya (SQL):** 5 query DBeaver-ben + validálás
- **B pálya (Excel):** 5 pivot + insight — az eredmény számít, nem az eszköz

_„Tool hiba ≠ bukás. A módszer a lényeg."_

**Házi feladat:** lásd `hazi_feladat.md`

---

## Jó prompt vs rossz prompt — SQL kontextus

### ❌ ROSSZ:
```
Írj egy SQL query-t a revenue-hoz.
```
→ Melyik tábla? Melyik adatbázis? Milyen szűrés? Milyen dialektus?

### ✅ JÓ:
```
SQLite query az orders táblából: channel-enkénti revenue összeg és átlag, csak a nem-returned sorokra. Rendezd csökkenő összeg szerint.
```

### ❌ ROSSZ:
```
JOIN-old össze a két táblát.
```
→ Melyik JOIN típus? Melyik kulccsal? Mi legyen az output?

### ✅ JÓ:
```
SQLite: LEFT JOIN orders és customers customer_id-vel. Mutasd azokat a sorokat, ahol nincs match (orphan check). Oszlopok: order_id, customer_id, revenue.
```

### ❌ ROSSZ:
```
Magyarázd el ezt a query-t.
```
→ Milyen szinten? Fejlesztőnek? Kezdőnek? Mit emeljek ki?

### ✅ JÓ:
```
Magyarázd el ezt a query-t soronként, magyarul, Excel-analógiákkal. A célközönség: üzleti elemző, aki pivot táblát ért, de SQL-t most tanul.
[query ide]
```
