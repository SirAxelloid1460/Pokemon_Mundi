# ============================================
# PlayerCreationPanel.gd
# Panel unificado de creación de personaje (UI construida por código).
# Izquierda: previews. Derecha: nombre, género, apariencia y outfit (5 partes).
# ============================================
extends PanelContainer

signal creation_confirmed(player_data: Dictionary)

# ============================================
# REFERENCIAS A NODOS (creadas en _build_ui)
# ============================================

var preview_front: TextureRect
var preview_battle: TextureRect
var preview_walk: TextureRect
var label_front: Label
var label_battle: Label
var label_walk: Label

var name_input: LineEdit

var btn_gender_left: Button
var btn_gender_right: Button
var label_gender: Label

var btn_skin_left: Button
var btn_skin_right: Button
var label_skin: Label

var btn_hair_style_left: Button
var btn_hair_style_right: Button
var label_hair_style: Label

var btn_hair_color_left: Button
var btn_hair_color_right: Button
var label_hair_color: Label

var btn_hat_left: Button
var btn_hat_right: Button
var label_hat: Label

var btn_shirt_left: Button
var btn_shirt_right: Button
var label_shirt: Label

var btn_pants_left: Button
var btn_pants_right: Button
var label_pants: Label

var btn_shoes_left: Button
var btn_shoes_right: Button
var label_shoes: Label

var btn_gloves_left: Button
var btn_gloves_right: Button
var label_gloves: Label

var btn_confirm: Button
var label_error: Label

# ============================================
# CONSTANTES — APARIENCIA
# ============================================

const SPRITE_BASE = "res://Assets/Sprites/MainCharacter/"

const SKIN_TONES  = 6
const HAIR_STYLES = 8
const HAIR_COLORS = 12

const GENDERS       = ["boy", "girl"]
const GENDER_LABELS = ["Chico", "Chica"]

const HAIR_COLOR_NAMES = [
	"Negro", "Castaño oscuro", "Castaño", "Rubio oscuro",
	"Rubio", "Pelirrojo", "Naranja", "Rosa",
	"Morado", "Azul", "Verde", "Blanco"
]

# Gorra y Guantes: índice 0 = sin accesorio. Camisa/Pantalón varían por género.
const HATS_COUNT   = 6
const SHOES_COUNT  = 8
const GLOVES_COUNT = 4
const SHIRTS_BOY   = 8
const SHIRTS_GIRL  = 8
const PANTS_BOY    = 6
const PANTS_GIRL   = 6

# ============================================
# ESTADO ACTUAL
# ============================================

var current_gender_index: int = 0
var current_skin:         int = 0
var current_hair_style:   int = 0
var current_hair_color:   int = 0
var current_hat:    int = 0
var current_shirt:  int = 0
var current_pants:  int = 0
var current_shoes:  int = 0
var current_gloves: int = 0

# ============================================
# INICIALIZACIÓN
# ============================================

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_connect_signals()
	label_error.visible = false
	name_input.max_length = 12
	name_input.grab_focus()
	_refresh_all_labels()
	update_all_previews()

# ============================================
# CONSTRUCCIÓN DE UI
# ============================================

func _build_ui():
	add_theme_stylebox_override("panel", _bg_stylebox())

	var outer := MarginContainer.new()
	for s in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		outer.add_theme_constant_override(s, 60)
	add_child(outer)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 40)
	outer.add_child(hbox)

	# --- Izquierda: previews ---
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 12)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(left)

	var title_prev := Label.new()
	title_prev.text = "VISTA PREVIA"
	title_prev.add_theme_font_size_override("font_size", 40)
	left.add_child(title_prev)

	preview_front = _make_preview(left)
	label_front = _make_caption(left, "Vista frontal")
	preview_battle = _make_preview(left)
	label_battle = _make_caption(left, "Batalla")
	preview_walk = _make_preview(left)
	label_walk = _make_caption(left, "Caminando")

	# --- Derecha: opciones ---
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 12)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(right)

	var title_opt := Label.new()
	title_opt.text = "CREA TU PERSONAJE"
	title_opt.add_theme_font_size_override("font_size", 40)
	right.add_child(title_opt)

	# Nombre
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 10)
	var name_title := Label.new()
	name_title.text = "Nombre"
	name_title.custom_minimum_size = Vector2(170, 0)
	name_title.add_theme_font_size_override("font_size", 30)
	name_row.add_child(name_title)
	name_input = LineEdit.new()
	name_input.custom_minimum_size = Vector2(300, 0)
	name_input.add_theme_font_size_override("font_size", 30)
	name_row.add_child(name_input)
	right.add_child(name_row)

	# Filas con flechas
	var r: Dictionary
	r = _make_arrow_row(right, "Género");       btn_gender_left = r.left;     label_gender = r.value;     btn_gender_right = r.right
	r = _make_arrow_row(right, "Tono de piel"); btn_skin_left = r.left;       label_skin = r.value;       btn_skin_right = r.right
	r = _make_arrow_row(right, "Cabello");      btn_hair_style_left = r.left; label_hair_style = r.value; btn_hair_style_right = r.right
	r = _make_arrow_row(right, "Color pelo");   btn_hair_color_left = r.left; label_hair_color = r.value; btn_hair_color_right = r.right
	r = _make_arrow_row(right, "Gorra");        btn_hat_left = r.left;        label_hat = r.value;        btn_hat_right = r.right
	r = _make_arrow_row(right, "Camisa");       btn_shirt_left = r.left;      label_shirt = r.value;      btn_shirt_right = r.right
	r = _make_arrow_row(right, "Pantalón");     btn_pants_left = r.left;      label_pants = r.value;      btn_pants_right = r.right
	r = _make_arrow_row(right, "Zapatos");      btn_shoes_left = r.left;      label_shoes = r.value;      btn_shoes_right = r.right
	r = _make_arrow_row(right, "Guantes");      btn_gloves_left = r.left;     label_gloves = r.value;     btn_gloves_right = r.right

	# Confirmar + error
	btn_confirm = Button.new()
	btn_confirm.text = "Confirmar"
	btn_confirm.add_theme_font_size_override("font_size", 34)
	right.add_child(btn_confirm)

	label_error = Label.new()
	label_error.add_theme_color_override("font_color", Color(1, 0.45, 0.45))
	label_error.add_theme_font_size_override("font_size", 26)
	right.add_child(label_error)

func _make_preview(parent: Node) -> TextureRect:
	var tr := TextureRect.new()
	tr.custom_minimum_size = Vector2(160, 200)
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.visible = false
	parent.add_child(tr)
	return tr

func _make_caption(parent: Node, txt: String) -> Label:
	var l := Label.new()
	l.text = txt
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 30)
	parent.add_child(l)
	return l

func _make_arrow_row(parent: Node, title: String) -> Dictionary:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)

	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.custom_minimum_size = Vector2(150, 0)
	title_lbl.add_theme_font_size_override("font_size", 30)
	row.add_child(title_lbl)

	var left := Button.new()
	left.text = "<"
	left.add_theme_font_size_override("font_size", 30)
	row.add_child(left)

	var value := Label.new()
	value.custom_minimum_size = Vector2(180, 0)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.add_theme_font_size_override("font_size", 30)
	row.add_child(value)

	var right := Button.new()
	right.text = ">"
	right.add_theme_font_size_override("font_size", 30)
	row.add_child(right)

	return {"left": left, "value": value, "right": right}

func _bg_stylebox() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.10, 0.16, 0.97)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(8)
	return sb

# ============================================
# CONEXIÓN DE SEÑALES
# ============================================

func _connect_signals():
	name_input.text_changed.connect(_on_name_changed)

	btn_gender_left.pressed.connect(func(): _cycle("gender", -1))
	btn_gender_right.pressed.connect(func(): _cycle("gender", 1))

	btn_skin_left.pressed.connect(func(): _cycle("skin", -1))
	btn_skin_right.pressed.connect(func(): _cycle("skin", 1))

	btn_hair_style_left.pressed.connect(func(): _cycle("hair_style", -1))
	btn_hair_style_right.pressed.connect(func(): _cycle("hair_style", 1))

	btn_hair_color_left.pressed.connect(func(): _cycle("hair_color", -1))
	btn_hair_color_right.pressed.connect(func(): _cycle("hair_color", 1))

	btn_hat_left.pressed.connect(func(): _cycle("hat", -1))
	btn_hat_right.pressed.connect(func(): _cycle("hat", 1))

	btn_shirt_left.pressed.connect(func(): _cycle("shirt", -1))
	btn_shirt_right.pressed.connect(func(): _cycle("shirt", 1))

	btn_pants_left.pressed.connect(func(): _cycle("pants", -1))
	btn_pants_right.pressed.connect(func(): _cycle("pants", 1))

	btn_shoes_left.pressed.connect(func(): _cycle("shoes", -1))
	btn_shoes_right.pressed.connect(func(): _cycle("shoes", 1))

	btn_gloves_left.pressed.connect(func(): _cycle("gloves", -1))
	btn_gloves_right.pressed.connect(func(): _cycle("gloves", 1))

	btn_confirm.pressed.connect(_on_confirm_pressed)

# ============================================
# CICLO GENÉRICO DE FLECHAS
# ============================================

func _cycle(part: String, direction: int):
	match part:
		"gender":
			current_gender_index = _wrap(current_gender_index + direction, GENDERS.size())
			current_shirt = 0
			current_pants = 0
		"skin":
			current_skin = _wrap(current_skin + direction, SKIN_TONES)
		"hair_style":
			current_hair_style = _wrap(current_hair_style + direction, HAIR_STYLES)
		"hair_color":
			current_hair_color = _wrap(current_hair_color + direction, HAIR_COLORS)
		"hat":
			current_hat = _wrap(current_hat + direction, HATS_COUNT + 1)
		"shirt":
			var count = SHIRTS_BOY if current_gender_index == 0 else SHIRTS_GIRL
			current_shirt = _wrap(current_shirt + direction, count)
		"pants":
			var count = PANTS_BOY if current_gender_index == 0 else PANTS_GIRL
			current_pants = _wrap(current_pants + direction, count)
		"shoes":
			current_shoes = _wrap(current_shoes + direction, SHOES_COUNT)
		"gloves":
			current_gloves = _wrap(current_gloves + direction, GLOVES_COUNT + 1)

	_refresh_all_labels()
	update_all_previews()

func _wrap(value: int, max_value: int) -> int:
	return (value + max_value) % max_value

# ============================================
# LABELS
# ============================================

func _refresh_all_labels():
	label_gender.text     = GENDER_LABELS[current_gender_index]
	label_skin.text       = "%d/%d" % [current_skin + 1, SKIN_TONES]
	label_hair_style.text = "%d/%d" % [current_hair_style + 1, HAIR_STYLES]
	label_hair_color.text = HAIR_COLOR_NAMES[current_hair_color]

	label_hat.text = "Ninguna" if current_hat == 0 else "%d/%d" % [current_hat, HATS_COUNT]

	var shirt_count = SHIRTS_BOY if current_gender_index == 0 else SHIRTS_GIRL
	label_shirt.text = "%d/%d" % [current_shirt + 1, shirt_count]

	var pants_count = PANTS_BOY if current_gender_index == 0 else PANTS_GIRL
	label_pants.text = "%d/%d" % [current_pants + 1, pants_count]

	label_shoes.text = "%d/%d" % [current_shoes + 1, SHOES_COUNT]

	label_gloves.text = "Ninguno" if current_gloves == 0 else "%d/%d" % [current_gloves, GLOVES_COUNT]

# ============================================
# PREVIEWS
# ============================================

func update_all_previews():
	var gender = GENDERS[current_gender_index]
	_update_preview(preview_front,  gender, "front")
	_update_preview(preview_battle, gender, "battle")
	_update_preview(preview_walk,   gender, "walk")

func _update_preview(node: TextureRect, gender: String, preview_type: String):
	var path = (
		"%s%s/preview/skin_%d_hair_%d_%d_hat_%d_shirt_%d_pants_%d_shoes_%d_gloves_%d_%s.png"
		% [
			SPRITE_BASE, gender,
			current_skin, current_hair_style, current_hair_color,
			current_hat, current_shirt, current_pants, current_shoes, current_gloves,
			preview_type
		]
	)

	if ResourceLoader.exists(path):
		node.texture = load(path)
		node.visible = true
	else:
		var fallback = "%s%s/preview/default_%s.png" % [SPRITE_BASE, gender, preview_type]
		if ResourceLoader.exists(fallback):
			node.texture = load(fallback)
			node.visible = true
		else:
			node.visible = false

# ============================================
# CONFIRMACIÓN
# ============================================

func _on_confirm_pressed():
	var player_name = name_input.text.strip_edges()
	if not _validate_name(player_name):
		return

	emit_signal("creation_confirmed", {
		"name":       player_name,
		"gender":     GENDERS[current_gender_index],
		"skin_tone":  current_skin,
		"hair_style": current_hair_style,
		"hair_color": current_hair_color,
		"hat":        current_hat,
		"shirt":      current_shirt,
		"pants":      current_pants,
		"shoes":      current_shoes,
		"gloves":     current_gloves,
	})

func _validate_name(player_name: String) -> bool:
	if player_name.length() < 1:
		_show_error("Debes ingresar un nombre.")
		return false
	if player_name.length() > 12:
		_show_error("El nombre es demasiado largo (máx. 12).")
		return false
	return true

func _show_error(message: String):
	label_error.text    = message
	label_error.visible = true

func _on_name_changed(_text: String):
	label_error.visible = false
