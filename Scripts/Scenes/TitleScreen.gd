# ============================================
# TitleScreen.gd
# Pantalla de título principal
# ============================================
extends Control

@onready var press_start = $VBoxContainer/PressStart
@onready var copyright = $Copyright
@onready var logo = $VBoxContainer/Logo
@onready var version_label: Label = $VersionLabel

const MAIN_MENU_SCENE = preload("res://Scenes/menus/MainMenu.tscn")

var can_press: bool = false
var blink_timer: float = 0.0
var menu_open: bool = false


func _ready():
	press_start.modulate.a = 0.0
	# Versión del juego
	version_label.text = "v" + ProjectSettings.get_setting("application/config/version", "0.1")
	 
	await ScreenFade.fade_in()

	# Pequeño fade in del press start al aparecer
	await get_tree().create_timer(0.5).timeout
	can_press = true

func _process(delta):
	# Efecto de parpadeo en "Presiona START"
	if can_press and not menu_open:
		blink_timer += delta * 2.0
		press_start.modulate.a = (sin(blink_timer) + 1.0) / 2.0

func _input(event):
	if not can_press or menu_open:
		return
	if event.is_action_pressed("ui_accept") or \
	   event.is_action_pressed("ui_select"):
		_open_main_menu()

# ============================================
# ABRIR MENÚ PRINCIPAL
# ============================================

func _open_main_menu():
	can_press  = false
	menu_open  = true
	AudioManager.play_sfx("menu_select")

	# Fade out del PressStart
	var tween = create_tween()
	tween.tween_property(press_start, "modulate:a", 0.0, 0.3)
	await tween.finished

	# Instanciar y añadir MainMenu encima de todo
	var main_menu = MAIN_MENU_SCENE.instantiate()
	add_child(main_menu)
