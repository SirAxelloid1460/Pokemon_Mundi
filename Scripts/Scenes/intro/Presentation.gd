# ============================================
# Presentation.gd
# Secuencia completa de introducción del juego
# ============================================
extends Control

# ============================================
# SEÑALES
# ============================================

signal presentation_complete

# ============================================
# REFERENCIAS A NODOS
# ============================================

@onready var textbox : NinePatchRect = $Textbox
@onready var professor_sprite = $ProfArangurenMain
@onready var content_container = $ContentContainer
@onready var animation_player = $AnimationPlayer
@onready var initial_notes_panel = $InitialNotesPanel  # Panel con notas para el jugador
@onready var continue_button: Button = $ContinueButton

# ============================================
# ESCENAS MODULARES
# ============================================

const WORLD_MAP_SCENE = preload("res://Scenes/intro/presentation_modules/WorldMapDisplay.tscn")
const PLAYER_CREATION_SCENE = preload("res://Scenes/intro/presentation_modules/PlayerCreationPanel.tscn")

# ============================================
# ESTADOS DE LA PRESENTACIÓN
# ============================================

enum PresentationState {
	INITIAL_NOTES,          # Notas iniciales al jugador
	GREETING,               # Saludo del profesor
	PLAYER_INFO,            # Nombre, género, apariencia
	WORLD_PRESENTATION,     # Mapa del mundo y explicación
	WORLD_OUTRO,            # Discurso del profesor tras el mapa
	FAREWELL,              # Despedida del profesor
	FINISHED               # Completado
}

var current_state = PresentationState.INITIAL_NOTES
var current_module = null

# ============================================
# DATOS DEL JUGADOR
# ============================================

var player_data = {
	"name": "",
	"gender": "",
	"skin_tone": 0,
	"hair_style": 0,
	"hair_color": 0,
	"hat":        0,   # 0 = sin gorra
	"shirt":      0,
	"pants":      0,
	"shoes":      0,
	"gloves":     0,   # 0 = sin guantes
}

# ============================================
# DATOS DEL MAPA MUNDIAL
# ============================================

var world_dialogue_sequence = [
	{"text": "Este vasto mundo está dividido en múltiples regiones.", "region": ""},
	{"text": "Al norte se alza SINNOH, hogar de leyendas ancestrales.", "region": "Sinnoh"},
	{"text": "GALAR, tierra de grandes batallas.", "region": "Galar"},
	{"text": "ALMIA, donde los Rangers protegen a los Pokémon.", "region": "Almia"},
	{"text": "UNOVA, una región moderna y vibrante.", "region": "Unova"},
	{"text": "KALOS, conocida por su elegancia.", "region": "Kalos"},
	{"text": "JOHTO, tierra de tradiciones antiguas.", "region": "Johto"},
	{"text": "KANTO, donde todo comenzó.", "region": "Kanto"},
	{"text": "FIORE, otra tierra de Rangers.", "region": "Fiore"},
	{"text": "PALDEA, con sus climas únicos.", "region": "Paldea"},
	{"text": "El ARCHIPIÉLAGO NARANJA, islas tropicales de mar abierto.", "region": "Naranja"},
	{"text": "OBLIVIA, un remoto archipiélago de Rangers.", "region": "Oblivia"},
	{"text": "HOENN, con sus vastos océanos y volcanes.", "region": "Hoenn"},
	{"text": "Y al sur, ALOLA, un paraíso tropical.", "region": "Alola"},
]

var world_dialogue_index = 0

# ============================================
# INICIALIZACIÓN
# ============================================

func _ready():
	#Conectar señales
	textbox.dialogue_finished.connect(_on_dialogue_finished)
	textbox.option_selected.connect(_on_option_selected)
	textbox.text_displayed.connect(_on_text_displayed)
	# continue_button.pressed ya viene conectado desde la escena (.tscn)
	
	#Ocultar elementos inicialmente
	professor_sprite.visible = false
	textbox.visible = false
	content_container.visible = true
	
	#Iniciar presentación (las notas arrancan en alpha 0)
	start_presentation()

	#Revelar la pantalla: MainMenu entró con fade out y dejó el overlay en negro
	ScreenFade.fade_in()

# ============================================
# FLUJO PRINCIPAL
# ============================================

func start_presentation():
	#Inicia la secuencia de presentación
	current_state = PresentationState.INITIAL_NOTES
	show_initial_notes()

# ============================================
# 1. NOTAS INICIALES
# ============================================

func show_initial_notes():
	#Muestra el panel de notas iniciales para el jugador
	initial_notes_panel.visible = true
	initial_notes_panel.modulate.a = 0.0
	
	#Fade in
	var tween = create_tween()
	tween.tween_property(initial_notes_panel, "modulate:a", 1.0, 0.5)
	await tween.finished

	#Permitir confirmar con Enter además del clic
	continue_button.grab_focus()
	
	#Esperar a que el jugador presione para continuar
	#El panel debe tener un botón "Continuar" conectado a _on_initial_notes_confirmed()

func _on_initial_notes_confirmed():
	#Cuando el jugador confirma haber leído las notas
	#Fade out del panel
	continue_button.visible = false
	var tween = create_tween()
	tween.tween_property(initial_notes_panel, "modulate:a", 0.0, 0.5)
	await tween.finished
	
	initial_notes_panel.visible = false
	show_professor_greeting()

# ============================================
# 2. SALUDO DEL PROFESOR
# ============================================

func show_professor_greeting():
	#El profesor aparece y saluda
	current_state = PresentationState.GREETING
	
	#Mostrar profesor
	professor_sprite.visible = true
	professor_sprite.modulate.a = 0.0
	
	#Animación de aparición
	if animation_player.has_animation("professor_appear"):
		animation_player.play("professor_appear")
		await animation_player.animation_finished
	else:
		var tween = create_tween()
		tween.tween_property(professor_sprite, "modulate:a", 1.0, 0.5)
		await tween.finished
	
	#Mostrar textbox y diálogos
	textbox.visible = true
	textbox.show_dialogue([
		"¡Hey! Perdón por hacerte esperar.\n¡Hay mucho que explicar, poco tiempo!",
		"¡Bienvenido al mundo de POKÉMON!",
		"Mi nombre es Yaniska Aranguren.\nPero me llaman la Profesora Pikachu.",
		"Antes de comenzar tu aventura,\ncuéntame un poco sobre ti."
	])

# ============================================
# 3. CREACIÓN DEL PERSONAJE
# ============================================
 
func show_player_creation():
	#Instancia el panel unificado: nombre + género + apariencia en una sola pantalla.
	current_state = PresentationState.PLAYER_INFO
 
	# Ocultar textbox y profesor mientras el jugador edita
	textbox.visible = false
	var tween = create_tween()
	tween.tween_property(professor_sprite, "modulate:a", 0.0, 0.3)
	await tween.finished
	professor_sprite.visible = false
 
	# Instanciar panel con aparición suave
	current_module = PLAYER_CREATION_SCENE.instantiate()
	current_module.modulate.a = 0.0
	content_container.add_child(current_module)
	current_module.creation_confirmed.connect(_on_creation_confirmed)
	var tween2 = create_tween()
	tween2.tween_property(current_module, "modulate:a", 1.0, 0.45)
	await tween2.finished
 
func _on_creation_confirmed(data: Dictionary):
	#Recibe todos los datos del jugador desde el panel unificado.
	player_data.name = data.name
	player_data.gender = data.gender
	player_data.skin_tone = data.skin_tone
	player_data.hair_style = data.hair_style
	player_data.hair_color = data.hair_color
	player_data.hat = data.hat
	player_data.shirt = data.shirt
	player_data.pants = data.pants
	player_data.shoes = data.shoes
	player_data.gloves = data.gloves
 
	unload_current_module()
 
	# Volver a mostrar al profesor para la confirmación
	professor_sprite.visible = true
	professor_sprite.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(professor_sprite, "modulate:a", 1.0, 0.3)
	await tween.finished
 
	textbox.visible = true
 
	# Confirmación del profesor antes de continuar
	var gender_text = "chico" if player_data.gender == "boy" else "chica"
	textbox.show_text_with_options(
		"Así que eres un " + gender_text + " llamado " + player_data.name + "... ¿Es correcto?",
		["Sí, correcto", "No, déjame cambiar"]
	)
 
# ============================================
# 4. PRESENTACIÓN DEL MUNDO
# ============================================

func transition_to_world_presentation():
	#Transición al mapa del mundo
	current_state = PresentationState.WORLD_PRESENTATION
	
	#Ocultar profesor
	var tween = create_tween()
	tween.tween_property(professor_sprite, "modulate:a", 0.0, 0.5)
	await tween.finished
	professor_sprite.visible = false
	
	# Instanciar mapa como módulo
	current_module = WORLD_MAP_SCENE.instantiate()
	content_container.add_child(current_module)
	current_module.modulate.a = 0.0
 
	var tween2 = create_tween()
	tween2.tween_property(current_module, "modulate:a", 1.0, 1.0)
	await tween2.finished
	
	# Narrar las regiones de arriba abajo (el textbox se mueve antes de cada mención)
	textbox.visible = true
	await _narrate_world()

func _on_text_displayed():
	# El resaltado se gestiona en _narrate_world (no aquí).
	pass

# Narra cada región: mueve el textbox ANTES, luego resalta y menciona. Orden de arriba abajo
# (definido en world_dialogue_sequence) para que el textbox no salte cada dos por tres.
func _narrate_world() -> void:
	for entry in world_dialogue_sequence:
		var region: String = entry["region"]
		await _move_textbox_for_region(region)        # 1) mover preventivamente
		if region != "":
			current_module.highlight_region(region)   # 2) resaltar
		textbox.show_single_text(entry["text"])       # 3) mencionar
		await textbox.dialogue_finished
	await finish_world_presentation()

# Coloca el textbox arriba o abajo para no tapar la región y espera a que termine de moverse.
func _move_textbox_for_region(region_name: String) -> void:
	var to_y := 521.0
	if region_name != "":
		var rrect: Rect2 = current_module.get_region_screen_rect(region_name)
		if rrect.size.x > 0.0:
			var center_y: float = rrect.position.y + rrect.size.y * 0.5
			to_y = 20.0 if center_y >= 360.0 else 521.0
	if absf(textbox.position.y - to_y) > 1.0:
		var t := create_tween()
		t.tween_property(textbox, "position:y", to_y, 0.3)
		await t.finished

func finish_world_presentation():
	current_state = PresentationState.WORLD_OUTRO
	textbox.position.y = 521.0   # devolver el textbox abajo para el resto del diálogo
	# Fade out y destruir módulo del mapa
	var tween = create_tween()
	tween.tween_property(current_module, "modulate:a", 0.0, 1.0)
	await tween.finished
	current_module.clear_all_highlights()
	unload_current_module()
 
	# Volver a mostrar a la profesora, ahora con la pokébola en la mano (frame 0)
	professor_sprite.visible    = true
	professor_sprite.frame      = 0
	professor_sprite.modulate.a = 0.0
	var tween2 = create_tween()
	tween2.tween_property(professor_sprite, "modulate:a", 1.0, 0.5)
	await tween2.finished
 
	# Primera frase y, acto seguido, saca a su Pikachu
	textbox.show_single_text("Este mundo está habitado por criaturas llamadas POKÉMON.")
	await textbox.dialogue_finished
	await _reveal_pikachu()

	textbox.show_dialogue([
		"¡Como este pequeño Pikachu!",
		"En este mundo, cada persona elige libremente su propio camino.",
		"Algunos luchan junto a ellos como entrenadores y retan a los gimnasios.",
		"Otros los cuidan y se conectan como Rangers, en misiones y rescates.",
		"Hay quienes brillan en los concursos, o se dedican a rellenar la Pokédex.",
		"Incluso podrías fundar tu propio gimnasio... o tomar el mando de uno ya existente.",
		"Y, aunque no debería decirlo... algunos eligen la senda del crimen, como el Team Rocket.",
		"Pero esa decisión no me corresponde a mí.",
		"Serás tú, " + player_data.name + ", quien decida en qué dedicarse.",
	])
	await textbox.dialogue_finished
	show_farewell()

func _reveal_pikachu():
	#Destello en la zona de la pokébola; a la vez cambia al sprite sin bola y suelta a Pikachu.
	var ball_pos := Vector2(604, 372)   # mano de la profesora (frame 0), en pantalla

	var flash := Sprite2D.new()
	flash.texture = _make_flash_texture()
	flash.position = ball_pos
	flash.scale = Vector2(0.3, 0.3)
	flash.modulate.a = 0.0
	content_container.add_child(flash)

	# Simultáneo: sprite sin pokébola (frame 1) y aparece Pikachu
	professor_sprite.frame = 1
	_spawn_pikachu(ball_pos)

	var t = create_tween()
	t.set_parallel(true)
	t.tween_property(flash, "modulate:a", 1.0, 0.1)
	t.tween_property(flash, "scale", Vector2(2.6, 2.6), 0.5)
	await get_tree().create_timer(0.2).timeout
	var t2 = create_tween()
	t2.tween_property(flash, "modulate:a", 0.0, 0.35)
	await t2.finished
	flash.queue_free()
	await get_tree().create_timer(0.15).timeout

func _make_flash_texture() -> Texture2D:
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(1, 1, 0.7, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 160
	tex.height = 160
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	return tex

func _spawn_pikachu(pos: Vector2):
	#Aparece Pikachu cuando exista el sprite (res://Assets/Sprites/pokemon/pikachu.png).
	var tex = null
	for p in ["res://Assets/Sprites/pokemon/pikachu.png", "res://Assets/Sprites/pokemon/Pikachu.png", "res://Assets/Sprites/pokemon/025.png"]:
		if ResourceLoader.exists(p):
			tex = load(p)
			break
	if tex == null:
		return
	var pika := Sprite2D.new()
	pika.texture = tex
	pika.position = pos + Vector2(0, 24)
	pika.scale = Vector2(0.2, 0.2)
	content_container.add_child(pika)
	var pt = create_tween()
	pt.set_trans(Tween.TRANS_BACK)
	pt.set_ease(Tween.EASE_OUT)
	pt.tween_property(pika, "scale", Vector2(3, 3), 0.4)

# ============================================
# 5. DESPEDIDA
# ============================================

func show_farewell():
	current_state = PresentationState.FAREWELL

	textbox.show_dialogue([
		"¡Muy bien, " + player_data.name + "!",
		"Tu aventura está a punto de comenzar.",
		"Un mundo de sueños y aventuras con POKÉMON te espera.",
		"El camino que sigas... dependerá solo de ti.",
		"Recuerda: el vínculo con tus Pokémon es lo más importante.",
		"¡Adelante, y mucha suerte!"
	])

# ============================================
# 6. FINALIZACIÓN
# ============================================

func finish_presentation():
	current_state = PresentationState.FINISHED

	Game.player_name   = player_data.name
	Game.player_gender = player_data.gender
	Game.player_appearance = {
		"skin_tone":  player_data.skin_tone,
		"hair_style": player_data.hair_style,
		"hair_color": player_data.hair_color,
		"hat":        player_data.hat,
		"shirt":      player_data.shirt,
		"pants":      player_data.pants,
		"shoes":      player_data.shoes,
		"gloves":     player_data.gloves,
	}

	emit_signal("presentation_complete")
	Game.GameData.active_scene = "res://Scenes/world/PlayerRoom.tscn"
	await ScreenFade.fade_out()
	get_tree().change_scene_to_file("res://Scenes/world/PlayerRoom.tscn")

# ============================================
# CALLBACKS
# ============================================

func _on_dialogue_finished():
	# WORLD_PRESENTATION se gestiona en _narrate_world (espera cada línea por su cuenta).
	match current_state:
		PresentationState.GREETING:
			show_player_creation()

		PresentationState.FAREWELL:
			finish_presentation()
 
func _on_option_selected(index: int):
	match current_state:
		PresentationState.PLAYER_INFO:
			# Confirmación del profesor tras el panel unificado
			if index == 0:
				transition_to_world_presentation()
			else:
				# Volver a abrir el panel para editar
				show_player_creation()

# ============================================
# UTILIDADES
# ============================================

func unload_current_module():
	#Descarga el módulo actual del contenedor
	if current_module:
		current_module.queue_free()
		current_module = null
