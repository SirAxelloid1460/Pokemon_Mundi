#!/usr/bin/env python3
"""
Pokemon Mundi - Simulacion del sistema de tiers acumulativos.
Reconstruido desde el historial de diseno (sesion Abril 2026).

Mecanica nucleo: STATS ACUMULATIVOS.
Al evolucionar, el nivel resetea pero los stats ganados se mantienen.
T0 es la unica excepcion (NO resetea el nivel al evolucionar).
"""

# ============================================================
#  FORMULAS BASE (formula estandar de stats de Pokemon, IV=0)
# ============================================================

def calc_hp(base, iv, level):
    return int(((2*base + iv) * level) / 100) + level + 10

def calc_stat(base, iv, level):
    return int(int(((2*base + iv) * level) / 100) + 5)

def stats_at(bases, level, iv=0):
    hp, atk, df, spa, spd, spe = bases
    return [calc_hp(hp, iv, level), calc_stat(atk, iv, level),
            calc_stat(df, iv, level), calc_stat(spa, iv, level),
            calc_stat(spd, iv, level), calc_stat(spe, iv, level)]

def delta(bases, lv, iv=0):
    """Ganancia incremental de stats al pasar de lv-1 a lv."""
    if lv <= 1:
        return [0]*6
    s1 = stats_at(bases, lv, iv)
    s0 = stats_at(bases, lv-1, iv)
    return [s1[i] - s0[i] for i in range(6)]

# ============================================================
#  CONFIGURACION DE TIERS (valores finales del diseno)
# ============================================================

CAP_T0    = 30    # baby - NO resetea al evolucionar
CAP_T1    = 60    # fase 1
CAP_T2    = 40    # fase 2
CAP_T3    = 30    # fase 3 (final)
CAP_NOEVO = 150   # sin evolucion (cap extendido)
CAP_T4    = 200   # legendarios
CAP_T5    = 250   # miticos

MULT_T1       = 1.0
MULT_T2       = 1.5
MULT_T3       = 2.0
MULT_T2_FINAL = 3.0   # T2 "metodo final" (Haunter, Kadabra, Graveler...)

# Multiplicadores por tramo para sin-evolucion (delta x mult, por nivel)
def mult_noevo(lv):
    if lv <= 100: return 1.75
    if lv <= 200: return 1.50
    return 1.25

# Legendarios T4: 4 tramos 2.0 / 1.75 / 1.5 / 1.25 desde lv 1/101/201/301
def mult_t4(lv):
    if lv <= 100: return 2.00
    if lv <= 200: return 1.75
    if lv <= 300: return 1.50
    return 1.25

# Miticos T5: 4 tramos 2.0 / 1.8 / 1.6 / 1.4
def mult_t5(lv):
    if lv <= 100: return 2.00
    if lv <= 200: return 1.80
    if lv <= 300: return 1.60
    return 1.40

# ============================================================
#  NUCLEO ACUMULATIVO
# ============================================================

def accumulate_chain(phases):
    """
    phases: lista de (bases, niveles_a_recorrer, mult_constante).
    El primer nivel de la PRIMera fase inicializa con stats_at(bases,1).
    Cada nivel siguiente suma int(delta * mult).
    Al cambiar de fase NO se reinicia 'current' (stats acumulativos).
    """
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

def accumulate_variable(bases, cap, mult_fn):
    """Acumula una sola fase con multiplicador variable por nivel (no-evo/T4/T5)."""
    current = list(stats_at(bases, 1))
    for lv in range(2, cap+1):
        d = delta(bases, lv)
        m = mult_fn(lv)
        current = [current[i] + int(d[i]*m) for i in range(6)]
    return current

def total(stats):
    return sum(stats)

# ============================================================
#  MECANICA DE NIVEL TRAS EVOLUCION (Formulae.gd)
#  offset de transferencia = 100  (de la version 300/200/100)
#  Para los caps finales 60/40/30, el reset es a lv1.
# ============================================================

def level_after_evolution(current_level, current_cap, transfer_offset=100):
    if current_level >= current_cap:
        return max(1, current_cap - transfer_offset - 1)
    return max(1, current_level - transfer_offset)

# Con caps 60/40/30 el offset 100 siempre da 1 -> reset total a lv1.
# (La formula se conserva por si se reescalan los caps.)

# ============================================================
#  ESCALADO DE NIVEL DE ENCUENTRO (legendarios/miticos)
# ============================================================

def lv_mundi(lv_orig, cap_tier):
    return round(lv_orig / 100 * cap_tier)

# ============================================================
#  DATOS DE PRUEBA
# ============================================================

# Cadenas evolutivas completas (T1 -> T2 -> T3)
chains = {
    'Bulbasaur->Venusaur':   ([45,49,49,65,65,45],[60,62,63,80,80,60],[80,82,83,100,100,80]),
    'Charmander->Charizard': ([39,52,43,60,50,65],[58,64,58,80,65,80],[78,84,78,109,85,100]),
    'Squirtle->Blastoise':   ([44,48,65,50,64,43],[59,63,80,65,80,58],[79,83,100,85,105,78]),
    'Caterpie->Butterfree':  ([45,30,35,20,20,45],[50,20,55,25,25,30],[60,45,50,90,80,70]),
    'Gastly->Gengar':        ([30,35,30,100,35,80],[45,50,45,115,55,95],[60,65,60,130,75,110]),
    'Dreepy->Dragapult':     ([28,60,30,40,30,82],[68,80,50,60,50,102],[88,120,75,100,75,142]),
    'Deino->Hydreigon':      ([52,65,50,45,50,38],[72,85,70,65,70,58],[92,105,90,125,90,98]),
    'Togepi->Togekiss':      ([35,20,65,40,65,20],[55,40,85,80,105,40],[85,50,95,120,115,80]),
}

# Cadenas de 2 fases (T1 -> T2 final)
chains_2 = {
    'Magikarp->Gyarados':   ([20,10,55,15,20,80],[95,125,79,60,100,81]),
    'Larvesta->Volcarona':  ([55,85,55,50,55,60],[85,60,65,135,105,100]),
    'Sneasel->Weavile':     ([55,95,55,35,75,115],[70,120,65,45,85,125]),
}

# T2 metodo final (encontrados ya en fase 2, sin T1) -> mult x3.0
t2_final = {
    'Haunter':  [45,50,45,115,55,95],
    'Kadabra':  [40,35,30,120,70,105],
    'Graveler': [55,95,115,45,45,35],
    'Machoke':  [80,100,70,50,60,45],
}

# Sin evolucion (cap 150, mult variable)
noevo = {
    'Lapras':  [130,85,80,85,95,60],
    'Tauros':  [75,100,95,40,70,110],
    'Snorlax': [160,110,65,65,110,30],
}

# Legendarios T4 (cap 200, mult_t4)
t4 = {
    'Articuno': [90,85,100,95,125,85],
    'Mewtwo':   [106,110,90,154,90,130],
    'Rayquaza': [105,150,90,150,90,95],
    'Kyogre':   [100,100,90,150,140,90],
    'Groudon':  [100,150,140,100,90,90],
    'Giratina': [150,100,120,100,120,90],
}

# Miticos T5 (cap 250, mult_t5)
t5 = {
    'Mew':     [100,100,100,100,100,100],
    'Arceus':  [120,120,120,120,120,120],
    'Jirachi': [100,100,100,100,100,100],
}

# ============================================================
#  EJECUCION: TODOS AL CAP MAXIMO DE SU TIER
# ============================================================

results = []

for name, (b1, b2, b3) in chains.items():
    s = accumulate_chain([(b1, CAP_T1, MULT_T1),
                          (b2, CAP_T2, MULT_T2),
                          (b3, CAP_T3, MULT_T3)])
    results.append((name, 'T3', total(s)))

for name, (b1, b2) in chains_2.items():
    s = accumulate_chain([(b1, CAP_T1, MULT_T1),
                          (b2, CAP_T2, MULT_T2)])
    results.append((name, 'T2', total(s)))

for name, b in t2_final.items():
    s = accumulate_chain([(b, CAP_T2, MULT_T2_FINAL)])
    results.append((name, 'T2m', total(s)))

for name, b in noevo.items():
    s = accumulate_variable(b, CAP_NOEVO, mult_noevo)
    results.append((name, 'T1-NE', total(s)))

for name, b in t4.items():
    s = accumulate_variable(b, CAP_T4, mult_t4)
    results.append((name, 'T4', total(s)))

for name, b in t5.items():
    s = accumulate_variable(b, CAP_T5, mult_t5)
    results.append((name, 'T5', total(s)))

results.sort(key=lambda r: r[2])

print("="*54)
print(" POKEMON MUNDI - PODER TOTAL AL CAP MAXIMO DE CADA TIER")
print("="*54)
print(f" T0=30 | T1=60 x1.0 | T2=40 x1.5 | T3=30 x2.0")
print(f" T2m=40 x3.0 | NoEvo=150 | T4=200 | T5=250")
print("-"*54)
print(f" {'Pokemon':28s} {'Tier':>5} {'Sigma':>7}")
print("-"*54)
for name, tier, val in results:
    print(f" {name:28s} {tier:>5} {val:>7}")

print("-"*54)
order = [('T2m','T2 metodo final'),('T2','T2'),('T3','T3'),
         ('T1-NE','T1 sin evo'),('T4','T4 Legendario'),('T5','T5 Mitico')]
print(" RANGOS POR TIER")
for tid, label in order:
    vals = [v for n,t,v in results if t == tid]
    if vals:
        print(f"  {label:20s} {min(vals):5d} - {max(vals):5d}")

allv = [v for _,_,v in results]
print("-"*54)
print(f" Ratio global: {max(allv)/min(allv):.2f}x")
print(f"   min = {min(allv)}  |  max = {max(allv)}")

# ============================================================
#  ESCENARIO WORST-CASE: evolucion a 3/4 del cap del tier
# ============================================================

def run_worst_case():
    WC_T1 = round(CAP_T1 * 0.75)   # 45
    WC_T2 = round(CAP_T2 * 0.75)   # 30
    WC_T3 = CAP_T3                 # fase final siempre al cap

    print()
    print("="*54)
    print(" WORST CASE - evolucion a 3/4 del cap de cada tier")
    print("="*54)
    print(f" T1 nv{WC_T1}/{CAP_T1} | T2 nv{WC_T2}/{CAP_T2} | T3 nv{WC_T3}/{CAP_T3}")
    print("-"*54)
    print(f" {'Pokemon':24s} {'best':>7} {'worst':>7} {'perdida':>9}")
    print("-"*54)
    for name, (b1, b2, b3) in chains.items():
        best = total(accumulate_chain([(b1,CAP_T1,MULT_T1),(b2,CAP_T2,MULT_T2),(b3,CAP_T3,MULT_T3)]))
        worst = total(accumulate_chain([(b1,WC_T1,MULT_T1),(b2,WC_T2,MULT_T2),(b3,WC_T3,MULT_T3)]))
        loss = (1 - worst/best) * 100
        print(f" {name:24s} {best:>7} {worst:>7} {loss:>8.1f}%")

run_worst_case()
