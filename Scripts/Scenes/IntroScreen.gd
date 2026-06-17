# ============================================
# IntroScreen.gd
# Pantalla de intro con video skipeable
# ============================================
extends Control
 
@onready var video_player: VideoStreamPlayer = $CanvasLayer/VideoPlayer
@onready var background: ColorRect = $Background
 
const NEXT_SCENE = "res://Scenes/TitleScreen.tscn"
const VIDEO_BASE = "res://Assets/Videos/"
 
# ============================================
# LOCALIZACIÓN → VIDEO
# ============================================

const VIDEO_MAP: Dictionary = {
	"es_LA": "intro_es_LA.ogv",
	"es_ES": "intro_es_ES.ogv",
	"en": "intro_en.ogv",
	"fr": "intro_fr.ogv",
	"de": "intro_de.ogv",
	"it": "intro_it.ogv",
	"pt": "intro_pt.ogv",
	"ja": "intro_ja.ogv",
}
const VIDEO_FALLBACK = "intro_en.ogv"

# Separado de skippable para que _on_video_finished
# siempre pueda hacer la transición independientemente
var is_transitioning: bool = false

var skippable: bool = false
 
# ============================================
# INICIALIZACIÓN
# ============================================
 
func _ready():
	background.color = Color.BLACK
	ScreenFade.set_black()

	if not _load_video_for_language():
		return

	video_player.finished.connect(_on_video_finished)
	
	# Iniciar video en paralelo con el fade in
	video_player.play()
	
	await ScreenFade.fade_in()
 
	# Ajustar tamaño del VideoPlayer al primer frame disponible
	await get_tree().process_frame
	await get_tree().process_frame
	_fit_video_letterbox()
 
	skippable = true
	await get_tree().create_timer(1.0).timeout
 
# ============================================
# CARGA DE VIDEO POR IDIOMA
# ============================================
 
func _load_video_for_language() -> bool:
	var locale = LocalizationManager.get_current_language()
	var lang_short = locale.substr(0, 2)
	var candidates = [locale, lang_short]

	var video_file = ""
 
	for candidate in candidates:
		if VIDEO_MAP.has(candidate):
			var path = VIDEO_BASE + VIDEO_MAP[candidate]
			if ResourceLoader.exists(path):
				video_file = path
				break
 
	if video_file == "":
		# Último recurso: fallback directo
		var fallback_path = VIDEO_BASE + VIDEO_FALLBACK
		if ResourceLoader.exists(fallback_path):
			video_file = fallback_path
		else:
			push_error("IntroScreen: No se encontró ningún video de intro.")
			_go_to_title()
			return false
 
	video_player.stream = load(video_file)
	return true
 
# ============================================
# LETTERBOX — ajuste de tamaño y posición
# ============================================
 
func _fit_video_letterbox():
	#Centra el video manteniendo su aspect ratio original.
	#Las barras negras las provee el Background negro de fondo.
	var tex = video_player.get_video_texture()
 
	if tex and tex.get_width() > 0 and tex.get_height() > 0:
		_apply_letterbox(Vector2(tex.get_width(), tex.get_height()))
	else:
		# Fallback: usar tamaño conocido del video si la textura aún no está lista
		_apply_letterbox(Vector2(640, 360))
 
func _apply_letterbox(video_size: Vector2):
	#Calcula y aplica el tamaño/posición del VideoPlayer para letterbox.
	var screen_size = get_viewport_rect().size
	var video_ratio  = video_size.x / video_size.y
	var screen_ratio = screen_size.x / screen_size.y
 
	var final_size: Vector2
 
	if video_ratio > screen_ratio:
		# Video más ancho que la pantalla → barras arriba y abajo (letterbox)
		final_size = Vector2(screen_size.x, screen_size.x / video_ratio)
	else:
		# Video más alto que la pantalla → barras a los lados (pillarbox)
		final_size = Vector2(screen_size.y * video_ratio, screen_size.y)
 
	# Centrar en pantalla
	video_player.size = final_size
	video_player.position = (screen_size - final_size) / 2.0
 
# ============================================
# INPUT — skip
# ============================================
 
func _input(event):
	if not skippable:
		return
	if event.is_action_pressed("ui_accept") or \
	   event.is_action_pressed("ui_select") or \
	   event.is_action_pressed("ui_cancel"):
		_go_to_title()
 
# ============================================
# FIN DEL VIDEO Y TRANSICIÓN
# ============================================
 
func _on_video_finished():
	# El video terminó — hacer transición independientemente de skippable
	_go_to_title()
 
func _go_to_title():
	# Evitar doble llamadaprint("_go_to_title llamado, is_transitioning: ", is_transitioning)
	if is_transitioning:
		return
	is_transitioning = true
	skippable = false
	video_player.stop()
	await ScreenFade.fade_out()
	get_tree().change_scene_to_file(NEXT_SCENE)
 
