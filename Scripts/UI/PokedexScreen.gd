class_name PokedexScreen
extends CanvasLayer
# Pantalla completa de Pokédex: lista virtualizada (~1025) + panel de detalle.
# Respeta visto/capturado de Game. Se abre desde GameMenu; Esc cierra.
# Navegación: arriba/abajo (1), izq/der o RePág/AvPág (página). D = revelar todo (debug).

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

var _entries: Array[Pokemon] = []
var _selected: int = 0
var _top: int = 0
var _reveal_all: bool = false

var _rows: Array = []
var _cursor: ColorRect
var _stats_lbl: Label
var _sprite: PokemonSprite
var _sprite_placeholder: Label

# Detalle
var _num_lbl: Label
var _name_lbl: Label
var _types_box: HBoxContainer
var _species_lbl: Label
var _phys_lbl: Label
var _desc_lbl: RichTextLabel

func _ready():
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_entries = PokemonList.get_list()
	_build_ui()
	_refresh_all()
	AudioManager.play_sfx("menu_select")

# ============================================
# CONSTRUCCIÓN DE UI
# ============================================

func _build_ui():
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

	var title := Label.new()
	title.text = "POKÉDEX"
	title.position = Vector2(70, 56)
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", ACCENT)
	add_child(title)

	_stats_lbl = Label.new()
	_stats_lbl.position = Vector2(620, 66)
	_stats_lbl.size = Vector2(600, 30)
	_stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_stats_lbl.add_theme_font_size_override("font_size", 22)
	_stats_lbl.add_theme_color_override("font_color", INK)
	add_child(_stats_lbl)

	# Separador vertical entre lista y detalle
	var sep := ColorRect.new()
	sep.color = Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.35)
	sep.position = Vector2(590, 112)
	sep.size = Vector2(2, 540)
	add_child(sep)

	# --- Lista virtualizada ---
	_cursor = ColorRect.new()
	_cursor.color = Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.18)
	_cursor.position = Vector2(LIST_X - 8, LIST_Y)
	_cursor.size = Vector2(508, ROW_H)
	add_child(_cursor)

	for i in range(VISIBLE_ROWS):
		var lbl := Label.new()
		lbl.position = Vector2(LIST_X, LIST_Y + i * ROW_H + 2)
		lbl.size = Vector2(500, ROW_H)
		lbl.add_theme_font_size_override("font_size", 24)
		lbl.add_theme_color_override("font_color", INK)
		add_child(lbl)
		_rows.append(lbl)

	# --- Detalle ---
	_num_lbl = Label.new()
	_num_lbl.position = Vector2(DETAIL_X, 116)
	_num_lbl.add_theme_font_size_override("font_size", 24)
	_num_lbl.add_theme_color_override("font_color", DIM_INK)
	add_child(_num_lbl)

	_name_lbl = Label.new()
	_name_lbl.position = Vector2(DETAIL_X, 144)
	_name_lbl.add_theme_font_size_override("font_size", 44)
	_name_lbl.add_theme_color_override("font_color", INK)
	add_child(_name_lbl)

	_types_box = HBoxContainer.new()
	_types_box.add_theme_constant_override("separation", 10)
	_types_box.position = Vector2(DETAIL_X, 206)
	add_child(_types_box)

	_species_lbl = Label.new()
	_species_lbl.position = Vector2(DETAIL_X, 256)
	_species_lbl.add_theme_font_size_override("font_size", 24)
	_species_lbl.add_theme_color_override("font_color", ACCENT)
	add_child(_species_lbl)

	_phys_lbl = Label.new()
	_phys_lbl.position = Vector2(DETAIL_X, 292)
	_phys_lbl.add_theme_font_size_override("font_size", 22)
	_phys_lbl.add_theme_color_override("font_color", INK)
	add_child(_phys_lbl)

	_desc_lbl = RichTextLabel.new()
	_desc_lbl.bbcode_enabled = false
	_desc_lbl.fit_content = true
	_desc_lbl.scroll_active = false
	_desc_lbl.position = Vector2(DETAIL_X, 470)
	_desc_lbl.size = Vector2(580, 170)
	_desc_lbl.add_theme_font_size_override("normal_font_size", 23)
	_desc_lbl.add_theme_color_override("default_color", INK)
	add_child(_desc_lbl)

	# Sprite (Node2D) y placeholder
	_sprite = PokemonSprite.new()
	_sprite.position = SPRITE_POS
	_sprite.scale = Vector2(2.6, 2.6)
	add_child(_sprite)

	_sprite_placeholder = Label.new()
	_sprite_placeholder.position = Vector2(980, 150)
	_sprite_placeholder.size = Vector2(200, 200)
	_sprite_placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sprite_placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_sprite_placeholder.add_theme_font_size_override("font_size", 120)
	_sprite_placeholder.add_theme_color_override("font_color", Color(DIM_INK.r, DIM_INK.g, DIM_INK.b, 0.6))
	add_child(_sprite_placeholder)

	var hint := Label.new()
	hint.text = "↑↓ mover   ←→ página   D revelar   ESC volver"
	hint.position = Vector2(70, 648)
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", DIM_INK)
	add_child(hint)

# ============================================
# INPUT
# ============================================

func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		_move_selection(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		_move_selection(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_move_selection(VISIBLE_ROWS)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left"):
		_move_selection(-VISIBLE_ROWS)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_D:
		_reveal_all = not _reveal_all
		_refresh_all()
		get_viewport().set_input_as_handled()

func _move_selection(delta: int):
	var n := _entries.size()
	if n == 0:
		return
	var prev := _selected
	_selected = clampi(_selected + delta, 0, n - 1)
	if _selected == prev:
		return
	# Mantener la selección dentro de la ventana visible
	if _selected < _top:
		_top = _selected
	elif _selected >= _top + VISIBLE_ROWS:
		_top = _selected - VISIBLE_ROWS + 1
	_top = clampi(_top, 0, maxi(0, n - VISIBLE_ROWS))
	AudioManager.play_sfx("menu_move")
	_refresh_all()

func _close():
	AudioManager.play_sfx("menu_back")
	closed.emit()
	queue_free()

# ============================================
# REFRESCO
# ============================================

func _refresh_all():
	_refresh_list()
	_refresh_detail()
	_refresh_stats()

func _refresh_stats():
	var caught := Game.pokedex_caught.size()
	var seen := Game.pokedex_seen.size()
	_stats_lbl.text = "Vistos %d   Capturados %d / %d" % [seen, caught, _entries.size()]

func _refresh_list():
	for i in range(VISIBLE_ROWS):
		var lbl: Label = _rows[i]
		var idx := _top + i
		if idx >= _entries.size():
			lbl.text = ""
			continue
		var p: Pokemon = _entries[idx]
		var seen := _is_seen(p.pokeID)
		var caught := _is_caught(p.pokeID)
		var mark := "●" if caught else ("○" if seen else " ")
		var label_name := p.name if seen else "----------"
		lbl.text = "%s  Nº%04d  %s" % [mark, p.pokedexNr, label_name]
		var is_sel := idx == _selected
		lbl.add_theme_color_override("font_color", ACCENT if is_sel else (INK if seen else DIM_INK))
	# Posición del cursor
	var row_in_view := _selected - _top
	_cursor.position = Vector2(LIST_X - 8, LIST_Y + row_in_view * ROW_H)

func _refresh_detail():
	if _entries.is_empty():
		return
	var p: Pokemon = _entries[_selected]
	var seen := _is_seen(p.pokeID)
	_num_lbl.text = "Nº %04d" % p.pokedexNr

	# Limpiar chips de tipo
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

	# Sprite si existe; si no, silueta con número
	var path := PokemonSprite.resolve_path(p.pokeID, "U", "")
	if path != "":
		_sprite.visible = true
		_sprite_placeholder.visible = false
		_sprite.load_pokemon(p.pokeID, "U", "", "menu")
	else:
		_sprite.visible = false
		_sprite_placeholder.text = "?"
		_sprite_placeholder.visible = true

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
	lbl.text = type_name.capitalize().to_upper()
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
