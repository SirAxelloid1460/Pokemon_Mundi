#!/usr/bin/env python3
# Rellena tier / level_cap / *_max / BaseStats en Pokemon.json replicando la
# simulación (TIER_SYSTEM.md + tier_simulation.py). Stats acumulativos por fases.
import json, time, urllib.request, sys

ENDPOINT = "https://beta.pokeapi.co/graphql/v1beta"
POKEMON_JSON = "/home/user/Pokemon_Mundi/Scripts/StaticData/Pokemon.json"

# ---------- Fórmulas base (IV=0), idénticas al sim ----------
def calc_hp(base, level):
    return int(((2*base) * level) / 100) + level + 10

def calc_stat(base, level):
    return int(int(((2*base) * level) / 100) + 5)

def stats_at(b, level):
    return [calc_hp(b[0], level), calc_stat(b[1], level), calc_stat(b[2], level),
            calc_stat(b[3], level), calc_stat(b[4], level), calc_stat(b[5], level)]

def delta(b, lv):
    if lv <= 1:
        return [0]*6
    s1 = stats_at(b, lv); s0 = stats_at(b, lv-1)
    return [s1[i]-s0[i] for i in range(6)]

# ---------- Caps / multiplicadores ----------
CAP = {"T0": 30, "T1": 60, "T2": 40, "T3": 30, "T1-NE": 150, "T4": 200, "T5": 250}
MULT = {"T0": 1.0, "T1": 1.0, "T2": 1.5, "T3": 2.0}

def mult_noevo(lv): return 1.75 if lv <= 100 else (1.50 if lv <= 200 else 1.25)
def mult_t4(lv): return 2.00 if lv <= 100 else (1.75 if lv <= 200 else (1.50 if lv <= 300 else 1.25))
def mult_t5(lv): return 2.00 if lv <= 100 else (1.80 if lv <= 200 else (1.60 if lv <= 300 else 1.40))

# ---------- Núcleo acumulativo (idéntico al sim) ----------
def accumulate_chain(phases):
    # phases: lista de (bases, cap, mult_constante)
    current = [0]*6; first = True
    for bases, levels, m in phases:
        start = 1
        if first:
            current = list(stats_at(bases, 1)); start = 2; first = False
        for lv in range(start, levels+1):
            d = delta(bases, lv)
            current = [current[i] + int(d[i]*m) for i in range(6)]
    return current

def accumulate_variable(bases, cap, mult_fn):
    current = list(stats_at(bases, 1))
    for lv in range(2, cap+1):
        d = delta(bases, lv)
        m = mult_fn(lv)
        current = [current[i] + int(d[i]*m) for i in range(6)]
    return current

# ---------- Descarga de stats base (forma por defecto) ----------
QUERY = """
query Q($limit:Int!, $offset:Int!) {
  pokemon_v2_pokemonspecies(limit:$limit, offset:$offset, order_by:{id:asc}) {
    id
    pokemon_v2_pokemons(where:{is_default:{_eq:true}}) {
      pokemon_v2_pokemonstats(order_by:{stat_id:asc}) { base_stat stat_id }
    }
  }
}
"""
def gql(limit, offset):
    body = json.dumps({"query": QUERY, "variables": {"limit": limit, "offset": offset}}).encode()
    req = urllib.request.Request(ENDPOINT, data=body, headers={
        "Content-Type": "application/json",
        "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) PokemonMundi-DataGen/1.0"})
    for a in range(5):
        try:
            with urllib.request.urlopen(req, timeout=90) as r:
                res = json.loads(r.read().decode())
            if "errors" in res: raise RuntimeError(res["errors"])
            return res["data"]["pokemon_v2_pokemonspecies"]
        except Exception:
            if a == 4: raise
            time.sleep(2*(a+1))

def fetch_bases():
    bases = {}
    off = 0
    while True:
        batch = gql(120, off)
        if not batch: break
        for s in batch:
            pk = s["pokemon_v2_pokemons"]
            if not pk: continue
            st = {x["stat_id"]: x["base_stat"] for x in pk[0]["pokemon_v2_pokemonstats"]}
            bases[s["id"]] = [st.get(i, 0) for i in (1,2,3,4,5,6)]  # hp,atk,def,spa,spd,spe
        off += 120
        if len(batch) < 120: break
        time.sleep(0.3)
    return bases

# ---------- Lógica de tier ----------
def nb_ancestors(data, sid):
    # ancestros NO-bebé (los bebés se ignoran), del más cercano al más lejano
    res = []; cur = data[str(sid)]["EvolveFrom"]; seen = set()
    while cur and str(cur) in data and cur not in seen:
        seen.add(cur)
        if not data[str(cur)].get("IsBaby"):
            res.append(cur)
        cur = data[str(cur)]["EvolveFrom"]
    return res

def assign(data, bases, sid):
    v = data[str(sid)]
    b = bases.get(sid)
    if b is None:
        return None
    if v.get("IsMythical"):
        return "T5", accumulate_variable(b, CAP["T5"], mult_t5)
    if v.get("IsLegendary"):
        return "T4", accumulate_variable(b, CAP["T4"], mult_t4)
    if v.get("IsBaby"):
        return "T0", accumulate_chain([(b, CAP["T0"], MULT["T0"])])
    pre = nb_ancestors(data, sid)
    depth = len(pre)
    has_post = len(v.get("EvolveTo", [])) > 0
    if depth == 0 and not has_post:
        return "T1-NE", accumulate_variable(b, CAP["T1-NE"], mult_noevo)
    tier = ["T1", "T2", "T3"][min(depth, 2)]
    # cadena de fases NO-bebé, del más viejo al actual; cada fase a su cap por posición
    chain = list(reversed(pre)) + [sid]
    phases = []
    for i, cid in enumerate(chain):
        t = ["T1", "T2", "T3"][min(i, 2)]
        cb = bases.get(cid)
        if cb is None:
            return None
        phases.append((cb, CAP[t], MULT[t]))
    return tier, accumulate_chain(phases)

# ---------- Validación contra el sim ----------
EXPECTED = {3:1615, 6:1614, 9:1614, 12:1095, 94:1582, 887:1645, 635:1699,
            130:969, 637:1173, 461:1208, 143:2630, 128:2367,
            131:2593, 144:4466, 150:5263, 384:5263, 382:5183, 383:5183,
            487:5262, 151:5572, 385:5572, 493:6672}

def main():
    sys.stderr.write("Descargando stats base...\n")
    bases = fetch_bases()
    sys.stderr.write("bases: %d\n" % len(bases))
    data = json.load(open(POKEMON_JSON, encoding="utf-8"))

    counts = {}
    for k in sorted(data, key=lambda x: int(x)):
        sid = int(k)
        r = assign(data, bases, sid)
        if r is None:
            sys.stderr.write("sin bases #%s %s\n" % (k, data[k]["Name"]))
            continue
        tier, mx = r
        v = data[k]
        v["Tier"] = tier
        v["LevelCap"] = CAP[tier]
        v["BaseStats"] = bases[sid]
        v["HP_max"], v["Attack_max"], v["Defense_max"] = mx[0], mx[1], mx[2]
        v["SpAttack_max"], v["SpDefense_max"], v["Speed_max"] = mx[3], mx[4], mx[5]
        counts[tier] = counts.get(tier, 0) + 1

    # validación
    sys.stderr.write("\n=== VALIDACIÓN vs simulación ===\n")
    ok = True
    for sid, exp in EXPECTED.items():
        v = data[str(sid)]
        got = v["HP_max"]+v["Attack_max"]+v["Defense_max"]+v["SpAttack_max"]+v["SpDefense_max"]+v["Speed_max"]
        flag = "OK" if got == exp else "DIFF"
        if got != exp: ok = False
        sys.stderr.write("  #%-4d %-14s tier %-5s Σ=%-5d esperado=%-5d %s\n" % (
            sid, v["Name"], v["Tier"], got, exp, flag))

    json.dump(data, open(POKEMON_JSON, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
    sys.stderr.write("\nPor tier: %s\n" % counts)
    sys.stderr.write("Validación %s\n" % ("OK ✅" if ok else "CON DIFERENCIAS ⚠️"))

if __name__ == "__main__":
    main()
