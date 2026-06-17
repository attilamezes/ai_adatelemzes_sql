# Telepítési útmutató — 6. alkalom: SQL + AI

## Szükséges eszközök

### 1. DBeaver Community (ingyenes)
- Letöltés: https://dbeaver.io/download/
- Windows / Mac / Linux — Community Edition
- Telepítés: next-next-finish

### 2. A `webshop.db` fájl (SQLite adatbázis)
- Ebben a csomagban megtalálod
- Mentsd egy könnyen elérhető mappába (pl. Asztal vagy Dokumentumok)

### 3. DBeaver beállítás (5 perc)

1. Nyisd meg a DBeaver-t
2. **Database** → **New Database Connection**
3. Válaszd: **SQLite**
4. **Path**: tallózd ki a `webshop.db` fájlt
5. **Test Connection** → ha kéri a driver letöltést, engedélyezd
6. **Finish**

### 4. Első teszt

Nyiss egy SQL Editor-t (jobb klikk a connection-ön → SQL Editor → New SQL Script), és futtasd:

```sql
SELECT COUNT(*) AS orders_count FROM orders;
SELECT COUNT(*) AS customers_count FROM customers;
```

Várt eredmény: 50 order, 45 customer.

---

## Táblaszerkezet

### orders tábla (50 sor)

| Oszlop | Típus | Leírás |
|--------|-------|--------|
| order_id | INTEGER | Rendelés azonosító (PK) |
| customer_id | TEXT | Ügyfél azonosító (FK → customers) |
| order_date | TEXT | Rendelés dátuma (YYYY-MM-DD) |
| channel | TEXT | Értékesítési csatorna (web, marketplace, partner) |
| category | TEXT | Termékkategória (Electronics, Clothing, Home & Garden) |
| product_name | TEXT | Terméknév |
| quantity | INTEGER | Mennyiség |
| unit_price | REAL | Egységár |
| discount | REAL | Kedvezmény (0–0.2) |
| is_returned | TEXT | Visszaküldve? (yes/no) |
| payment_method | TEXT | Fizetési mód |
| revenue | REAL | Bevétel = quantity × unit_price × (1 − discount) |
| dq_flag | TEXT | Adatminőségi jelölés (orphan / missing_customer / NULL) |

### customers tábla (45 sor)

| Oszlop | Típus | Leírás |
|--------|-------|--------|
| customer_id | TEXT | Ügyfél azonosító (PK) |
| customer_name | TEXT | Név |
| city | TEXT | Város |
| signup_date | TEXT | Regisztráció dátuma |
| segment | TEXT | Szegmens (new / returning) |

---

## B terv — ha a DBeaver / SQLite nem működik

- Használd az `orders_clean.csv` és `customers.csv` fájlokat Excelben
- A SQL query-ket az AI chatben írasd meg, és az eredményt pivottal / SUMIF-fel ellenőrizd
- A lényeg a gondolkodásmód (definíció → query → validálás), nem az eszköz
