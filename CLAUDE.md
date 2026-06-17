# Pokémon Mundi — Resumen del proyecto (handoff para Claude Code)

RPG fan-made tipo Pokémon con elementos de Ranger. Motor **Godot 4 / GDScript**. Desarrollador único (Axel).

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
1. Añadir campos `level_cap` y `tier` a `PokemonModel.gd`.
2. Completar `PokemonList.gd` (hoy es stub: devuelve `[Pokemon.new()]`).
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
