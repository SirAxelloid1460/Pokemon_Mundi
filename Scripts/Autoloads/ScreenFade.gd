# ============================================
# ScreenFade.gd (Autoload/Singleton)
# Fade global reutilizable entre escenas
# Ubicación: res://Scripts/Autoloads/ScreenFade.gd
#
# USO:
#   await ScreenFade.fade_out()
#   get_tree().change_scene_to_file("res://Scenes/...")
#   await ScreenFade.fade_in()
#
#   # Con opciones:
#   await ScreenFade.fade_out(1.0, Color.WHITE)
#   await ScreenFade.fade_out(0.3, Color.BLACK, preload("res://Assets/Sprites/fade_texture.png"))
# ============================================
extends Node
 
const DEFAULT_DURATION = 0.5
const DEFAULT_COLOR = Color.BLACK
 
# Usamos TextureRect siempre — soporta color (via modulate) y textura
var _canvas_layer: CanvasLayer
var _rect: ColorRect
var _tween: Tween
 
# ============================================
# INICIALIZACIÓN
# ============================================
 
func _ready():
	# Crear CanvasLayer como hijo y añadirlo al root
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 200
	_canvas_layer.name = "ScreenFadeLayer"
	get_tree().root.call_deferred("add_child", _canvas_layer)
	await get_tree().process_frame

	# Crear ColorRect dentro del CanvasLayer
	_rect = ColorRect.new()
	_rect.color = DEFAULT_COLOR
	_rect.color.a = 0.0
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.anchors_preset = Control.PRESET_FULL_RECT
	_rect.name = "FadeRect"
	_canvas_layer.add_child(_rect)
 
	await get_tree().process_frame

	# Ajustar tamaño al viewport después de añadirlo al árbol
	_fit_rect_to_viewport()
	get_tree().root.size_changed.connect(_fit_rect_to_viewport)

func _fit_rect_to_viewport():
	#Ajusta el rect al tamaño actual del viewport.
	var vp_size = get_tree().root.get_visible_rect().size
	_rect.position = Vector2.ZERO
	_rect.size = vp_size

# ============================================
# API PÚBLICA
# ============================================
 
func fade_out(duration: float = DEFAULT_DURATION,
			  color: Color = DEFAULT_COLOR,
			  texture: Texture2D = null) -> void:

	#Oscurece la pantalla. Awaitable.
	_rect.color = color
	await _animate(0.0, 1.0, duration)
 
func fade_in(duration: float = DEFAULT_DURATION,
			  color: Color = DEFAULT_COLOR,
			  texture: Texture2D = null) -> void:

	#Aclara la pantalla. Awaitable.
	if not _rect:
		await get_tree().process_frame
		await get_tree().process_frame

	_rect.color = color
	await _animate(1.0, 0.0, duration)
 
func fade_to_scene(scene_path: String,
				   duration: float = DEFAULT_DURATION,
				   color: Color = DEFAULT_COLOR) -> void:
	#Fade out → cambia escena → fade in en una sola llamada.
	await fade_out(duration, color)
	get_tree().change_scene_to_file(scene_path)
	await fade_in(duration, color)
 
func flash(duration: float = 0.2, color: Color = Color.WHITE) -> void:
	#Flash rápido de color (útil para golpes, capturas, etc.)
	_rect.color = color
	await _animate(0.0, 1.0, duration * 0.3)
	await _animate(1.0, 0.0, duration * 0.7)
 
func set_black() -> void:
	#Pone la pantalla en negro instantáneamente.
	if not _rect:
		await get_tree().process_frame
		await get_tree().process_frame

	_rect.color = DEFAULT_COLOR
	_rect.color.a = 1.0
 
func clear() -> void:
	#Limpia el fade instantáneamente.
	if not _rect:
		await get_tree().process_frame
		await get_tree().process_frame

	_rect.color.a = 0.0
 
# ============================================
# INTERNOS
# ============================================
func _animate(from: float, to: float, duration: float) -> void:

	if _tween:
		_tween.kill()
		_tween = null

	_rect.color.a = from

	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.tween_property(_rect, "color:a", to, duration)
	await _tween.finished
