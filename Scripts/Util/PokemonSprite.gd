class_name PokemonSprite
extends AnimatedSprite2D
# Sprite animado de un Pokémon desde una hoja regular de 2 columnas x 7 filas.
# Filas (2 frames cada una):
#   0 battle_enemy · 1 battle_ally · 2 menu · 3 walk_up · 4 walk_left · 5 walk_down · 6 walk_right
# Nombre de archivo: {dex:0001}_{genero}[_{region}].png   (genero M/F/U; region vacía = base)
#
# Uso:
#   var p := PokemonSprite.new()
#   add_child(p)
#   p.load_pokemon(1)                       # Bulbasaur base, género universal
#   p.play("walk_down")
#   p.apply_shiny(shiny_palette)            # recolor shiny (paleta del mismo tamaño/orden)

const BASE_PATH := "res://Assets/Sprites/pokemon/"
const COLS := 2
const ANIM_ROWS := ["battle_enemy", "battle_ally", "menu", "walk_up", "walk_left", "walk_down", "walk_right"]
const ANIM_FPS := {
	"battle_enemy": 3.0, "battle_ally": 3.0, "menu": 3.0,
	"walk_up": 6.0, "walk_left": 6.0, "walk_down": 6.0, "walk_right": 6.0,
}

var dex: int = 0
var _texture: Texture2D = null

func load_pokemon(p_dex: int, gender := "U", region := "", default_anim := "battle_enemy") -> bool:
	var path := resolve_path(p_dex, gender, region)
	if path == "":
		push_warning("PokemonSprite: no se encontró sprite para dex %d (%s/%s)" % [p_dex, gender, region])
		return false
	dex = p_dex
	_texture = load(path)
	material = null   # aspecto normal sin material
	sprite_frames = build_frames(_texture)
	if sprite_frames.has_animation(default_anim):
		play(default_anim)
	return true

func apply_shiny(shiny_palette: Array) -> void:
	#shiny_palette: los mismos colores que la paleta normal del sprite, en el mismo orden, recoloreados.
	if _texture == null:
		return
	var normal := PaletteSwap.extract_palette(_texture)
	material = PaletteSwap.make_material(normal, shiny_palette)

func clear_shiny() -> void:
	material = null

# ============================================
# RESOLUCIÓN DE ARCHIVO (con fallbacks)
# ============================================

static func resolve_path(p_dex: int, gender: String, region: String) -> String:
	var dex_str := "%04d" % p_dex
	var genders := [gender, "U", "M", "F"]   # preferido → universal → cualquiera
	var regions := [region, ""]              # preferida → base
	for r in regions:
		for g in genders:
			var fname := "%s_%s" % [dex_str, g]
			if r != "":
				fname += "_" + r
			var p := BASE_PATH + fname + ".png"
			if ResourceLoader.exists(p):
				return p
	return ""

# ============================================
# CONSTRUCCIÓN DE FRAMES
# ============================================

static func build_frames(tex: Texture2D) -> SpriteFrames:
	var rows := ANIM_ROWS.size()
	var fw := int(tex.get_width() / COLS)        # tamaño de frame auto-derivado de la hoja
	var fh := int(tex.get_height() / rows)
	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	for row in range(rows):
		var anim: String = ANIM_ROWS[row]
		sf.add_animation(anim)
		sf.set_animation_loop(anim, true)
		sf.set_animation_speed(anim, ANIM_FPS.get(anim, 4.0))
		for col in range(COLS):
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(col * fw, row * fh, fw, fh)
			sf.add_frame(anim, at)
	return sf
