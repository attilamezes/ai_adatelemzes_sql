# SQL puskák — 5 alap query minta

## Használat
Ez a referencia lap. Minden mintához van: minta query, üzleti kérdés, Excel-analógia, és tipikus AI hiba.

---

## 1. SELECT + WHERE — Szűrés

**Excel-analógia:** Szűrő (Filter) az oszlopokon

**Üzleti kérdés:** _Mely web channel rendelések hoztak 50-nél magasabb revenue-t?_

```sql
SELECT order_id, order_date, product_name, revenue
FROM orders
WHERE channel = 'web' AND revenue > 50
ORDER BY revenue DESC;
```

**Fontos:**
- Szöveges értéknél aposztrófok: `'web'` (nem idézőjel!)
- `AND` / `OR` kombinálható, zárójelezz ha kell
- `ORDER BY ... DESC` = csökkenő, `ASC` = növekvő (alapértelmezett)

**Tipikus AI hiba:** dupla idézőjelet használ (`"web"`) → SQLite-ban működik, de szokj rá az aposztróf ra.

---

## 2. GROUP BY + aggregáció — Összesítés

**Excel-analógia:** Pivot tábla (Rows = channel, Values = SUM/COUNT/AVG)

**Üzleti kérdés:** _Mennyi a revenue channel-enként?_

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

**Fontos:**
- `GROUP BY` nélkül az aggregáció az egész táblára fut (1 sor eredmény)
- Ami nem aggregáció, annak a `GROUP BY`-ban kell lennie
- `ROUND(érték, 2)` = 2 tizedesre kerekítés

**Tipikus AI hiba:** elfelejtett `GROUP BY` → hibás vagy meglepő eredmény.

---

## 3. HAVING — Szűrt összesítés

**Excel-analógia:** Pivot → Value Filter (pl. „csak ahol összeg > 500")

**Üzleti kérdés:** _Melyik category hozott 500-nál több revenue-t?_

```sql
SELECT 
    category,
    ROUND(SUM(revenue), 2) AS total_revenue
FROM orders
GROUP BY category
HAVING total_revenue > 500
ORDER BY total_revenue DESC;
```

**Fontos:**
- `WHERE` = soronként szűr (aggregáció ELŐTT)
- `HAVING` = csoportonként szűr (aggregáció UTÁN)
- Sorrend: `WHERE` → `GROUP BY` → `HAVING` → `ORDER BY`

**Tipikus AI hiba:** `WHERE SUM(revenue) > 500` — ez hibás! Aggregáció utáni szűrés = `HAVING`.

---

## 4. LEFT JOIN — Táblák összekapcsolása

**Excel-analógia:** VLOOKUP / Power Query Merge (Left Outer)

**Üzleti kérdés:** _Rendelések + ügyfél adatok együtt, orphan check-kel._

```sql
-- Alap JOIN
SELECT 
    o.order_id, o.customer_id, c.customer_name, c.city, c.segment,
    o.channel, o.revenue
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id;

-- Orphan check: ki nem joinolt?
SELECT o.order_id, o.customer_id, o.revenue
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;
```

**Fontos:**
- `LEFT JOIN` = minden bal oldali sor megmarad, akkor is ha nincs match
- `INNER JOIN` = csak a matchelő sorok maradnak (adatvesztés!)
- **Mindig COUNT before/after JOIN!**

**Tipikus AI hiba:** INNER JOIN-t használ anélkül, hogy jelezné a sorvesztést.

---

## 5. CASE WHEN — Feltételes logika

**Excel-analógia:** IF() / IFS() képlet

**Üzleti kérdés:** _Return rate channel-enként._

```sql
SELECT 
    channel,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN is_returned = 'yes' THEN 1 ELSE 0 END) AS returned_count,
    ROUND(
        100.0 * SUM(CASE WHEN is_returned = 'yes' THEN 1 ELSE 0 END) / COUNT(*), 
        1
    ) AS return_rate_pct
FROM orders
GROUP BY channel
ORDER BY return_rate_pct DESC;
```

**Fontos:**
- `CASE WHEN ... THEN ... ELSE ... END` = soronkénti feltétel
- `100.0 *` → kényszerít tizedes osztásra (SQLite egész számot ad egész/egész-re!)
- Kombinálható `SUM`, `AVG`, `COUNT`-al

**Tipikus AI hiba:** `100 *` egész számmal → a return rate 0 lesz (egész osztás).

---

## Bónusz: SQLite-specifikus dolgok

| Téma | SQLite | MySQL / PostgreSQL |
|------|--------|--------------------|
| Dátum év | `strftime('%Y', order_date)` | `YEAR(order_date)` |
| Dátum hónap | `strftime('%m', order_date)` | `MONTH(order_date)` |
| Top N | `LIMIT 5` | `LIMIT 5` (ugyanaz) |
| NULL kezelés | `COALESCE(x, 'default')` | `COALESCE(x, 'default')` (ugyanaz) |
| Típus cast | `CAST(x AS REAL)` | `CAST(x AS DECIMAL)` |
| String concat | `x || ' ' || y` | `CONCAT(x, ' ', y)` |

**Aranyszabály:** Ha az AI más dialektust ad, ne javítsd kézzel — mondd meg neki:
```
Írd át SQLite-kompatibilisre. Ne használj MySQL/PostgreSQL specifikus függvényeket.
```

---

## A legfontosabb 10 másodperc: COUNT before/after JOIN

```sql
-- MINDIG futtasd ezt JOIN előtt és után:
SELECT COUNT(*) FROM orders;                    -- 50
SELECT COUNT(*) FROM orders o LEFT JOIN customers c ON o.customer_id = c.customer_id;  -- 50
SELECT COUNT(*) FROM orders o INNER JOIN customers c ON o.customer_id = c.customer_id; -- 48!
```

_Ha a szám változik: tudd miért!_
