class_name CharacterCompositor
extends Node2D
# Construye el personaje principal por CAPAS (paper-doll) desde los atlas de partes,
# en vez de un único spritesheet pre-hecho (PJ_movement.png).
#
# Estructura de assets:
#   res://Assets/Sprites/MainCharacter/atlas/{anim}/{dir}/{parte}[/lado]/1.png
#     anim  = idle | walk | run
#     dir   = down | up | sideways      (left/right = sideways con flip horizontal)
#     parte = head, hair, chest, arms, hands, legs, feet
#     lado  = left/right (down,up)  |  upper/lower (sideways)  |  (sin lado: chest, hair, head)
#   Cada PNG es una rejilla de 32x36: COLUMNAS = frames de animación, FILAS = variantes
#   (las partes móviles traen varias variantes; chest/hair traen 1). 'variant' elige la fila.
#
# WIP / por confirmar con el autor de los assets:
#   - Orden z definitivo y, en 'sideways', el z por lado (brazo lejano detrás del torso,
#     cercano delante) — hoy el orden es plano por parte.
#   - Recolor de piel/pelo (palette_swap) y variantes de ropa: aún no (sólo capas base).

const ATLAS := "res://Assets/Sprites/MainCharacter/atlas"
const FRAME := Vector2i(32, 36)        # tamaño de frame (ancho confirmado = 32)
const DEFAULT_FPS := 8.0

var variant: int = 0                   # fila a usar (variante) en partes con varias filas

# Orden z (atrás → adelante) por dirección.
const Z_ORDER := {
	"down":     ["legs", "feet", "chest", "arms", "hands", "head", "hair"],
	"up":       ["hair", "head", "legs", "feet", "chest", "arms", "hands"],
	"sideways": ["legs", "feet", "chest", "arms", "hands", "head", "hair"],
}
# Orden de lados dentro de una parte (el primero queda detrás).
const SIDE_ORDER := ["upper", "left", "right", "lower"]

var _layers: Array[AnimatedSprite2D] = []
var _anim := "idle"
var _dir := "down"
var fps := DEFAULT_FPS

# Pose pública: facing ∈ {down, up, left, right}; anim ∈ {idle, walk, run}.
func set_pose(anim: String, facing: String) -> void:
	_anim = anim
	var flip := facing == "left"
	_dir = "sideways" if facing in ["left", "right"] else facing
	_rebuild()
	scale.x = -1.0 if flip else 1.0

func _rebuild() -> void:
	for l in _layers:
		l.queue_free()
	_layers.clear()
	var dir_path := "%s/%s/%s" % [ATLAS, _anim, _dir]
	var order: Array = Z_ORDER.get(_dir, [])
	for part in order:
		for layer_path in _part_layers("%s/%s" % [dir_path, part]):
			var spr := _make_layer(layer_path)
			if spr:
				add_child(spr)
				_layers.append(spr)
	play()

# Devuelve las rutas de PNG de una parte: su propio 1.png, o el de cada lado, ordenados.
func _part_layers(part_path: String) -> Array:
	var out: Array = []
	if ResourceLoader.exists(part_path + "/1.png"):
		out.append(part_path + "/1.png")
		return out
	var sides := []
	for s in SIDE_ORDER:
		if ResourceLoader.exists("%s/%s/1.png" % [part_path, s]):
			sides.append("%s/%s/1.png" % [part_path, s])
	return sides

func _make_layer(png_path: String) -> AnimatedSprite2D:
	var tex: Texture2D = load(png_path)
	if tex == null:
		return null
	var frames := _slice(tex)
	if frames.is_empty():
		return null
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	sf.add_animation("default")
	sf.set_animation_speed("default", fps)
	sf.set_animation_loop("default", true)
	for at in frames:
		sf.add_frame("default", at)
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = sf
	spr.centered = false
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return spr

# Corta una rejilla: columnas = frames, fila = la variante elegida.
func _slice(tex: Texture2D) -> Array:
	var cols := maxi(1, int(tex.get_width()) / FRAME.x)    # columnas = frames
	var rows := maxi(1, int(tex.get_height()) / FRAME.y)   # filas = variantes
	var row := clampi(variant, 0, rows - 1)
	var out: Array = []
	for c in range(cols):
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(c * FRAME.x, row * FRAME.y, FRAME.x, FRAME.y)
		out.append(at)
	return out

func set_variant(v: int) -> void:
	variant = v
	_rebuild()

func play() -> void:
	for l in _layers:
		l.play("default")
