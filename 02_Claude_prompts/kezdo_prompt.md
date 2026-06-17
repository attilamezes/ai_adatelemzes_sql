# Kezdő prompt — Webshop EDA elemzés

## Kontextus

Ez a prompt az AI-asszisztált SQL elemzési folyamat indítópontja.
Adatbázis: `webshop.db` (SQLite), két tábla: `orders` (50 sor), `customers` (45 sor).

---

## A prompt

```
Szerep: pénzügyi elemzőként és SQL tutor-ként dolgozol.
Adatbázis: SQLite — csak SQLite kompatibilis szintaxist használhatsz.
Táblázatok: orders, customers — a táblák tartalmát még nem ismerjük.

Feladat: olyan adatfeltáró lekérdezéseket kell készítened SQLite kompatibilis
parancsokkal ahol feltárjuk az elemzéshez szükséges elemeket. Annyi kérdést és
lekérdezést adj, amennyi teljes körben megválaszolja a lenti pontokat:

1. Táblaméret mind a két táblázatra — hány sorunk van
2. Mezők: milyen mezőink vannak, ezeknek mi a tartalmuk, milyen a táblázatok
   szerkezete, ezek közül melyik sorolható be az alábbi kategóriákba
3. Kapcsolatok: mely mezők kötik össze a két táblázatot, melyek a mezők egyedi
   azonosítói a táblázatoknak, hogyan illeszkednek a táblázatok egymáshoz.
   Vannak-e orphan elemeink az egyes táblákban?
4. Dimenziók: mely mezők tekinthetők dimenziónak és ezeknek milyen egyedi értékük
   van, melyek ezek az elemek, milyen a gyakoriságuk
5. Értékmezők: mely mezők tartalmaznak numerikus adatokat, meg kell ismernünk
   ezeknek a mezőknek egymáshoz történő kapcsolódását
   (unit price, darab, mely időszakra stb.)

Minden query után írj 1 magyarázó mondatot: hogy az adott lekérdezéssel mire
szeretnénk választ kapni és mire figyeljek.

Végén adj javaslatot egy report tervezethez ebben a formában:
- Javasolt elemzési dimenziók
- Javasolt KPI-ok és azok számítása
- Szükséges JOIN típus, hogy az orphan mezők is belekerüljenek a számításokba
- 3 kérdés amely az elemzést meg fogja válaszolni
```

---

## Megjegyzések a prompthoz

**Ami működik:**
- Van szerepkör (pénzügyi elemző + SQL tutor)
- Megadja az SQL dialektust (SQLite — kritikus!)
- Strukturált kérdéssor (1-5 pont)
- Meghatározza a végeredmény formátumát

**Amit mindig ellenőrizz az AI outputjában:**
- SQLite szintaxist használt-e? (ne legyen YEAR(), DATE_FORMAT(), TOP N)
- A revenue képletet ellenőrizte-e? (quantity × unit_price × (1 − discount))
- Jelölte-e az orphan sorokat?
- GROUP BY szerepel-e minden aggregációnál?
- 100.0 × van-e, nem 100 × (SQLite egész osztásnál 0-t ad!)

**Tipikus AI hibák ennél a promptnál:**
- MySQL/PostgreSQL szintaxis használata
- INNER JOIN orphan check nélkül
- Számtani átlagár súlyozott átlag helyett
- GROUP BY elhagyása aggregációnál
