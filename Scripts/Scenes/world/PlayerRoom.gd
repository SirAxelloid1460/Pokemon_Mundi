extends Node2D
# Habitación inicial: primer mundo tras la presentación del profesor.
# Construye suelo, paredes con colisión, jugador, cámara y el menú de campo por código.

const PLAYER_SCENE := preload("res://Scenes/Player.tscn")
const TEXTBOX_SCENE := preload("res://Scenes/ui/TextBox.tscn")

const ROOM := Rect2(0, 0, 640, 448)
const SPAWN := Vector2(320, 256)
const SIGN_POS := Vector2(320, 96)

const FLOOR_COLOR := Color(0.36, 0.55, 0.36)
const WALL_COLOR := Color(0.20, 0.28, 0.20)
const GRID_COLOR := Color(1, 1, 1, 0.05)
const BACKDROP_COLOR := Color(0.06, 0.07, 0.10)

var player: CharacterBody2D
var menu: GameMenu
var _textbox = null
var _dialogue_active := false

func _ready():
	add_to_group("overworld")
	Game.GameData.active_scene = scene_file_path
	_build_walls()
	_spawn_player()
	_setup_camera()
	_setup_menu()
	_setup_hud()
	queue_redraw()
	AudioManager.play_music("lab")   # no-op si la pista no existe aún
	await ScreenFade.fade_in()

# ============================================
# CONSTRUCCIÓN DEL MUNDO
# ============================================

func _build_walls():
	var body := StaticBody2D.new()
	add_child(body)
	var defs := [
		Rect2(0, 0, ROOM.size.x, 16),                  # arriba
		Rect2(0, ROOM.size.y - 16, ROOM.size.x, 16),   # abajo
		Rect2(0, 0, 16, ROOM.size.y),                  # izquierda
		Rect2(ROOM.size.x - 16, 0, 16, ROOM.size.y),   # derecha
	]
	for r in defs:
		var cs := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = r.size
		cs.shape = shape
		cs.position = r.position + r.size / 2.0
		body.add_child(cs)

func _spawn_player():
	player = PLAYER_SCENE.instantiate()
	player.position = SPAWN
	add_child(player)

func _setup_camera():
	var cam := Camera2D.new()
	cam.zoom = Vector2(3, 3)                 # acercar la cámara (antes se veía "desde el espacio")
	cam.position_smoothing_enabled = false   # sin retraso: la cámara va pegada al jugador
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(ROOM.size.x)
	cam.limit_bottom = int(ROOM.size.y)
	player.add_child(cam)                    # sigue al jugador
	cam.make_current()

func _setup_menu():
	menu = GameMenu.new()
	add_child(menu)

func _setup_hud():
	var hud := CanvasLayer.new()
	hud.layer = 10
	add_child(hud)
	var hint := Label.new()
	hint.text = "Flechas: moverte    ·    ESC: menú    ·    Enter: interactuar"
	hint.add_theme_font_size_override("font_size", 22)
	hint.add_theme_color_override("font_color", Color.WHITE)
	hint.add_theme_color_override("font_outline_color", Color.BLACK)
	hint.add_theme_constant_override("outline_size", 6)
	hint.position = Vector2(24, 16)
	hud.add_child(hint)

# ============================================
# DIBUJO
# ============================================

func _draw():
	draw_rect(Rect2(-400, -240, 1440, 960), BACKDROP_COLOR, true)
	draw_rect(ROOM, FLOOR_COLOR, true)

	var x := 0.0
	while x <= ROOM.size.x:
		draw_line(Vector2(x, 0), Vector2(x, ROOM.size.y), GRID_COLOR, 1.0)
		x += 32.0
	var y := 0.0
	while y <= ROOM.size.y:
		draw_line(Vector2(0, y), Vector2(ROOM.size.x, y), GRID_COLOR, 1.0)
		y += 32.0

	draw_rect(ROOM, WALL_COLOR, false, 6.0)

	var sign_rect := Rect2(SIGN_POS.x - 18, SIGN_POS.y - 14, 36, 28)
	draw_rect(sign_rect, Color(0.45, 0.30, 0.16), true)
	draw_rect(sign_rect, Color(0.25, 0.16, 0.08), false, 3.0)

# ============================================
# INTERACCIÓN
# ============================================

func _unhandled_input(event: InputEvent):
	if _dialogue_active:
		return
	if menu and menu.state != GameMenu.State.CLOSED:
		return
	if event.is_action_pressed("ui_accept"):
		if player and not player.is_moving and player.position.distance_to(SIGN_POS) <= 56.0:
			_show_sign()

func _show_sign():
	_dialogue_active = true
	if player:
		player.lock_input()
	if _textbox == null:
		var layer := CanvasLayer.new()
		layer.layer = 90
		add_child(layer)
		_textbox = TEXTBOX_SCENE.instantiate()
		_textbox.position = Vector2(280, 560)
		layer.add_child(_textbox)
		_textbox.dialogue_finished.connect(_on_sign_done)
	_textbox.show_dialogue([
		"CARTEL: ¡Bienvenido a Pokémon Mundi!",
		"Tu aventura comienza aquí.",
		"Pulsa ESC para abrir el menú cuando quieras.",
	])

func _on_sign_done():
	_dialogue_active = false
	if player:
		player.unlock_input()

func is_menu_blocked() -> bool:
	#El menú de campo no debe abrirse mientras hay un diálogo activo.
	return _dialogue_active
