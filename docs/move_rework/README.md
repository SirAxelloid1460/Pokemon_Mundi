# Rework de movimientos — diseño (handoff)

Rebalanceo de movimientos de daño para Pokémon Mundi. Estado: **diseño en curso** (aún no
implementado en `Scripts/`/`data/`). Este directorio es el volcado de las decisiones tomadas.

## Archivos
- `normal_families.json` — las 13 familias normales (potencia, coste, usos).
- `multihit_family.json` — la familia Multi-hit y sus subfamilias por concepto.
- `removed_moves.json` — movimientos removidos del juego, pasivas, fusiones y efectos especiales.
- `moves_curated.json` — lista de moves resultante (773), generada desde PokeAPI y curada.

---

## Sistema de familias normales

Una **familia** agrupa movimientos del mismo concepto/tipo en progresión de potencia, igual que
una línea evolutiva aprende versiones más fuertes (Ascuas → Lanzallamas → Llamarada).

### Reglas
- **Pool de PP de familia**:
  - `pp_base` = PP base del movimiento raíz, redondeado al múltiplo de 4 más cercano.
  - `pp_max` = PP máximo del movimiento raíz (`base × 1.6`), naturalmente múltiplo de 4.
- **Coste** (consume del pool): familias de 3 → `1 / 2 / 4`; familias de 2 → `1 / 2` (tope débil)
  o `1 / 4` (tope fuerte). Excepción **Látigo Cepa**: `1 / 3`.
- **Potencia**: cada tier = `anterior × 2 + 10`.
- **Usos** = `pool / coste` (con `pp_base` y con `pp_max`).

### Las 13 familias
| Familia | Miembros (pot · coste) | pp_base/pp_max |
|---|---|---|
| Ascuas | Ascuas 40·1 / Lanzallamas 90·2 / Llamarada 190·4 | 24 / 40 |
| Absorber | Absorber 20·1 / Megaagotar 50·2 / Gigadrenado 110·4 | 24 / 40 |
| Impactrueno | Impactrueno 40·1 / Rayo 90·2 / Trueno 190·4 | 28 / 48 |
| Nieve Polvo | Nieve Polvo 40·1 / Rayo Hielo 90·2 / Ventisca 190·4 | 24 / 40 |
| Picotazo Veneno | P. Veneno 15·1 / Residuos 40·2 / Bomba Lodo 90·4 | 36 / 56 |
| Tornado | Tornado 40·1 / Aire Afilado 90·2 / Tajo Aéreo 190·4 | 36 / 56 |
| Lanzarrocas | Lanzarrocas 50·1 / Avalancha 110·2 / Roca Afilada 230·4 | 16 / 24 |
| Pistola Agua | Pistola Agua 40·1 / Hidrobomba 190·4 | 24 / 40 |
| Burbuja | Burbuja 40·1 / Rayo Burbuja 90·2 | 28 / 48 |
| Hoja Afilada | Hoja Afilada 55·1 / Hoja Aguda 120·2 | 24 / 40 |
| Confusión | Confusión 50·1 / Psicorrayo 110·2 | 24 / 40 |
| Picotazo | Picotazo 35·1 / Pico Taladro 80·2 | 36 / 56 |
| Látigo Cepa | Látigo Cepa 45·1 / Latigazo 150·3 | 24 / 42 |

> Nota: `Burbuja` y varios moves de Multi-hit fueron recortados en los juegos oficiales (Gen 8)
> pero se **conservan** aquí por decisión de diseño.

---

## Familia Multi-hit (sistema aparte)

Movimientos multi-golpe. Tienen dos dimensiones (potencia por golpe y nº de golpes), así que su
**coste/usos se rige por un sistema aparte, todavía por definir**. Subfamilias por concepto:

| Subfamilia | Miembros (pot · golpes) |
|---|---|
| Furia | Ataque Furia 15·(2-5) / Golpes Furia 25·(2-5) |
| Golpe de mano | Doble Bofetón 25·(2) / Puño Cometa 18·(2-5) / Empujón 15·(2-5) |
| Patada | Triple Patada 15·(3) / Doble Patada 30·(2) |
| Púas/Agujas | Clavo Cañón 20·(2-5) / Pin Misil 25·(2-5) / Doble Ataque 40·(2, env 15%/golpe) |
| Munición arrojada | Semilladora 25 / Pedrada 25 / Ráfaga Escamas 25 (todos 2-5) |
| Hielo punzante | Triple Axel 20·(3) / Carámbano 25·(2-5) |
| Hueso | Ataque Óseo 25·(2-5) / Huesomerang 50·(2) |
| Acero/Engranaje | Rueda Doble 50·(2) / Ferropuño Doble 60·(2) |
| Agua | Shuriken de Agua 20·(2-5) / Azote Torrencial 25·(3) |
| Standalone | Plumerazo · Ala Bis · Dracoflechas · Paliza |

### Pasiva del concepto
- **Trump Card** se elimina como move y pasa a ser pasiva de los Multi-hit: **+1 potencia por
  cada PP faltante**.

### Caso especial: Paliza (Beat Up)
- Potencia = `5 + ataque_base / 10`.
- Golpea de 1 a 6 veces: 1 por cada Pokémon del equipo aliado **no** debilitado/dormido/
  envenenado/paralizado/quemado/congelado, **excepto el propio usuario**.
- Requiere implementación a mano (no es potencia fija).

---

## Movimientos removidos (833 → 773)

Se quitaron **60 moves** que los juegos oficiales retiraron (criterio: lista de moves inusables
en Scarlet/Violet, Serebii) más algunos añadidos por decisión propia. Detalle en
`removed_moves.json`. Resumen:

- **54 removidos del todo** (Bide, Conversion/2, Embargo, Foresight, Pursuit, Return, Frustration,
  Sonic Boom, Dragon Rage, Submission, Magnitude, Mirror Move, Sky Drop, Bombardeo, Golpe Bis…).
- **5 → pasivas** (removidos como move; pendiente implementar como pasiva):
  - Camouflage → pasiva tipo Bicho
  - Captivate → pasiva de ciertos Pokémon (p.ej. Skitty)
  - Power-Up Punch → pasiva tipo Lucha
  - Grudge → pasiva tipo Fantasma (con rebalanceo)
  - Trump Card → pasiva Multi-hit (ver arriba)
- **1 fusión**: Secret Power + Nature Power → uno solo (superviviente: Nature Power; efecto
  fusionado **pendiente**).

### Conservados con efecto cambiado
- **Natural Gift**: se queda; +efecto: si el usuario ingiere la baya que llevaba, el cambio de
  tipo del ataque persiste hasta fin de combate o hasta ser debilitado.
- **Doble Bofetón**: se queda en Multi-hit, cambiado a 2 golpes fijos + potencia 25.

### Firmas de legendarios conservadas
Geocontrol, Ala Mortífera, Mil Flechas, Mil Temblores, Fuerza Telúrica, Luz Aniquiladora, Tecno
Shock, Bomba Ígnea — inusables en SV solo porque su Pokémon no salió, pero sí están en la dex de 1025.

---

## Pendientes
1. Definir el sistema de coste/usos de la familia **Multi-hit**.
2. Definir el efecto fusionado de **Secret + Nature Power**.
3. Implementar las 5 pasivas (Camouflage, Captivate, Power-Up Punch, Grudge, Trump Card).
4. Implementar **Paliza** y **Natural Gift** (efectos a mano).
5. Volcar todo esto a `data/`/`Scripts/` (expandir `Moves.json`, migrar `Move.gd`).
