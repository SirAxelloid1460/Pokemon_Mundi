class_name PokedexScreen
extends CanvasLayer
# Pantalla completa de Pokédex. Dos vistas:
#   CATEGORIES → menú de categorías (Nacional + una por región).
#   LIST       → lista virtualizada de la categoría + panel de detalle.
# Respeta visto/capturado de Game. El tier NO se muestra (sólo cálculos internos).
# Nav lista: ↑↓ (1), ←→ (página), D revela todo (debug), ESC vuelve a categorías.

signal closed

const VIEWPORT := Vector2(1280, 720)
const ACCENT := Color(0.05, 0.42, 0.42)
const INK := Color(0.10, 0.10, 0.12)
const DIM_INK := Color(0.45, 0.45, 0.48)
const PAPER := Color(0.97, 0.96, 0.92)

const VISIBLE_ROWS := 14
const ROW_H := 36
const LIST_X := 70.0
const LIST_Y := 120.0
const DETAIL_X := 620.0
const SPRITE_POS := Vector2(1080, 250)

# Auto-repetición al mantener pulsada ↑/↓ y zonas de hover para la rueda del ratón
const REPEAT_DELAY := 0.32   # retardo antes de empezar a repetir
const REPEAT_RATE := 0.05    # intervalo entre pasos mientras se mantiene
const LIST_RECT := Rect2(62, 120, 508, 504)    # área de la lista (VISIBLE_ROWS*ROW_H)

# Categorías: Nacional + las regiones del juego (Ranger Fiore/Almia/Oblivia ya con datos + Decolore)
const CATEGORIES := [
	{"key": "national", "name": "Nacional"},
	{"key": "kanto",    "name": "Kanto"},
	{"key": "naranja",  "name": "A. Naranja"},
	{"key": "johto",    "name": "Johto"},
	{"key": "hoenn",    "name": "Hoenn"},
	{"key": "sinnoh",   "name": "Sinnoh"},
	{"key": "unova",    "name": "Teselia"},
	{"key": "kalos",    "name": "Kalos"},
	{"key": "alola",    "name": "Alola"},
	{"key": "galar",    "name": "Galar"},
	{"key": "paldea",   "name": "Paldea"},
	{"key": "almia",    "name": "Almia"},
	{"key": "oblivia",  "name": "Oblivia"},
	{"key": "fiore",    "name": "Fiore"},
	{"key": "decolore", "name": "Decolore"},
]

# key de categoría → nombre de región en data/region_areas.json (las que viven en el mapa)
const KEY_TO_AREA := {
	"kanto": "Kanto", "naranja": "Naranja", "johto": "Johto", "hoenn": "Hoenn",
	"sinnoh": "Sinnoh", "unova": "Unova", "kalos": "Kalos", "alola": "Alola",
	"galar": "Galar", "paldea": "Paldea", "almia": "Almia", "oblivia": "Oblivia",
	"fiore": "Fiore",
}

enum View { CATEGORIES, LIST }

var _view: int = View.CATEGORIES

# Vista LISTA
var _list: Array = []          # [{ "p": Pokemon, "num": int }]
var _category_key: String = "national"
var _category_name: String = "Nacional"
var _selected: int = 0
var _top: int = 0
var _reveal_all: bool = false
var _form_index: int = 0   # forma mostrada en el detalle (selector de la Nacional)
var _repeat_dir: int = 0   # dirección mantenida (↑/↓) para el auto-scroll
var _repeat_timer: float = 0.0

# Vista CATEGORÍAS
var _cat_index: int = 0
var _cat_counts: Dictionary = {}

# --- Nodos ---
var _cat_root: Control
var _cat_cursor: ColorRect
var _col_rows: Dictionary = {}      # key -> Label (fila de la columna lateral)
var _map_hi: Dictionary = {}        # key -> ColorRect (zona clicable sobre el mapa)
var _map_lbl: Dictionary = {}       # key -> Label (nombre sobre el mapa)
var _area_screen: Dictionary = {}   # key -> Rect2 en coordenadas de pantalla
var _cat_pulse: float = 0.0

var _list_root: Control
var _rows: Array = []
var _cursor: ColorRect
var _title_lbl: Label
var _stats_lbl: Label
var _empty_lbl: Label
var _sprite: PokemonSprite
var _sprite_placeholder: Label
var _num_lbl: Label
var _name_lbl: Label
var _form_lbl: Label
var _types_box: HBoxContainer
var _species_lbl: Label
var _phys_lbl: Label
var _desc_lbl: RichTextLabel

func _ready():
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	PokemonList.get_list()
	_build_common()
	_build_categories()
	_build_list()
	_show_categories()
	AudioManager.play_sfx("menu_select")

# ============================================
# CONSTRUCCIÓN COMÚN (fondo + marco)
# ============================================

func _build_common():
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.size = VIEWPORT
	add_child(dim)

	var bg := ColorRect.new()
	bg.color = PAPER
	bg.position = Vector2(44, 44)
	bg.size = Vector2(1192, 632)
	add_child(bg)

	var frame := NinePatchRect.new()
	frame.texture = load("res://Assets/Sprites/Frames/frame_1.png")
	frame.patch_margin_left = 6
	frame.patch_margin_top = 6
	frame.patch_margin_right = 6
	frame.patch_margin_bottom = 6
	frame.position = Vector2(40, 40)
	frame.size = Vector2(1200, 640)
	add_child(frame)

	_title_lbl = Label.new()
	_title_lbl.position = Vector2(70, 56)
	_title_lbl.add_theme_font_size_override("font_size", 40)
	_title_lbl.add_theme_color_override("font_color", ACCENT)
	add_child(_title_lbl)

	_stats_lbl = Label.new()
	_stats_lbl.position = Vector2(620, 66)
	_stats_lbl.size = Vector2(600, 30)
	_stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_stats_lbl.add_theme_font_size_override("font_size", 22)
	_stats_lbl.add_theme_color_override("font_color", INK)
	add_child(_stats_lbl)

# ============================================
# VISTA CATEGORÍAS
# ============================================

func _build_categories():
	_cat_root = Control.new()
	_cat_root.size = VIEWPORT
	add_child(_cat_root)

	# Conteos por categoría
	for c in CATEGORIES:
		if c.key == "national":
			_cat_counts[c.key] = PokemonList.get_total_count()
		else:
			_cat_counts[c.key] = PokemonList.get_by_region(c.key).size()

	var areas := _load_region_areas()

	# Fondo oscuro del área del mapa + mapa mundi con filtro de pantalla digital
	var mrect := Rect2(64, 104, 928, 560)
	var dark := ColorRect.new()
	dark.color = Color(0.04, 0.05, 0.08)
	dark.position = mrect.position
	dark.size = mrect.size
	_cat_root.add_child(dark)

	var tex: Texture2D = _load_map_texture()
	var map_origin := mrect.position
	var map_scale := 1.0
	if tex:
		var ts := tex.get_size()
		map_scale = minf(mrect.size.x / ts.x, mrect.size.y / ts.y)
		var draw := ts * map_scale
		map_origin = mrect.position + (mrect.size - draw) * 0.5
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.centered = false
		spr.position = map_origin
		spr.scale = Vector2(map_scale, map_scale)
		spr.material = _make_screen_material()
		_cat_root.add_child(spr)

	# Hotspots de las regiones que tengan caja definida (>0) en region_areas.json
	for c in CATEGORIES:
		var ak: String = KEY_TO_AREA.get(c.key, "")
		if ak == "" or not areas.has(ak):
			continue
		var box: Rect2 = areas[ak]
		if box.size.x <= 0.0 or box.size.y <= 0.0:
			continue
		var sr := Rect2(map_origin + box.position * map_scale, box.size * map_scale)
		_area_screen[c.key] = sr
		var hi := ColorRect.new()
		hi.color = Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.16)
		hi.position = sr.position
		hi.size = sr.size
		_cat_root.add_child(hi)
		_map_hi[c.key] = hi
		var ml := Label.new()
		ml.text = c.name
		ml.position = sr.position + Vector2(4, 2)
		ml.add_theme_font_size_override("font_size", 16)
		ml.add_theme_color_override("font_color", PAPER)
		_cat_root.add_child(ml)
		_map_lbl[c.key] = ml

	# Columna lateral: Nacional, Decolore y cualquier región aún sin caja en el mapa
	_cat_cursor = ColorRect.new()
	_cat_cursor.color = Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.20)
	_cat_cursor.size = Vector2(208, 28)
	_cat_root.add_child(_cat_cursor)

	var y := 116.0
	for c in CATEGORIES:
		if _area_screen.has(c.key):
			continue
		var row := Label.new()
		row.position = Vector2(1016, y)
		row.size = Vector2(192, 28)
		row.add_theme_font_size_override("font_size", 22)
		_cat_root.add_child(row)
		_col_rows[c.key] = row
		y += 30.0

	var hint := Label.new()
	hint.text = "↑↓ / ratón elegir   Enter / clic abrir   ESC salir"
	hint.position = Vector2(70, 664)
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", DIM_INK)
	_cat_root.add_child(hint)

func _load_region_areas() -> Dictionary:
	var out := {}
	var path := "res://data/region_areas.json"
	if not FileAccess.file_exists(path):
		return out
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return out
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		return out
	for rn in data:
		var r = data[rn]
		if r is Dictionary:
			out[rn] = Rect2(float(r.get("x", 0)), float(r.get("y", 0)), float(r.get("w", 0)), float(r.get("h", 0)))
	return out

func _load_map_texture() -> Texture2D:
	for p in ["res://Assets/Mapas_Regionales/pokemon_world_2.png", "res://Assets/Mapas_Regionales/Pokemon World.webp"]:
		if ResourceLoader.exists(p):
			return load(p)
	return null

func _make_screen_material() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://Assets/Shaders/pokedex_screen.gdshader")
	return m

func _cat_at_point(p: Vector2) -> String:
	for k in _area_screen:
		if (_area_screen[k] as Rect2).has_point(p):
			return k
	for k in _col_rows:
		var row: Label = _col_rows[k]
		if Rect2(1008, row.position.y - 1, 208, 28).has_point(p):
			return k
	return ""

func _index_of_key(key: String) -> int:
	for i in range(CATEGORIES.size()):
		if CATEGORIES[i].key == key:
			return i
	return 0

func _show_categories():
	_view = View.CATEGORIES
	_title_lbl.text = "POKÉDEX"
	_stats_lbl.text = "Capturados %d / %d" % [Game.pokedex_caught.size(), PokemonList.get_total_count()]
	_cat_root.visible = true
	_list_root.visible = false
	_refresh_categories()

func _refresh_categories():
	var sel_key: String = CATEGORIES[_cat_index].key
	# Filas de la columna lateral
	for c in CATEGORIES:
		if not _col_rows.has(c.key):
			continue
		var lbl: Label = _col_rows[c.key]
		var count: int = _cat_counts.get(c.key, 0)
		var on := c.key == sel_key
		lbl.text = ("%-10s %d" % [c.name, count]) if count > 0 else ("%-10s —" % c.name)
		lbl.add_theme_color_override("font_color", ACCENT if on else (INK if count > 0 else DIM_INK))
	# Cursor de columna (solo si el seleccionado vive en la columna)
	if _col_rows.has(sel_key):
		_cat_cursor.visible = true
		_cat_cursor.position = Vector2(1008, (_col_rows[sel_key] as Label).position.y - 1)
	else:
		_cat_cursor.visible = false
	# Resaltado base de los hotspots no seleccionados (el seleccionado pulsa en _process)
	for k in _map_hi:
		if k != sel_key:
			(_map_hi[k] as ColorRect).color = Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.16)

func _input_categories(event: InputEvent):
	# ↑/↓ se gestionan en _process (auto-repetición al mantener pulsado)
	if event is InputEventMouseMotion:
		var k := _cat_at_point(event.position)
		if k != "" and k != CATEGORIES[_cat_index].key:
			_cat_index = _index_of_key(k)
			AudioManager.play_sfx("menu_move")
			_refresh_categories()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var k2 := _cat_at_point(event.position)
		if k2 != "":
			_cat_index = _index_of_key(k2)
			_open_category(CATEGORIES[_cat_index])
		return
	if event.is_action_pressed("ui_cancel"):
		_close()
	elif event.is_action_pressed("ui_accept"):
		_open_category(CATEGORIES[_cat_index])

# ============================================
# VISTA LISTA
# ============================================

func _build_list():
	_list_root = Control.new()
	_list_root.size = VIEWPORT
	add_child(_list_root)

	var sep := ColorRect.new()
	sep.color = Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.35)
	sep.position = Vector2(590, 112)
	sep.size = Vector2(2, 540)
	_list_root.add_child(sep)

	_cursor = ColorRect.new()
	_cursor.color = Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.18)
	_cursor.position = Vector2(LIST_X - 8, LIST_Y)
	_cursor.size = Vector2(508, ROW_H)
	_list_root.add_child(_cursor)

	for i in range(VISIBLE_ROWS):
		var lbl := Label.new()
		lbl.position = Vector2(LIST_X, LIST_Y + i * ROW_H + 2)
		lbl.size = Vector2(500, ROW_H)
		lbl.add_theme_font_size_override("font_size", 24)
		lbl.add_theme_color_override("font_color", INK)
		_list_root.add_child(lbl)
		_rows.append(lbl)

	_empty_lbl = Label.new()
	_empty_lbl.text = "(Sin datos — próximamente)"
	_empty_lbl.position = Vector2(LIST_X, 300)
	_empty_lbl.add_theme_font_size_override("font_size", 26)
	_empty_lbl.add_theme_color_override("font_color", DIM_INK)
	_empty_lbl.visible = false
	_list_root.add_child(_empty_lbl)

	# --- Detalle ---
	_num_lbl = Label.new()
	_num_lbl.position = Vector2(DETAIL_X, 116)
	_num_lbl.add_theme_font_size_override("font_size", 24)
	_num_lbl.add_theme_color_override("font_color", DIM_INK)
	_list_root.add_child(_num_lbl)

	_name_lbl = Label.new()
	_name_lbl.position = Vector2(DETAIL_X, 142)
	_name_lbl.add_theme_font_size_override("font_size", 42)
	_name_lbl.add_theme_color_override("font_color", INK)
	_list_root.add_child(_name_lbl)

	_form_lbl = Label.new()
	_form_lbl.position = Vector2(DETAIL_X, 192)
	_form_lbl.size = Vector2(440, 28)
	_form_lbl.add_theme_font_size_override("font_size", 21)
	_form_lbl.add_theme_color_override("font_color", ACCENT)
	_list_root.add_child(_form_lbl)

	_types_box = HBoxContainer.new()
	_types_box.add_theme_constant_override("separation", 10)
	_types_box.position = Vector2(DETAIL_X, 226)
	_list_root.add_child(_types_box)

	_species_lbl = Label.new()
	_species_lbl.position = Vector2(DETAIL_X, 268)
	_species_lbl.add_theme_font_size_override("font_size", 24)
	_species_lbl.add_theme_color_override("font_color", ACCENT)
	_list_root.add_child(_species_lbl)

	_phys_lbl = Label.new()
	_phys_lbl.position = Vector2(DETAIL_X, 302)
	_phys_lbl.add_theme_font_size_override("font_size", 22)
	_phys_lbl.add_theme_color_override("font_color", INK)
	_list_root.add_child(_phys_lbl)

	_desc_lbl = RichTextLabel.new()
	_desc_lbl.bbcode_enabled = false
	_desc_lbl.fit_content = true
	_desc_lbl.scroll_active = false
	_desc_lbl.position = Vector2(DETAIL_X, 470)
	_desc_lbl.size = Vector2(580, 170)
	_desc_lbl.add_theme_font_size_override("normal_font_size", 23)
	_desc_lbl.add_theme_color_override("default_color", INK)
	_list_root.add_child(_desc_lbl)

	_sprite = PokemonSprite.new()
	_sprite.position = SPRITE_POS
	_sprite.scale = Vector2(2.6, 2.6)
	_list_root.add_child(_sprite)

	_sprite_placeholder = Label.new()
	_sprite_placeholder.position = Vector2(980, 150)
	_sprite_placeholder.size = Vector2(200, 200)
	_sprite_placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sprite_placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_sprite_placeholder.add_theme_font_size_override("font_size", 120)
	_sprite_placeholder.add_theme_color_override("font_color", Color(DIM_INK.r, DIM_INK.g, DIM_INK.b, 0.6))
	_list_root.add_child(_sprite_placeholder)

	var hint := Label.new()
	hint.text = "↑↓ mover   ←→ página   Z/X formas   D revelar   ESC categorías"
	hint.position = Vector2(70, 648)
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", DIM_INK)
	_list_root.add_child(hint)

func _open_category(cat: Dictionary):
	_category_key = cat.key
	_category_name = cat.name
	_list.clear()
	var mons := PokemonList.get_by_region(cat.key)
	for p in mons:
		var num: int = p.pokedexNr if cat.key == "national" else int(p.regional_dex.get(cat.key, 0))
		_list.append({"p": p, "num": num})
	_selected = 0
	_top = 0
	_form_index = 0
	_view = View.LIST
	_cat_root.visible = false
	_list_root.visible = true
	_title_lbl.text = "POKÉDEX · " + _category_name
	AudioManager.play_sfx("menu_select")
	_refresh_list_view()

func _input_list(event: InputEvent):
	# ↑/↓ se gestionan en _process (auto-repetición al mantener pulsado)
	if event.is_action_pressed("ui_cancel"):
		_show_categories()
		AudioManager.play_sfx("menu_back")
	elif event.is_action_pressed("ui_right"):
		_move_selection(VISIBLE_ROWS)
	elif event.is_action_pressed("ui_left"):
		_move_selection(-VISIBLE_ROWS)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_D:
		_reveal_all = not _reveal_all
		_refresh_list_view()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_X:
		_cycle_form(1)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_Z:
		_cycle_form(-1)

func _move_selection(delta: int, play_sound := true):
	var n := _list.size()
	if n == 0:
		return
	var prev := _selected
	_selected = clampi(_selected + delta, 0, n - 1)
	if _selected == prev:
		return
	if _selected < _top:
		_top = _selected
	elif _selected >= _top + VISIBLE_ROWS:
		_top = _selected - VISIBLE_ROWS + 1
	_top = clampi(_top, 0, maxi(0, n - VISIBLE_ROWS))
	_form_index = 0
	if play_sound:
		AudioManager.play_sfx("menu_move")
	_refresh_list_view()

# Lista de formas a mostrar en la categoría actual para una especie.
# Nacional: todas. Región con formas regionales (alola/galar/paldea): TODAS las
# de esa región (ciclables con Z/X, p.ej. las 3 razas de Tauros de Paldea); si
# no hay, solo la base. Resto de regiones: solo la base.
func _display_forms(p: Pokemon) -> Array:
	if p.forms.is_empty():
		return []
	if _category_key == "national":
		return p.forms
	var regs: Array = []
	for f in p.forms:
		if f.get("region", "") == _category_key:
			regs.append(f)
	if not regs.is_empty():
		return regs
	return [p.base_form()]

func _cycle_form(delta: int):
	if _view != View.LIST or _list.is_empty():
		return
	var forms := _display_forms(_list[_selected].p)
	if forms.size() <= 1:
		return
	_form_index = (_form_index + delta + forms.size()) % forms.size()
	AudioManager.play_sfx("menu_move")
	_refresh_detail()

func _refresh_list_view():
	_refresh_stats()
	var empty := _list.is_empty()
	_empty_lbl.visible = empty
	_cursor.visible = not empty
	for lbl in _rows:
		lbl.visible = not empty
	if empty:
		_clear_detail()
		return
	_refresh_rows()
	_refresh_detail()

func _refresh_stats():
	if _category_key == "national":
		_stats_lbl.text = "Vistos %d   Capturados %d / %d" % [Game.pokedex_seen.size(), Game.pokedex_caught.size(), _list.size()]
	else:
		var caught := 0
		for it in _list:
			if _is_caught(it.p.pokeID):
				caught += 1
		_stats_lbl.text = "Capturados %d / %d" % [caught, _list.size()]

func _refresh_rows():
	for i in range(VISIBLE_ROWS):
		var lbl: Label = _rows[i]
		var idx := _top + i
		if idx >= _list.size():
			lbl.text = ""
			continue
		var it = _list[idx]
		var p: Pokemon = it.p
		var seen := _is_seen(p.pokeID)
		var caught := _is_caught(p.pokeID)
		var mark := "●" if caught else ("○" if seen else " ")
		var label_name := p.name if seen else "----------"
		lbl.text = "%s  Nº%04d  %s" % [mark, it.num, label_name]
		var is_sel := idx == _selected
		lbl.add_theme_color_override("font_color", ACCENT if is_sel else (INK if seen else DIM_INK))
	_cursor.position = Vector2(LIST_X - 8, LIST_Y + (_selected - _top) * ROW_H)

func _refresh_detail():
	var it = _list[_selected]
	var p: Pokemon = it.p
	var seen := _is_seen(p.pokeID)

	# Número: el de la categoría; si es regional, también el Nacional
	if _category_key == "national":
		_num_lbl.text = "Nº %04d" % it.num
	else:
		_num_lbl.text = "Nº %04d   ·   Nac. %04d" % [it.num, p.pokedexNr]

	for c in _types_box.get_children():
		c.queue_free()

	if not seen:
		_name_lbl.text = "----------"
		_name_lbl.add_theme_color_override("font_color", DIM_INK)
		_form_lbl.text = ""
		_species_lbl.text = ""
		_phys_lbl.text = ""
		_desc_lbl.text = ""
		_sprite.visible = false
		_sprite_placeholder.text = "?"
		_sprite_placeholder.visible = true
		return

	# Forma actual a mostrar (regional fija, o la elegida con Z/X en la Nacional)
	var forms := _display_forms(p)
	_form_index = clampi(_form_index, 0, maxi(0, forms.size() - 1))
	var form: Dictionary = forms[_form_index] if not forms.is_empty() else {}
	var t1: String = form.get("type1", p.type1)
	var t2: String = form.get("type2", p.type2)

	_name_lbl.text = p.name
	_name_lbl.add_theme_color_override("font_color", INK)
	_form_lbl.text = _form_caption(form, forms.size())
	_species_lbl.text = p.species
	_phys_lbl.text = "Altura  %.1f m      Peso  %.1f kg" % [p.height, p.weight]
	_desc_lbl.text = p.description

	_add_type_chip(t1)
	if t2 != "":
		_add_type_chip(t2)

	var region: String = form.get("region", "")
	var path := PokemonSprite.resolve_path(p.pokeID, "U", region)
	if path != "":
		_sprite.visible = true
		_sprite_placeholder.visible = false
		_sprite.load_pokemon(p.pokeID, "U", region, "menu")
	else:
		_sprite.visible = false
		_sprite_placeholder.text = "?"
		_sprite_placeholder.visible = true

func _form_caption(form: Dictionary, total: int) -> String:
	if form.is_empty():
		return ""
	var label: String = form.get("label", "")
	# Si hay varias formas a recorrer (Nacional o región con varias), mostrar el selector
	if total > 1:
		var form_name := label if label != "" else "Base"
		return "Forma %d/%d  ·  %s" % [_form_index + 1, total, form_name]
	# Forma única: solo la etiqueta (si no es base)
	if form.get("category", "") != "base" and label != "":
		return label
	return ""

func _clear_detail():
	_num_lbl.text = ""
	_name_lbl.text = ""
	_form_lbl.text = ""
	_species_lbl.text = ""
	_phys_lbl.text = ""
	_desc_lbl.text = ""
	for c in _types_box.get_children():
		c.queue_free()
	_sprite.visible = false
	_sprite_placeholder.visible = false

# ============================================
# INPUT (dispatcher)
# ============================================

# Auto-scroll continuo: mientras se mantenga ↑/↓, repetir el paso tras un retardo inicial.
func _process(delta: float):
	if _view == View.CATEGORIES:
		_cat_pulse += delta
		var sk: String = CATEGORIES[_cat_index].key
		if _map_hi.has(sk):
			var a: float = 0.30 + 0.18 * sin(_cat_pulse * 6.0)
			(_map_hi[sk] as ColorRect).color = Color(ACCENT.r, ACCENT.g, ACCENT.b, a)
	var dir := 0
	if Input.is_action_pressed("ui_down"):
		dir += 1
	if Input.is_action_pressed("ui_up"):
		dir -= 1
	if dir == 0:
		_repeat_dir = 0
		return
	if dir != _repeat_dir:
		_repeat_dir = dir
		_repeat_timer = REPEAT_DELAY
		_step(dir, true)
	else:
		_repeat_timer -= delta
		if _repeat_timer <= 0.0:
			_repeat_timer = REPEAT_RATE
			_step(dir, false)   # pasos repetidos: sin sonido para no saturar

func _step(dir: int, play_sound: bool):
	if _view == View.LIST:
		_move_selection(dir, play_sound)
	else:
		_move_cat(dir, play_sound)

func _move_cat(delta: int, play_sound := true):
	var prev := _cat_index
	_cat_index = clampi(_cat_index + delta, 0, CATEGORIES.size() - 1)
	if _cat_index == prev:
		return
	if play_sound:
		AudioManager.play_sfx("menu_move")
	_refresh_categories()

func _input(event: InputEvent):
	if _handle_wheel(event):
		get_viewport().set_input_as_handled()
		return
	if _view == View.CATEGORIES:
		_input_categories(event)
	else:
		_input_list(event)
	get_viewport().set_input_as_handled()

# Rueda del ratón: desplaza la lista/categorías si el cursor está sobre su área.
func _handle_wheel(event: InputEvent) -> bool:
	if not (event is InputEventMouseButton and event.pressed):
		return false
	var step := 0
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		step = -1
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		step = 1
	else:
		return false
	if _view == View.LIST and LIST_RECT.has_point(event.position):
		_move_selection(step)
		return true
	if _view == View.CATEGORIES:
		_move_cat(step)
		return true
	return false

func _close():
	AudioManager.play_sfx("menu_back")
	closed.emit()
	queue_free()

# ============================================
# HELPERS
# ============================================

func _is_seen(dex: int) -> bool:
	return _reveal_all or Game.is_pokemon_seen(dex)

func _is_caught(dex: int) -> bool:
	return _reveal_all or Game.is_pokemon_caught(dex)

func _add_type_chip(type_name: String):
	if type_name == "":
		return
	var chip := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = _type_color(type_name)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(6)
	chip.add_theme_stylebox_override("panel", sb)
	var lbl := Label.new()
	lbl.text = type_name.to_upper()
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	lbl.add_theme_constant_override("outline_size", 3)
	chip.add_child(lbl)
	_types_box.add_child(chip)

func _type_color(type_name: String) -> Color:
	var id := Type.from_string(type_name)
	if id < 0:
		return Color(0.4, 0.4, 0.4)
	var t = TypesList.get_by_id(id)
	return t.color if t else Color(0.4, 0.4, 0.4)
