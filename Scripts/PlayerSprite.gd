# ============================================
# PlayerSprite.gd
# Sistema de sprites modulares por capas
# Ubicación: res://scripts/PlayerSprite.gd
# ============================================
class_name PlayerSprite
extends Node2D

# Capas esenciales del personaje (de atrás hacia adelante)
@onready var shadow: Sprite2D = $Shadow
@onready var body_back: Sprite2D = $BodyBack  # Brazo/pierna trasera
@onready var legs: Sprite2D = $Legs
@onready var torso: Sprite2D = $Torso
@onready var arms: Sprite2D = $Arms
@onready var head: Sprite2D = $Head
@onready var hair: Sprite2D = $Hair
@onready var outfit: Sprite2D = $Outfit

# Capas opcionales (comentadas por ahora)
# @onready var eyes: Sprite2D = $Eyes
# @onready var accessories: Sprite2D = $Accessories

const SPRITE_BASE_PATH = "res://sprites/player/"

var current_gender: String = "boy"
var current_skin_tone: int = 0
var current_hair_style: int = 0
var current_hair_color: int = 0
var current_outfit: int = 0
var current_direction: String = "down"

func _ready():
	shadow.z_index = -1
	body_back.z_index = 0
	legs.z_index = 1
	torso.z_index = 2
	arms.z_index = 3
	head.z_index = 4
	hair.z_index = 5
	outfit.z_index = 6
	# eyes.z_index = 7
	# accessories.z_index = 8

func initialize(appearance_data: Dictionary, gender: String = "boy"):
	#Inicializa el sprite con datos de apariencia y género.
	current_gender = gender
	current_skin_tone = appearance_data.get("skin_tone", 0)
	current_hair_style = appearance_data.get("hair_style", 0)
	current_hair_color = appearance_data.get("hair_color", 0)
	current_outfit = appearance_data.get("outfit", 0)
	update_sprites()

func update_sprites(direction: String = "down"):
	#Actualiza todos los sprites según la dirección y apariencia.
	current_direction = direction
	load_body_part("legs", legs)
	load_body_part("torso", torso)
	load_body_part("arms", arms)
	load_body_part("head", head)
	load_body_part("hair", hair)
	load_body_part("outfit", outfit)
	# load_body_part("eyes", eyes)
	adjust_layer_visibility()

func load_body_part(part_name: String, sprite_node: Sprite2D):
	#Carga el sprite de una parte específica del cuerpo.
	var sprite_path = ""

	match part_name:
		"legs", "torso", "arms":
			sprite_path = "%s%s/%s/skin_%d_%s.png" % [
				SPRITE_BASE_PATH, current_gender, part_name,
				current_skin_tone, current_direction
			]
		"head":
			sprite_path = "%s%s/head/skin_%d_%s.png" % [
				SPRITE_BASE_PATH, current_gender,
				current_skin_tone, current_direction
			]
		"hair":
			sprite_path = "%s%s/hair/style_%d_color_%d_%s.png" % [
				SPRITE_BASE_PATH, current_gender,
				current_hair_style, current_hair_color, current_direction
			]
		"outfit":
			sprite_path = "%s%s/outfits/outfit_%d_%s.png" % [
				SPRITE_BASE_PATH, current_gender,
				current_outfit, current_direction
			]
		# "eyes":
		# 	sprite_path = "%s%s/eyes/%s.png" % [
		# 		SPRITE_BASE_PATH, current_gender, current_direction
		# 	]

	if ResourceLoader.exists(sprite_path):
		sprite_node.texture = load(sprite_path)
		sprite_node.visible = true
	else:
		sprite_node.visible = false
		if OS.is_debug_build():
			push_warning("Sprite no encontrado: " + sprite_path)

func adjust_layer_visibility():
	#Ajusta visibilidad de capas según la dirección.
	match current_direction:
		"up", "down":
			body_back.visible = false
		"left", "right":
			body_back.visible = true

func change_direction(new_direction: String):
	#Cambia la dirección del sprite.
	if new_direction != current_direction:
		update_sprites(new_direction)

func change_outfit(new_outfit: int):
	#Cambia solo el outfit sin recargar todo.
	current_outfit = new_outfit
	load_body_part("outfit", outfit)

func change_hair_color(new_color: int):
	#Cambia solo el color de cabello.
	current_hair_color = new_color
	load_body_part("hair", hair)

func change_hair_style(new_style: int):
	#Cambia el estilo de cabello.
	current_hair_style = new_style
	load_body_part("hair", hair)

# ============================================
# ACCESORIOS (comentado para más adelante)
# ============================================
# func add_accessory(accessory_name: String):
# 	var accessory_path = "%s%s/accessories/%s_%s.png" % [
# 		SPRITE_BASE_PATH, current_gender, accessory_name, current_direction
# 	]
# 	if ResourceLoader.exists(accessory_path):
# 		accessories.texture = load(accessory_path)
# 		accessories.visible = true

# func remove_accessory():
# 	accessories.visible = false
# 	accessories.texture = null
