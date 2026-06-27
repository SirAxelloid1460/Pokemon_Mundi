# Pokémon Mundi — Resumen del proyecto (handoff para Claude Code)

RPG fan-made tipo Pokémon con elementos de Ranger. Motor **Godot 4 / GDScript**. Desarrollador único (Axel).

## Flujo de trabajo Git (preferencia del usuario)
**No crear pull requests.** Commit y push **directos a `main`** de una sola vez. Confirmado por Axel (proyecto de un solo desarrollador).


## Estructura del repo real (Godot)
```
res://Scripts/      # todos los .gd
res://Scenes/       # .tscn (PascalCase)
res://Assets/       # Sprites, Fonts, SFX, Graphic
res://data/         # JSON (moves, pokeballs, encounter levels)
res://translates/   # .po + flags/  (es_ES y es_LA = locale "es", videos/flags distintos)
res://docs/         # documentación
```
Convenciones: PascalCase para escenas, camelCase para variables, IDs en UPPER_SNAKE_CASE (descripciones añaden `_DESC`). Estilo de código **conciso**: comentarios `#` de una línea, sin docstrings multilínea; `@onready var x: Type = $Node` con espaciado natural (sin alineación en columnas).

## Sistemas implementados
- **Flujo intro→juego**: `IntroScreen.gd` (video localizado, letterbox 640x360/480x360), `TitleScreen.gd` (instancia `MainMenu.tscn` como hijo, no cambia escena), `MainMenu.gd` (navegación por cursor: flecha 18x24px; foco nativo de Godot desactivado; ancho de botón = ancho de texto + 4×'M').
- **ScreenFade** (AutoLoad): usa `color:a` (NO `modulate:a`) para alpha; `CanvasLayer` añadido a `get_tree().root` vía `call_deferred`; tamaño del rect seteado explícito por código.
- **Save system** (`SaveManager.gd`): slots infinitos (auto=0, quick=1, manual=2+), nombres custom, orden por fecha, animación de borrado en 5 fases. Opciones persistidas aparte en `user://config.dat`.
- **OptionsMenu** (5 pestañas: Audio, Video, Gameplay, Interface, Controls): navegación carousel con flechas; flags desde `res://translates/flags/`.
- **Audio** (`AudioManager.gd`): buses Master, Music, SFX; `stop_music()` es corutina (requiere `await`).
- **Datos** (patrón estándar): Model (extends Resource) + List (extends Node, carga JSON + caché) + JSON con IDs de traducción. Aplicado a Type, Status, Pokeball, Move.
- **Tipos** (`Type.gd`/`TypesList.gd`): 19 tipos (incl. Stellar), ~200 relaciones; doble tipo = multiplicación de efectividades (x4 / x0.25 / x0).
- **Formulae.gd**: ahora COMPLETO (stats, daño con STAB/stage/crit, 6 curvas XP, sistema de tiers).

## Mecánica clave: stats acumulativos
Los stats **nunca** se resetean al evolucionar — **solo el nivel** se resetea. Ivysaur nv1 ≈ Bulbasaur nv300 en stats acumulados. T0 es excepción: NO resetea nivel al evolucionar.

### Tiers (validado por simulación)
| Tier | cap | mult | reset |
|------|-----|------|-------|
| T0 baby | 30 | 1.0 | no |
| T1 | 60 | 1.0 | sí |
| T2 | 40 | 1.5 | sí |
| T3 final | 30 | 2.0 | — |
| T1 sin-evo | 150 | 1.0 | — |
| T2 método (Haunter/Kadabra/Graveler) | 40 | 3.0 | — |
| T4 legendario | 200 | — |
| T5 mítico | 250 | — |

Threshold level = cap+1. Encuentros escalados: `lv_mundi = round(lv_orig/100 × cap_tier)`. Legendarios/míticos caen en ratio 0.89x–1.93x vs poder esperado del jugador → todos apropiadamente desafiantes.

## Localización
Workbook `pokemon_mundi_localization.xlsx`, 8 idiomas (EN, ES, ES-LA, JA, DE, FR, IT, PT).
- ✅ Pokéballs (nombres + desc, 28).
- ✅ Moves (nombres + desc, 902 / 902).
- ⏳ Status: IDs reformateados, sin traducir.
- ⏳ tr() Keys: solo headers.
- ⚠️ FR moves rango ~101–190: placeholders "Jackpot" donde no se confirmó nombre oficial.
- ⚠️ `Move.gd` llama `tr()` sobre strings inglesas crudas en vez de claves UPPER_SNAKE_CASE → **decisión de migración pendiente**.

## Pendientes (TODO)
1. ✅ Campos `level_cap` y `tier` añadidos a `PokemonModel.gd` (placeholder hasta definir reglas).
2. ✅ `PokemonList.gd` completo (autoload; carga `Pokemon.json` vía StaticDataManagement).
3. Expandir `Moves.json` de 24 → 902 entradas.
4. Migrar `Move.gd` a claves de traducción estructuradas.
5. Completar hojas Status y tr() Keys de localización.
6. Terminar `Presentation.gd` (secuencia de creación de personaje: panel de notas en adelante).
7. Ampliar BD de niveles de encuentro salvaje y validar escalado de legendarios/míticos.

## Gotchas de Godot 4 (aprendidos a las malas)
- `ColorRect` alpha → animar `color:a`, no `modulate:a`.
- `CanvasLayer` → añadir a root con `call_deferred`.
- Rect size → setear por código, no `anchors_preset`.
- Corutinas (`stop_music`) → siempre `await`.

---

## Estado actual (handoff — actualizado 2026-06-17)

Proyecto movido a `Documents\GitHub\Pokemon_Mundi` (versionado en git). Flujo completo **intro → creación → mundo → menús** implementado y funcionando.

### Intro / presentación (`Scripts/Scenes/intro/Presentation.gd`)
- Notas → saludo de la **Profesora Yaniska Aranguren** ("Profesora Pikachu", **NO Oak**) → creación de personaje → mapa del mundo → objetivo → despedida → `Scenes/world/PlayerRoom.tscn`.
- Sprite profesora `Prof_Aranguren_main.png`: frame 0 = con pokébola, frame 1 = sin ella. Tras el mapa "saca a Pikachu" (destello + cambio de frame; falta sprite real de Pikachu para que aparezca).
- `Scripts/UI/DialogueBox.gd`: typewriter a velocidad constante según `game_options.text_speed`; consume `ui_accept` (no se filtra al mundo). `ChoiceBox.gd`: caja de opciones anclada a la esquina sup-izq del textbox, selección por flecha + color (texto no se mueve).
- `PlayerCreationPanel.gd` y `WorldMapDisplay.gd` se construyen **por código** (sus `.tscn` eran stubs vacíos — patrón común aquí).

### Resaltado de regiones (mapa de la presentación)
- `WorldMapDisplay.gd` resalta cada región (caja pulsante `RegionHighlight.gd`) leyendo `data/region_areas.json`; `Presentation.gd` reubica el textbox para no taparla.
- Cajas de región **ya definidas** en `data/region_areas.json` (14, incl. Decolore) leyendo el mapa con rejilla de coordenadas; afinar con `Scenes/debug/RegionMapper.tscn` (F6: arrastrar, **S** guarda JSON) si hace falta. Regiones: Kanto, Naranja (Archipiélago Naranja), Johto, Hoenn, Sinnoh, Unova, Kalos, Alola, Galar, Paldea, Almia, Oblivia, Fiore, Decolore.

### Mundo (`Scripts/Scenes/world/PlayerRoom.gd`)
- Cuarto **placeholder** por código (suelo, paredes con colisión, cámara que sigue al jugador con zoom 3, cartel interactuable). Falta el mundo/mapas reales.
- `Player.gd`: movimiento por casillas con colisión; una zancada (medio ciclo de animación) por paso, alternando pie.

### Menú de campo (`Scripts/UI/GameMenu.gd`, instanciado por PlayerRoom)
- Barra **horizontal de iconos** arriba, sin marco, oscurecido tenue: Mapa · Mochila · Pokédex · Equipo · Personaje · Otros (nav izq/der; Esc abre/cierra). Iconos placeholder en `Scripts/UI/MenuIcon.gd`. "Otros" = Guardar / Opciones / Salir al título.

### Sprites de Pokémon
- **Hojas regulares 2 col × 7 fil, frame 80px**. Filas (2 frames c/u): `battle_enemy`, `battle_ally`, `menu`, `walk_up`, `walk_left`, `walk_down`, `walk_right`.
- Nombre: `{dex:0001}_{genero M/F/U}[_{region}].png` (región vacía = base; **formas regionales = sprite propio**, no shader).
- Carga: `Scripts/Util/PokemonSprite.gd` (`class_name PokemonSprite`; arma AnimatedSprite2D+SpriteFrames, resuelve archivo con fallbacks de género/región). Ya hay `Assets/Sprites/pokemon/0001_U.png` (Bulbasaur, 160×560). Preview: `Scenes/debug/PokemonPreview.tscn` (F6).
- **Shiny / recolores**: `Assets/Shaders/palette_swap.gdshader` + `Scripts/Util/PaletteSwap.gd` (color-key, filtro nearest). El normal sale del PNG; el shader **solo** para shiny y ciertos recolores. La paleta normal se auto-extrae del sprite (colores únicos por luminancia); la shiny = mismos N colores en el mismo orden, recoloreados. **PENDIENTE**: herramienta `@tool` para definir shinies a JSON.

### Pokédex (biblioteca + interfaz)
- **Datos**: `Scripts/StaticData/Pokemon.json` con las **1025 especies** de la Pokédex Nacional, generadas desde PokeAPI (script `/tmp/gen_pokemon.py`, GraphQL beta host con User-Agent). Por entrada: nombre ES (fallback EN), genus/especie, descripción (flavor ES), tipos, altura/peso, habilidades, catch rate, curva XP, género, cadena evolutiva (`EvolveFrom`/`EvolveTo`), flags baby/legendary/mythical.
- ✅ **Tier/stats rellenados** (`docs/tier_system/fill_tiers.py`): `tier`, `level_cap`, los 6 `_max` acumulados y `BaseStats` (stats base reales) para las 1025 especies, replicando la simulación (`TIER_SYSTEM.md`/`tier_simulation.py`). Validado: 22/23 ejemplos del sim exactos. **Bebés** = T0 aparte, se ignoran para la cadena (regla del documento → Snorlax T1-NE ✓; única divergencia: Togekiss queda T2 en vez del T3 del ejemplo manual del sim). Recalcular ⇒ re-correr el script. T2-método ×3.0 es compensación de encuentro (runtime), no va en `_max`.
- **Carga**: `PokemonList.gd` (autoload nuevo, patrón estándar: caché + `get_by_id`/`get_by_name`/`get_evolutions`). `PokemonModel.gd` ahora se construye desde diccionario (`Pokemon.new(dict)`).
- **Pokédex regional**: cada especie tiene `Dex` = `{region: nº_regional}` (script `/tmp/add_regions.py`). 9 regiones con dex canónica de PokeAPI: kanto, johto (updated/HGSS), hoenn (updated/ORAS), sinnoh (extended/Pt), unova (updated/B2W2), kalos (central+coastal+mountain fusionadas), alola (updated/USUM), galar (galar+IoA+CT), paldea (paldea+kitakami+blueberry). Multi-dex se fusionan y renumeran secuencial. **Naranja** (Archipiélago Naranja) duplica la dex de Kanto (151, misma numeración; script `/tmp/add_naranja.py`).
  - **Regiones Ranger** (`/tmp/add_ranger.py`, desde Bulbapedia raw wikitext): **Fiore** (Directorio Ranger, 213), **Almia** (267 + 3 especiales Dialga/Palkia/Shaymin = 270), **Oblivia** (directorio Presente R-001…301 + S-001…006 = 307; el directorio Pasado N-/X- se omitió). **Decolore** (Islas Decolore, región anime): 20 especies de la wiki international-pokedex, numeradas por orden de Pokédex Nacional.
- **Interfaz**: `Scripts/UI/PokedexScreen.gd` (CanvasLayer por código), dos vistas: **CATEGORIES** (mapa mundi `pokemon_world_2.png` con filtro de pantalla digital roja —shader `Assets/Shaders/pokedex_screen.gdshader`—; se selecciona región por **hotspot en el mapa** (leídos de `data/region_areas.json`) o por **columna lateral** para Nacional, Decolore y regiones aún sin caja mapeada; nav ratón+flechas. **Fallback**: con las cajas a cero, todo sale en la columna hasta que se mapeen con RegionMapper) → **LIST** (lista **virtualizada**, 14 filas, con numeración regional si aplica + panel de detalle: sprite, nº, nombre, chips de tipo coloreados desde TypesList, especie, altura/peso, descripción). El **tier NO se muestra** (solo cálculos internos). Respeta visto/capturado de `Game`; no-vistos salen como "----------"/silueta. Nav ↑↓ (1, auto-repite al mantener) y ←→ (página); rueda del ratón sobre la lista. **Z/X** formas, **D** revela todo (debug). Se abre desde `GameMenu` (estado `POKEDEX`).
- **Formas**: cada especie tiene `Forms` (1581 tras la pasada cosmética) con base/regional/mega/gmax/cosmetic/alternate, tipos por forma y etiqueta localizada. `PokemonModel.base_form()` y `regional_form(region)`. La pasada exhaustiva (`/tmp/add_forms2.py`, vs PokeAPI `pokemon-form`) rellenó cosméticas que faltaban: Unown, Vivillon/Scatterbug/Spewpa (20 patrones), Furfrou, Florges/Floette/Flabébé, Deerling/Sawsbuck, Burmy/Mothim, Genesect (cassettes), Arceus/Silvally (placas, cambian tipo), Alcremie (63), etc. **OJO**: esa instancia de PokeAPI trae 48 megas FALSAS (fanon, p.ej. Mega-Greninja) — se filtran por `-mega` (las 48 reales ya estaban).
- **Diferencias de sexo**: 102 especies con `GenderDiff: true` + `GenderDiffDesc` (descripción corta ES, de WikiDex; script `/tmp/add_gender.py`). Cargado en `PokemonModel` (`gender_diff`, `gender_diff_desc`). Aún no se muestra en la UI de la Pokédex.
- **Patrones especiales** (utilidades estáticas en `Scripts/Util/`, listas para enchufar a la party cuando exista):
  - `SpindaPattern.gd`: manchas de Spinda por PID (32 bits), algoritmo fiel al juego (4 manchas, offset 0-15 px por par de nibbles). `spot_positions(pid)`, `random_pid()`, `render_spots()`. Faltan: el campo PID por individuo y el sprite/asset de la mancha (BASE_SPOTS es placeholder a ajustar).
  - `VivillonPattern.gd`: patrón de Vivillon según el país real (`OS.get_locale()` → código ISO → slug de forma), mapa canónico del 3DS (Bulbapedia). `pattern_for_player()`. Países "divididos" usan el patrón representativo; Fancy/Poké Ball son solo de evento.
  - **Secciones regionales**: si la especie tiene forma de esa región (alola/galar/paldea/naranja), el detalle muestra **solo esa forma** (tipos, etiqueta y sprite con sufijo de región), no la base. Las formas del Archipiélago Naranja son **solo cambio de coloración** (mismos tipos), en 30 especies de Kanto.
  - **Nacional**: selector de formas en el detalle (**Z/X**) para recorrer **todas** las formas; muestra "Forma i/N · etiqueta".
  - Sprites de forma usan `{dex}_{genero}_{region}.png`; hoy casi todos faltan → silueta "?".

### Gotchas importantes
- **Editar `.gd` por fuera de Godot** puede dejar la caché vieja ejecutándose (errores `@onready` de nodos inexistentes) → **Proyecto → Recargar Proyecto Actual**.
- Cada escena llama `ScreenFade.fade_in()` en su `_ready` (el que cambia de escena hace `fade_out` y deja la pantalla en negro).
- `min()/max()/abs()` devuelven Variant → no usar con `:=` (usar tipo explícito o `minf/maxf/absf`).
- Estilo UI: frame NinePatch `Assets/Sprites/Frames/frame_1.png`; acento teal `Color(0.05, 0.42, 0.42)`. Ventana fija 1280×720, filtro nearest global.

### Próximos pasos sugeridos
1. Definir las cajas de regiones con `RegionMapper` (deja visual la presentación).
2. Herramienta `@tool` para shinies + meter más sprites de Pokémon.
3. **Sistema Pokémon / party** (clase `Pokemon` sigue comentada en `Game.gd`/`GameModel.gd`) → desbloquea Equipo y combate. (La Pokédex ya consume `PokemonList`.)
   - ✅ Tier/level_cap/`_max`/BaseStats rellenados en `Pokemon.json` (`docs/tier_system/fill_tiers.py`, validado vs sim).
   - Sprites: solo existe `0001_U.png`; la Pokédex muestra silueta "?" donde falten.
4. Mundo real (PlayerRoom es placeholder); restaurar `last_position` al cargar partida.
