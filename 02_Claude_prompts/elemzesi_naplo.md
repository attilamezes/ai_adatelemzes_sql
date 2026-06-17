# Elemzési napló — Webshop SQL EDA
**Dátum:** 2024-06
**Adatbázis:** webshop.db (SQLite) — orders: 50 sor, customers: 45 sor
**Eszköz:** DBeaver Community + Claude AI tutor

---

## 1. Adatfeltárás

### Táblaméret
- orders: **50 sor** ✅
- customers: **45 sor** ✅

### Adatminőségi megállapítások

| Ellenőrzés | Eredmény | Döntés |
|---|---|---|
| dq_flag | 48 NULL, 1 missing_customer, 1 orphan | Jelölve, bent marad |
| Revenue képlet | OK (csak kerekítési eltérés) | revenue oszlop megbízható |
| is_returned hatása | 6 visszaküldött rendelés | Nettó revenue-t használunk |
| Signup vs order dátum | Nincs hiba | OK |

---

## 2. JOIN döntés

| Teszt | Eredmény |
|---|---|
| LEFT JOIN sorok | 50 — nincs veszteség |
| INNER JOIN sorok | 48 — 2 orphan kiesik |
| Orphan sorok | order 1015 (C999) + order 1045 (NULL) |
| Customer rendelés nélkül | 0 |

**Döntés:** LEFT JOIN + `COALESCE(segment, 'UNKNOWN')` — az orphan sorok revenue-ja az árbevétel része, még ha az ügyfél nem azonosítható is.

---

## 3. KPI definíciók

| KPI | Számítás | Megjegyzés |
|---|---|---|
| Nettó revenue | SUM(revenue) WHERE is_returned = 'no' | Alap KPI |
| AOV | AVG(revenue) WHERE is_returned = 'no' | Számtani átlag rendelésszinten |
| Return rate | returned_db / összes_db × 100 | %-ban, 100.0× fontos! |
| Súlyozott átlagár | netto_revenue / teljesult_quantity | Pontosabb mint számtani átlag |
| Átlag discount | AVG(discount) | Minden sorra, returned-del együtt |

---

## 4. Channel elemzés (Q12)

| Channel | Orders | Return rate | Nettó revenue | AOV | Átlag discount |
|---|---|---|---|---|---|
| web | 23 | 4.3% | 949.15 | 43.14 | 3.3% |
| partner | 13 | 7.7% | 697.64 | 58.14 | 7.3% |
| marketplace | 14 | **28.6%** | 490.05 | 49.01 | 5.7% |

**Insight:** Marketplace return rate 3× magasabb a web-nél. Partner AOV a legmagasabb, de mennyiség korlátozott (hipotézis — nem igazolt az adatból).

---

## 5. Marketplace-Clothing anomália (Q13c–e)

- 4 rendelésből 3 visszaküldött
- Elvesztett revenue: **169.78 egység**
- A teljes nettó revenue **7.9%-a** — egyetlen channel-category kombinációból
- **Akció:** területi vezető bevonása az ok azonosításához
- **Nem látható veszteség:** elveszett potenciális rendelések — nem mérhető az adatból

---

## 6. Havi trend — kritikus megállapítás (Q15b)

| Hónap | Aktív napok | Orders | Nettó revenue | Napi átlag |
|---|---|---|---|---|
| 2024-01 | 27 | 31 | 1484.39 | 54.98 |
| 2024-02 | 19 | 19 | 652.45 | 34.34 |

- Abszolút visszaesés: **-831.94 egység (-56%)**
- Napi átlag visszaesés: **-38%** (időszak hosszával korrigálva)
- **Nem statisztikai artefaktum** — valódi visszaesés

---

## 7. Variance elemzés (Q15e, Q16a–c)

**Top vesztesek channel-category szinten:**

| Channel-Category | 2024-01 | 2024-02 | Variance |
|---|---|---|---|
| partner \| Clothing | 263.98 | 40.46 | -223.52 |
| web \| Electronics | 219.59 | 18.98 | -200.61 |
| web \| Home & Garden | 197.15 | 75.68 | -121.47 |
| marketplace \| Electronics | 184.48 | 82.77 | -101.71 |
| partner \| Electronics | 171.22 | 69.58 | -101.64 |

**Termékszinten:** 26 januári termék tűnt el februárra, helyettük nem jelent meg egyenértékű bevételi forrás.

**Következtetés:** Nem termékmix csere — kiesés. Operatív probléma valószínűsíthető, mert minden channel és category érintett.

---

## 8. Főbb hipotézisek

| # | Hipotézis | Bizonyosság | Következő lépés |
|---|---|---|---|
| 1 | Marketplace-Clothing visszáru rendeléskori hibából ered | Közepes | Területi vezető |
| 2 | Februári kiesés operatív probléma (nem értékesítési) | Közepes | Beszerzés + ops |
| 3 | Partner channel mennyisége nem növelhető | Alacsony | B2B adatok |
| 4 | UNKNOWN szegmens new customerekhez tartozik | Alacsony | CRM ellenőrzés |
| 5 | Home & Garden szezonális mélypontban van | Alacsony | Több időszak kell |

---

## 9. Ismert korlátok

- **50 sor** — statisztikailag nem reprezentatív, a módszer a fontos
- **2 hónap** — nem elégséges trendmegállapításhoz
- **Február csonka** (19 nap) — napi átlaggal kell korrigálni
- **UNKNOWN szegmens** — 2 orphan sor, ügyfél nem azonosítható
- **Árbevétel egysége ismeretlen** — feltételezhetően forint

---

## 10. Tanulságok az AI-asszisztált SQL elemzésről

1. **Dialektus mindig** — az AI hajlamos MySQL-t adni SQLite helyett; mindig add meg: "SQLite-compatible"
2. **COUNT before/after JOIN** — 10 másodperc, de kritikus; INNER JOIN észrevétlenül veszít sorokat
3. **Súlyozott átlagár** — számtani átlag félrevezető eltérő mennyiségeknél; használj netto_revenue / quantity-t
4. **100.0 × nem 100 ×** — SQLite egész osztásnál 0-t ad; mindig lebegőpontos szorzó kell
5. **NULLIF a nullával osztásnál** — ha nincs teljesült rendelés, a query hibát dob NULLIF nélkül
6. **Az AI ötletel, te ellenőrzöd** — minden számot validálj keresztszámmal vagy pivot-tal
