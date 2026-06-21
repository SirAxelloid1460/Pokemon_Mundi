# Pokémon Mundi — Sistema de Tiers y Stats Acumulativos

> Documento de handoff para Claude Code. Reconstruido desde las sesiones de diseño y simulación (Abril 2026). Acompaña al script `tier_simulation.py`, que reproduce todos los números de este documento.

---

## 1. Filosofía del sistema

Pokémon Mundi reemplaza el escalado lineal estándar por un **sistema acumulativo por fases**. La innovación central:

- Los stats **NO se recalculan** al evolucionar.
- Al evolucionar, **el nivel resetea pero todos los stats ganados se mantienen**: los stats del momento de evolución se convierten en la base del nuevo tier.
- Cada fase evolutiva (Tier) tiene su propio **cap de nivel** y su propio **multiplicador de ganancia de stats**.

Esto significa que la **historia evolutiva importa**: cuándo evolucionas afecta el resultado final, algo que no existe en Pokémon original.

**Excepción única — T0:** los baby Pokémon NO resetean el nivel al evolucionar a T1.

---

## 2. Caps y multiplicadores por tier

| Tier   | Descripción            | Cap nivel | Mult. stats | Reset al evo | Notas |
|--------|------------------------|-----------|-------------|--------------|-------|
| T0     | Baby Pokémon           | 30        | ×1.0        | **NO**       | Única excepción: el nivel no resetea al evolucionar a T1 |
| T1     | Fase 1                 | 60        | ×1.0        | Sí           | — |
| T2     | Fase 2                 | 40        | ×1.5        | Sí           | T2 método final usa ×3.0 |
| T3     | Fase 3 (evo final)     | 30        | ×2.0        | —            | Fase final, sin más evolución |
| T1-NE  | Sin evolución          | 150       | variable    | —            | Cap extendido; mult. por tramo 1.75 / 1.50 / 1.25 |
| T4     | Legendarios            | 200       | variable    | —            | Mult. por tramo 2.0 / 1.75 / 1.5 / 1.25 |
| T5     | Míticos                | 250       | variable    | —            | Mult. por tramo 2.0 / 1.8 / 1.6 / 1.4 |

### Multiplicadores variables por tramo de nivel

**Sin evolución (T1-NE), cap 150:**
- nv 1–100 → ×1.75
- nv 101–200 → ×1.50
- nv 201+ → ×1.25

**Legendarios (T4), cap 200 — 4 tramos desde lv 1 / 101 / 201 / 301:**
- nv 1–100 → ×2.00
- nv 101–200 → ×1.75
- nv 201–300 → ×1.50
- nv 301+ → ×1.25

**Míticos (T5), cap 250 — 4 tramos:**
- nv 1–100 → ×2.00
- nv 101–200 → ×1.80
- nv 201–300 → ×1.60
- nv 301+ → ×1.40

---

## 3. Mecánica de stats acumulativos

Al evolucionar, el Pokémon pasa al siguiente tier **conservando todos sus stats actuales**. El nivel resetea a 1, pero desde el nivel 2 en adelante el nuevo Pokémon **suma deltas** usando sus propias bases multiplicadas por el multiplicador del tier.

El **delta** es la ganancia incremental de un stat al pasar de `lv-1` a `lv`, calculada con la fórmula estándar de Pokémon. La acumulación aplica `int(delta × mult)` por nivel.

### Equivalencias de nivel (ejemplo Bulbasaur→Ivysaur→Venusaur)

| Equivalencia                    | Significado |
|---------------------------------|-------------|
| Ivysaur nv1 = Bulbasaur nv60    | Al llegar a T2 conserva todos los stats de T1 al cap |
| Venusaur nv1 = Ivysaur nv40     | Al llegar a T3 conserva todos los stats de T2 al cap |
| Venusaur nv1 = stats acumulados de T1 + T2 | Las dos fases anteriores se sumaron a la base |

---

## 4. Fórmulas base (IV = 0)

```python
def calc_hp(base, iv, level):
    return int(((2*base + iv) * level) / 100) + level + 10

def calc_stat(base, iv, level):
    return int(int(((2*base + iv) * level) / 100) + 5)

def stats_at(bases, level, iv=0):
    hp, atk, df, spa, spd, spe = bases
    return [calc_hp(hp,iv,level), calc_stat(atk,iv,level),
            calc_stat(df,iv,level), calc_stat(spa,iv,level),
            calc_stat(spd,iv,level), calc_stat(spe,iv,level)]

def delta(bases, lv, iv=0):
    # ganancia incremental de stats al pasar de lv-1 a lv
    if lv <= 1:
        return [0]*6
    s1 = stats_at(bases, lv, iv)
    s0 = stats_at(bases, lv-1, iv)
    return [s1[i] - s0[i] for i in range(6)]
```

### Núcleo acumulativo

```python
def accumulate_chain(phases):
    # phases: lista de (bases, niveles_a_recorrer, mult_constante)
    # El primer nivel de la primera fase inicializa con stats_at(bases,1).
    # Al cambiar de fase NO se reinicia 'current' (stats acumulativos).
    current = [0]*6
    first = True
    for bases, levels, mult in phases:
        start = 1
        if first:
            current = list(stats_at(bases, 1))
            start = 2
            first = False
        for lv in range(start, levels+1):
            d = delta(bases, lv)
            current = [current[i] + int(d[i]*mult) for i in range(6)]
    return current
```

---

## 5. Caso especial: T2 método final

Los Pokémon que el jugador encuentra **ya en su fase 2** (Haunter, Kadabra, Machoke, Graveler, etc.) no tuvieron fase T1 que les aportara stats acumulados. Para compensarlo, su multiplicador en T2 es **×3.0** en lugar de ×1.5.

Aun así, siguen siendo el grupo más débil del sistema — algo intencional, ya que son atajos de captura.

---

## 6. Mecánica de nivel tras evolución (`Formulae.gd`)

La función `level_after_evolution` se diseñó con un **offset de transferencia = 100**, heredado de la versión con caps 300/200/100:

```python
def level_after_evolution(current_level, current_cap, transfer_offset=100):
    if current_level >= current_cap:
        return max(1, current_cap - transfer_offset - 1)
    return max(1, current_level - transfer_offset)
```

> Con los caps finales (60/40/30), el offset 100 siempre devuelve 1 → **reset total a lv1**. La fórmula se conserva por si se reescalan los caps en el futuro.

---

## 7. Escalado de nivel de encuentro (legendarios / míticos)

Los niveles de encuentro de los juegos originales (cap 100) se reescalan proporcionalmente al cap del tier:

```
lv_mundi = round(lv_orig / 100 × cap_tier)
```

Los míticos obtenidos como evento/regalo usan un **nivel narrativo** según el momento del juego en que se obtienen, no su nivel de regalo literal.

### T4 — Legendarios (cap 200)

| Pokémon | lv orig | lv Mundi | Momento | Ratio vs jugador |
|---|---|---|---|---|
| Raikou / Entei / Suicune | 41 | 82 | Mid game | 1.02–1.08× |
| Regirock / Regice / Registeel | 42 | 84 | Mid game | 1.11× |
| Latias / Latios | 43 | 86 | Mid game | 1.17× |
| Cobalion / Terrakion / Virizion | 49 | 98 | Late game | 0.89–0.91× |
| Kyogre / Groudon | 50 | 100 | Late game | 1.03× |
| Reshiram / Zekrom / Xerneas / Yveltal | 50 | 100 | Late game | 1.04× |
| Lugia / Ho-Oh | 51 | 102 | Late game | 1.06× |
| Solgaleo / Lunala | 55 | 110 | Late game | 1.14× |
| Uxie / Mesprit / Azelf | 57 | 114 | Late game | 1.03× |
| Dialga / Palkia | 58 | 116 | Late game | 1.21× |
| Articuno / Zapdos / Moltres | 59 | 118 | Late game | 1.06× |
| Giratina | 62 | 124 | Post game | 1.14× |
| Rayquaza | 65 | 130 | Post game | 1.20× |
| Zacian / Zamazenta | 70 | 140 | Post game | 1.27–1.36× |
| Koraidon / Miraidon | 72 | 144 | Post game | 1.30× |

### T5 — Míticos (cap 250)

| Pokémon | lv narrativo | lv Mundi | Momento | Ratio vs jugador |
|---|---|---|---|---|
| Victini | 20 | 50 | Early game | 1.88× |
| Celebi | 40 | 100 | Mid game | 1.35× |
| Mew / Jirachi / Shaymin / Meloetta / Diancie / Hoopa | 50 | 125 | Late game | 1.16× |
| Genesect / Darkrai / Deoxys / Marshadow / Volcanion | 55 | 138 | Late game | 1.28× |
| Zarude | 60 | 150 | Late game | 1.39× |
| Pecharunt | 70 | 175 | Post game | 1.42× |
| Arceus | 80 | 200 | Post game tardío | 1.93× |

Todos los legendarios y míticos quedan en un ratio **0.89×–1.93×** respecto al jugador en su momento de encuentro: enfrentables pero un desafío real en mid-late game.

---

## 8. Niveles de encuentro — Pokémon de método

Para Pokémon que evolucionan por método (intercambio, piedra, amistad) sin nivel fijo, el nivel de encuentro worst-case se basa en el promedio ponderado de los juegos principales donde aparecen.

| Pokémon | Nivel final |
|---|---|
| Abra | 13 |
| Gastly | 17 |
| Geodude | 11 |
| Eevee | 20 |
| Sneasel | 26 |
| Slowpoke | 17 |
| Magnemite | 17 |
| Rhyhorn | 21 |
| Sunkern | 7 |
| Duraludon | 42 |
| Lampent | 48 |

Pokémon huevo/regalo (Togepi, Pichu, Cleffa, Igglybuff, Riolu): nivel 1–4 (encuentro como huevo).

---

## 9. Resultados de la simulación (todos al cap máximo)

Configuración: `T0=30 | T1=60 ×1.0 | T2=40 ×1.5 | T3=30 ×2.0 | T2m=40 ×3.0 | NoEvo=150 | T4=200 | T5=250`

| Pokémon | Tier | Σ poder |
|---|---|---|
| Magikarp→Gyarados | T2 | 969 |
| Graveler | T2m | 1081 |
| Caterpie→Butterfree | T3 | 1095 |
| Kadabra | T2m | 1103 |
| Machoke | T2m | 1113 |
| Haunter | T2m | 1115 |
| Larvesta→Volcarona | T2 | 1173 |
| Sneasel→Weavile | T2 | 1208 |
| Togepi→Togekiss | T3 | 1573 |
| Gastly→Gengar | T3 | 1582 |
| Charmander→Charizard | T3 | 1614 |
| Squirtle→Blastoise | T3 | 1614 |
| Bulbasaur→Venusaur | T3 | 1615 |
| Dreepy→Dragapult | T3 | 1645 |
| Deino→Hydreigon | T3 | 1699 |
| Tauros | T1-NE | 2367 |
| Lapras | T1-NE | 2593 |
| Snorlax | T1-NE | 2630 |
| Articuno | T4 | 4466 |
| Kyogre / Groudon | T4 | 5183 |
| Giratina | T4 | 5262 |
| Mewtwo / Rayquaza | T4 | 5263 |
| Mew / Jirachi | T5 | 5572 |
| Arceus | T5 | 6672 |

### Rangos por tier

| Tier | Rango Σ |
|---|---|
| T2 método final | 1081 – 1115 |
| T2 | 969 – 1208 |
| T3 | 1095 – 1699 |
| T1 sin evo | 2367 – 2630 |
| T4 Legendario | 4466 – 5263 |
| T5 Mítico | 5572 – 6672 |

**Ratio global: 6.89×** (Arceus 6672 vs Magikarp→Gyarados 969).

---

## 10. Escenario worst-case (evolución a ¾ del cap)

Forzando la evolución al 75% del cap de cada tier (T1 nv45/60, T2 nv30/40, T3 al cap):

| Pokémon | Best | Worst | Pérdida |
|---|---|---|---|
| Bulbasaur→Venusaur | 1615 | 1384 | 14.3% |
| Charmander→Charizard | 1614 | 1384 | 14.3% |
| Squirtle→Blastoise | 1614 | 1383 | 14.3% |
| Caterpie→Butterfree | 1095 | 958 | 12.5% |
| Gastly→Gengar | 1582 | 1353 | 14.5% |
| Dreepy→Dragapult | 1645 | 1429 | 13.1% |
| Deino→Hydreigon | 1699 | 1469 | 13.5% |
| Togepi→Togekiss | 1573 | 1359 | 13.6% |

**Conclusión:** evolucionar tarde (¾ del cap) cuesta ~12–15% de poder frente al best case. Validado como aceptable — el costo de evolucionar temprano vs. tarde es moderado y no rompe el balance.

---

## 11. Notas de implementación para Claude Code

- **Campos pendientes en `PokemonModel.gd`:** añadir `level_cap` y `tier`.
- **`Formulae.gd` en disco es un stub** — la implementación completa (stats, daño, curvas XP, lógica de tier) vive en el historial; regenerar desde aquí.
- **El multiplicador se aplica al DELTA por nivel, no al total** — aplicarlo al total acumulado fue descartado porque distorsiona la progresión. Con `int()`, multiplicadores pequeños (×1.1) sobre deltas chicos se redondean a 0, por eso los multiplicadores de compensación se elevaron a rangos 1.75–3.0.
- **T0 nunca resetea el nivel al evolucionar** — caso especial obligatorio en la lógica de evolución.
- **`level_after_evolution` conserva el offset 100** aunque con los caps actuales siempre dé reset a 1; no eliminarlo.
- El script `tier_simulation.py` es la fuente de verdad ejecutable: cualquier cambio de cap o multiplicador debe re-validarse corriéndolo.
