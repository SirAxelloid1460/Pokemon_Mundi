extends Node2D
# Herramienta para definir las áreas de cada región sobre el mapa.
# Ejecuta esta escena (F6).
#   · Arrastra con el ratón para dibujar la caja de la región ACTUAL.
#   · ←/→ : cambiar de región      · Enter : confirmar y siguiente
#   · Backspace : borrar la caja actual    · S : guardar JSON (user:// + consola)
# Copia el JSON impreso a res://data/region_areas.json

const MAP_CANDIDATES := [
	"res://Assets/Mapas_Regionales/pokemon_world_2.png",
	"res://Assets/Mapas_Regionales/Pokemon World.webp",
]
const REGIONS := ["Kanto", "Johto", "Hoenn", "Sinnoh", "Unova", "Kalos", "Alola", "Galar", "Paldea", "Almia", "Oblivia", "Fiore"]
const OUT_PATH := "user://region_areas.json"

var _scale: float = 1.0
var _origin: Vector2 = Vector2.ZERO
var _index: int = 0
var _areas: Dictionary = {}        # nombre -> Rect2 (px del mapa)
var _dragging: bool = false
var _drag_start: Vector2 = Vector2.ZERO
var _drag_cur: Vector2 = Vector2.ZERO
var _label: Label

func _ready():
	var tex = _load_first_existing(MAP_CANDIDATES)
	if tex == null:
		push_error("RegionMapper: no se encontró el mapa.")
		return
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.position = Vector2(640, 360)
	var sz = tex.get_size()
	_scale = min(1280.0 / sz.x, 720.0 / sz.y)
	spr.scale = Vector2(_scale, _scale)
	_origin = Vector2((1280.0 - sz.x * _scale) * 0.5, (720.0 - sz.y * _scale) * 0.5)
	add_child(spr)

	_load_existing()

	_label = Label.new()
	_label.position = Vector2(16, 12)
	_label.add_theme_font_size_override("font_size", 22)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 5)
	add_child(_label)
	_update_label()

func _load_existing():
	# carga las cajas ya definidas (si existen) para poder retocarlas
	var path := "res://data/region_areas.json"
	if not FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		return
	for k in data:
		var r = data[k]
		if r is Dictionary and float(r.get("w", 0)) > 0.0:
			_areas[k] = Rect2(float(r.get("x", 0)), float(r.get("y", 0)), float(r.get("w", 0)), float(r.get("h", 0)))

func _load_first_existing(paths: Array):
	for p in paths:
		if ResourceLoader.exists(p):
			return load(p)
	return null

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_drag_start = event.position
			_drag_cur = event.position
		else:
			_dragging = false
			_commit_drag()
		queue_redraw()
	elif event is InputEventMouseMotion and _dragging:
		_drag_cur = event.position
		queue_redraw()
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_RIGHT, KEY_ENTER:
				_index = (_index + 1) % REGIONS.size()
			KEY_LEFT:
				_index = (_index - 1 + REGIONS.size()) % REGIONS.size()
			KEY_BACKSPACE:
				_areas.erase(REGIONS[_index])
			KEY_S:
				_save()
		_update_label()
		queue_redraw()

func _commit_drag():
	var r_screen := Rect2(_drag_start, _drag_cur - _drag_start).abs()
	if r_screen.size.x < 4.0 or r_screen.size.y < 4.0:
		return
	var pos_map := (r_screen.position - _origin) / _scale
	var size_map := r_screen.size / _scale
	_areas[REGIONS[_index]] = Rect2(pos_map, size_map)

func _save():
	var d := {}
	for k in _areas:
		var r: Rect2 = _areas[k]
		d[k] = {"x": int(round(r.position.x)), "y": int(round(r.position.y)), "w": int(round(r.size.x)), "h": int(round(r.size.y))}
	var txt := JSON.stringify(d, "\t")
	var f := FileAccess.open(OUT_PATH, FileAccess.WRITE)
	if f:
		f.store_string(txt)
		f.close()
	print("\n===== region_areas.json (cópialo a res://data/region_areas.json) =====")
	print(txt)
	print("También guardado en: ", ProjectSettings.globalize_path(OUT_PATH), "\n")

func _update_label():
	_label.text = "Región: %s  (%d/%d)   ·   Definidas: %d/%d\nArrastra para dibujar · ←/→ región · Enter siguiente · Backspace borra · S guarda" % [
		REGIONS[_index], _index + 1, REGIONS.size(), _areas.size(), REGIONS.size()]

func _draw():
	for k in _areas:
		var a: Rect2 = _areas[k]
		var sr := Rect2(_origin + a.position * _scale, a.size * _scale)
		var is_cur: bool = k == REGIONS[_index]
		var c := Color(1.0, 0.9, 0.3) if is_cur else Color(0.3, 0.9, 0.55)
		draw_rect(sr, Color(c.r, c.g, c.b, 0.12), true)
		draw_rect(sr, c, false, 2.0)
	if _dragging:
		var r := Rect2(_drag_start, _drag_cur - _drag_start).abs()
		draw_rect(r, Color(1.0, 0.9, 0.3, 0.15), true)
		draw_rect(r, Color(1.0, 0.9, 0.3, 1.0), false, 2.0)
