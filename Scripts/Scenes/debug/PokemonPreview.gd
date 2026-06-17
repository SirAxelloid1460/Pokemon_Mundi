extends Node2D
# Previsualización de un Pokémon: anima la hoja y prueba el shader shiny.
# Ejecuta esta escena (F6).  ←/→ cambia animación · Enter alterna shiny.

const SHEET := "res://Assets/Sprites/pokemon/0001_U.png"

var _sprite: PokemonSprite
var _label: Label
var _anim_index: int = 0
var _shiny: bool = false

func _ready():
	var bg := ColorRect.new()
	bg.color = Color(0.16, 0.18, 0.22)
	bg.size = Vector2(1280, 720)
	bg.z_index = -10
	add_child(bg)

	_sprite = PokemonSprite.new()
	add_child(_sprite)
	_sprite.position = Vector2(640, 360)
	_sprite.scale = Vector2(4, 4)
	_sprite.load_pokemon(1)

	_label = Label.new()
	_label.position = Vector2(24, 20)
	_label.add_theme_font_size_override("font_size", 24)
	add_child(_label)
	_update_label()

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("ui_right"):
		_cycle(1)
	elif event.is_action_pressed("ui_left"):
		_cycle(-1)
	elif event.is_action_pressed("ui_accept"):
		_toggle_shiny()

func _cycle(dir: int):
	var anims = PokemonSprite.ANIM_ROWS
	_anim_index = (_anim_index + dir + anims.size()) % anims.size()
	_sprite.play(anims[_anim_index])
	_update_label()

func _toggle_shiny():
	_shiny = not _shiny
	if _shiny:
		var normal := PaletteSwap.extract_palette_from_path(SHEET)
		var shifted: Array = []
		for c in normal:
			shifted.append(Color.from_hsv(fmod(c.h + 0.5, 1.0), c.s, c.v, c.a))
		_sprite.apply_shiny(shifted)
	else:
		_sprite.clear_shiny()
	_update_label()

func _update_label():
	var anims = PokemonSprite.ANIM_ROWS
	_label.text = "Bulbasaur (0001)   Animación: %s   Shiny: %s\n←/→ cambiar animación    ·    Enter alternar shiny (prueba)" % [
		anims[_anim_index], "Sí" if _shiny else "No"]
