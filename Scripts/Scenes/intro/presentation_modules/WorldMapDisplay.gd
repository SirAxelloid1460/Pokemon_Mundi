extends Node2D
# Mapa del mundo de la presentación: resalta regiones (caja desde data/region_areas.json)
# y expone el rect de pantalla de cada una para reubicar el textbox.

const MAP_CANDIDATES := [
	"res://Assets/Mapas_Regionales/pokemon_world_2.png",
	"res://Assets/Mapas_Regionales/Pokemon World.webp",
]
const AREAS_PATH := "res://data/region_areas.json"
const HighlightScript := preload("res://Scripts/Scenes/intro/presentation_modules/RegionHighlight.gd")

var map_sprite: Sprite2D
var region_overlays: Node2D
var animation_player: AnimationPlayer
var _highlight

var regions: Dictionary = {}
var current_highlighted_region: String = ""

var _areas: Dictionary = {}       # nombre -> Rect2 (px del mapa)
var _map_scale: float = 1.0
var _map_origin: Vector2 = Vector2.ZERO

func _ready():
	_load_areas()
	_build()

func _load_areas():
	if not FileAccess.file_exists(AREAS_PATH):
		return
	var f := FileAccess.open(AREAS_PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		return
	for rname in data:
		var r = data[rname]
		if r is Dictionary:
			_areas[rname] = Rect2(float(r.get("x", 0)), float(r.get("y", 0)), float(r.get("w", 0)), float(r.get("h", 0)))

func _build():
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.05, 0.06, 0.09)
	backdrop.position = Vector2.ZERO
	backdrop.size = Vector2(1280, 720)
	add_child(backdrop)

	map_sprite = Sprite2D.new()
	add_child(map_sprite)
	var tex = _load_first_existing(MAP_CANDIDATES)
	if tex:
		map_sprite.texture = tex
		map_sprite.position = Vector2(640, 360)
		var sz = tex.get_size()
		if sz.x > 0 and sz.y > 0:
			_map_scale = min(1280.0 / sz.x, 720.0 / sz.y)
			map_sprite.scale = Vector2(_map_scale, _map_scale)
			_map_origin = Vector2((1280.0 - sz.x * _map_scale) * 0.5, (720.0 - sz.y * _map_scale) * 0.5)

	region_overlays = Node2D.new()
	add_child(region_overlays)

	_highlight = HighlightScript.new()
	add_child(_highlight)

	animation_player = AnimationPlayer.new()
	add_child(animation_player)

func _load_first_existing(paths: Array):
	for p in paths:
		if ResourceLoader.exists(p):
			return load(p)
	return null

# ============================================
# CONVERSIÓN Y API
# ============================================

func _map_to_screen(r: Rect2) -> Rect2:
	return Rect2(_map_origin + r.position * _map_scale, r.size * _map_scale)

func get_region_screen_rect(region_name: String) -> Rect2:
	if _areas.has(region_name):
		return _map_to_screen(_areas[region_name])
	return Rect2()

func highlight_region(region_name: String, _duration: float = 0.5):
	# Sólo parpadea la caja de la región; el nombre va en el diálogo, no sobre el mapa.
	current_highlighted_region = region_name
	var srect := get_region_screen_rect(region_name)
	if _highlight:
		if srect.size.x > 0.0:
			_highlight.show_rect(srect)
		else:
			_highlight.hide_rect()

func clear_all_highlights(_duration: float = 0.5):
	current_highlighted_region = ""
	if _highlight:
		_highlight.hide_rect()

# ============================================
# COMPATIBILIDAD
# ============================================

func fade_out_region(_region_name: String, _duration: float = 0.3):
	pass

func start_pulse_effect(_region_overlay):
	pass

func show_full_map():
	clear_all_highlights()
	if map_sprite:
		map_sprite.modulate.a = 1.0

func hide_map(duration: float = 0.5):
	clear_all_highlights()
	if map_sprite:
		var tween := create_tween()
		tween.tween_property(map_sprite, "modulate:a", 0.0, duration)
