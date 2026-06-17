extends CharacterBody2D
# Movimiento por casillas (estilo Pokémon): un tile a la vez, con colisión y animación.

const TILE_SIZE := 32
const MOVE_TIME := 0.25   # segundos por casilla (también dura la animación de paso)

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var is_moving := false
var input_locked := false
var facing := "down"
var _step_parity := 0   # alterna pie izquierdo/derecho en cada paso

# Frame de reposo por dirección (fila 0 de cada bloque del spritesheet PJ_movement)
const IDLE_FRAME := {"down": 0, "up": 17, "left": 34, "right": 51}
const DIR_VEC := {"down": Vector2.DOWN, "up": Vector2.UP, "left": Vector2.LEFT, "right": Vector2.RIGHT}

func _ready():
	_set_idle_frame()

func _physics_process(_delta: float) -> void:
	if is_moving or input_locked:
		return
	var dir := _read_input_dir()
	if dir == "":
		return
	facing = dir
	var motion: Vector2 = DIR_VEC[dir] * TILE_SIZE
	if test_move(global_transform, motion):
		_set_idle_frame()   # mira hacia la pared pero no avanza
		return
	_step(dir, motion)

func _read_input_dir() -> String:
	if Input.is_action_pressed("ui_down"):  return "down"
	if Input.is_action_pressed("ui_up"):    return "up"
	if Input.is_action_pressed("ui_left"):  return "left"
	if Input.is_action_pressed("ui_right"): return "right"
	return ""

func _step(dir: String, motion: Vector2) -> void:
	is_moving = true
	var anim := "walk_" + dir
	var a := animation_player.get_animation(anim)
	var anim_len: float = a.length if a else 0.8
	var half := anim_len * 0.5
	animation_player.speed_scale = half / MOVE_TIME       # una zancada (medio ciclo) por casilla
	animation_player.play(anim)
	animation_player.seek(_step_parity * half, true)      # alterna pie izquierdo/derecho
	_step_parity = 1 - _step_parity
	var tween := create_tween()
	tween.tween_property(self, "position", position + motion, MOVE_TIME)
	await tween.finished
	is_moving = false
	if _read_input_dir() == "":
		_stop_anim()

func _stop_anim() -> void:
	animation_player.stop()
	animation_player.speed_scale = 1.0
	_set_idle_frame()

func _set_idle_frame() -> void:
	sprite.frame = IDLE_FRAME[facing]

func lock_input() -> void:
	input_locked = true

func unlock_input() -> void:
	input_locked = false
