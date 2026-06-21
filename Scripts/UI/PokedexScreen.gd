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

# Categorías: Nacional + las 12 regiones del juego (las 3 Ranger sin datos aún)
const CATEGORIES := [
	{"key": "national", "name": "Nacional"},
	{"key": "kanto",    "name": "Kanto"},
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
]

enum View { CATEGORIES, LIST }

var _view: int = View.CATEGORIES

# Vista LISTA
var _list: Array = []          # [{ "p": Pokemon, "num": int }]
var _category_key: String = "national"
var _category_name: String = "Nacional"
var _selected: int = 0
var _top: int = 0
var _reveal_all: bool = false

# Vista CATEGORÍAS
var _cat_index: int = 0
var _cat_counts: Dictionary = {}

# --- Nodos ---
var _cat_root: Control
var _cat_rows: Array = []
var _cat_cursor: ColorRect

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

	var sub := Label.new()
	sub.text = "Elige una categoría"
	sub.position = Vector2(70, 110)
	sub.add_theme_font_size_override("font_size", 24)
	sub.add_theme_color_override("font_color", DIM_INK)
	_cat_root.add_child(sub)

	_cat_cursor = ColorRect.new()
	_cat_cursor.color = Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.18)
	_cat_cursor.size = Vector2(560, 36)
	_cat_root.add_child(_cat_cursor)

	# Precomputar conteos por categoría
	for c in CATEGORIES:
		if c.key == "national":
			_cat_counts[c.key] = PokemonList.get_total_count()
		else:
			_cat_counts[c.key] = PokemonList.get_by_region(c.key).size()

	var y := 150.0
	for i in range(CATEGORIES.size()):
		var row := Label.new()
		row.position = Vector2(80, y + i * 36)
		row.size = Vector2(540, 34)
		row.add_theme_font_size_override("font_size", 25)
		_cat_root.add_child(row)
		_cat_rows.append(row)

	var hint := Label.new()
	hint.text = "↑↓ elegir   Enter abrir   ESC salir"
	hint.position = Vector2(70, 648)
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", DIM_INK)
	_cat_root.add_child(hint)

func _show_categories():
	_view = View.CATEGORIES
	_title_lbl.text = "POKÉDEX"
	_stats_lbl.text = "Capturados %d / %d" % [Game.pokedex_caught.size(), PokemonList.get_total_count()]
	_cat_root.visible = true
	_list_root.visible = false
	_refresh_categories()

func _refresh_categories():
	for i in range(_cat_rows.size()):
		var c = CATEGORIES[i]
		var lbl: Label = _cat_rows[i]
		var count: int = _cat_counts.get(c.key, 0)
		var is_sel := i == _cat_index
		if count > 0:
			lbl.text = "%-12s %d" % [c.name, count]
			lbl.add_theme_color_override("font_color", ACCENT if is_sel else INK)
		else:
			lbl.text = "%-12s — próximamente" % c.name
			lbl.add_theme_color_override("font_color", ACCENT if is_sel else DIM_INK)
	_cat_cursor.position = Vector2(74, 150 + _cat_index * 36 - 1)

func _input_categories(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		_close()
	elif event.is_action_pressed("ui_down"):
		_cat_index = (_cat_index + 1) % CATEGORIES.size()
		AudioManager.play_sfx("menu_move")
		_refresh_categories()
	elif event.is_action_pressed("ui_up"):
		_cat_index = (_cat_index - 1 + CATEGORIES.size()) % CATEGORIES.size()
		AudioManager.play_sfx("menu_move")
		_refresh_categories()
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
	_name_lbl.position = Vector2(DETAIL_X, 144)
	_name_lbl.add_theme_font_size_override("font_size", 44)
	_name_lbl.add_theme_color_override("font_color", INK)
	_list_root.add_child(_name_lbl)

	_types_box = HBoxContainer.new()
	_types_box.add_theme_constant_override("separation", 10)
	_types_box.position = Vector2(DETAIL_X, 206)
	_list_root.add_child(_types_box)

	_species_lbl = Label.new()
	_species_lbl.position = Vector2(DETAIL_X, 256)
	_species_lbl.add_theme_font_size_override("font_size", 24)
	_species_lbl.add_theme_color_override("font_color", ACCENT)
	_list_root.add_child(_species_lbl)

	_phys_lbl = Label.new()
	_phys_lbl.position = Vector2(DETAIL_X, 292)
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
	hint.text = "↑↓ mover   ←→ página   D revelar   ESC categorías"
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
	_view = View.LIST
	_cat_root.visible = false
	_list_root.visible = true
	_title_lbl.text = "POKÉDEX · " + _category_name
	AudioManager.play_sfx("menu_select")
	_refresh_list_view()

func _input_list(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		_show_categories()
		AudioManager.play_sfx("menu_back")
	elif event.is_action_pressed("ui_down"):
		_move_selection(1)
	elif event.is_action_pressed("ui_up"):
		_move_selection(-1)
	elif event.is_action_pressed("ui_right"):
		_move_selection(VISIBLE_ROWS)
	elif event.is_action_pressed("ui_left"):
		_move_selection(-VISIBLE_ROWS)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_D:
		_reveal_all = not _reveal_all
		_refresh_list_view()

func _move_selection(delta: int):
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
	AudioManager.play_sfx("menu_move")
	_refresh_list_view()

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
		_species_lbl.text = ""
		_phys_lbl.text = ""
		_desc_lbl.text = ""
		_sprite.visible = false
		_sprite_placeholder.text = "?"
		_sprite_placeholder.visible = true
		return

	_name_lbl.text = p.name
	_name_lbl.add_theme_color_override("font_color", INK)
	_species_lbl.text = p.species
	_phys_lbl.text = "Altura  %.1f m      Peso  %.1f kg" % [p.height, p.weight]
	_desc_lbl.text = p.description

	_add_type_chip(p.type1)
	if p.type2 != "":
		_add_type_chip(p.type2)

	var path := PokemonSprite.resolve_path(p.pokeID, "U", "")
	if path != "":
		_sprite.visible = true
		_sprite_placeholder.visible = false
		_sprite.load_pokemon(p.pokeID, "U", "", "menu")
	else:
		_sprite.visible = false
		_sprite_placeholder.text = "?"
		_sprite_placeholder.visible = true

func _clear_detail():
	_num_lbl.text = ""
	_name_lbl.text = ""
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

func _input(event: InputEvent):
	if _view == View.CATEGORIES:
		_input_categories(event)
	else:
		_input_list(event)
	get_viewport().set_input_as_handled()

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
