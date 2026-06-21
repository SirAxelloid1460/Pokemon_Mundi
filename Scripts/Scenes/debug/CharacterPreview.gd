extends Node2D
# Previsualización del personaje compuesto por capas (CharacterCompositor).
# Ejecuta esta escena (F6).  ←/→ cambia animación · ↑/↓ cambia orientación.

const ANIMS := ["idle", "walk", "run"]
const FACINGS := ["down", "left", "up", "right"]

var _char: CharacterCompositor
var _label: Label
var _ai: int = 0
var _fi: int = 0

func _ready():
	var bg := ColorRect.new()
	bg.color = Color(0.16, 0.18, 0.22)
	bg.size = Vector2(1280, 720)
	bg.z_index = -10
	add_child(bg)

	_char = CharacterCompositor.new()
	add_child(_char)
	_char.position = Vector2(640, 360)
	_char.scale = Vector2(8, 8)

	_label = Label.new()
	_label.position = Vector2(24, 20)
	_label.add_theme_font_size_override("font_size", 24)
	add_child(_label)

	_apply()

func _apply():
	_char.set_pose(ANIMS[_ai], FACINGS[_fi])
	# set_pose ajusta scale.x para el flip; reescalamos manteniendo el zoom
	_char.scale = Vector2(8 * signf(_char.scale.x), 8)
	_label.text = "anim: %s   facing: %s   variante: %d   (←/→ anim · ↑/↓ orient. · Enter variante)" % [ANIMS[_ai], FACINGS[_fi], _char.variant]

func _unhandled_input(event):
	if event.is_action_pressed("ui_right"):
		_ai = (_ai + 1) % ANIMS.size(); _apply()
	elif event.is_action_pressed("ui_left"):
		_ai = (_ai - 1 + ANIMS.size()) % ANIMS.size(); _apply()
	elif event.is_action_pressed("ui_down"):
		_fi = (_fi + 1) % FACINGS.size(); _apply()
	elif event.is_action_pressed("ui_up"):
		_fi = (_fi - 1 + FACINGS.size()) % FACINGS.size(); _apply()
	elif event.is_action_pressed("ui_accept"):
		_char.set_variant(_char.variant + 1); _apply()
