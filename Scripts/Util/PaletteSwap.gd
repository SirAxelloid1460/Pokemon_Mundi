class_name PaletteSwap
extends RefCounted
# Utilidades de reemplazo de paleta para shiny / recolores.
# El aspecto NORMAL sale del PNG sin material; esto solo genera variantes.
#
# Uso típico:
#   var normal = PaletteSwap.extract_palette_from_path("res://Assets/Sprites/pokemon/pikachu.png")
#   var shiny  = [...]   # mismos N colores que `normal`, en el mismo orden, recoloreados
#   PaletteSwap.apply_variant($Sprite2D, normal, shiny)   # mostrar shiny
#   PaletteSwap.clear_variant($Sprite2D)                  # volver al normal

const SHADER := preload("res://Assets/Shaders/palette_swap.gdshader")

# Colores únicos opacos de una textura, ordenados por luminancia (paleta normal).
static func extract_palette(tex: Texture2D) -> Array:
	if tex == null:
		return []
	var img := tex.get_image()
	if img == null:
		return []
	return _extract_from_image(img)

static func extract_palette_from_path(path: String) -> Array:
	if not ResourceLoader.exists(path):
		push_warning("PaletteSwap: textura no encontrada: " + path)
		return []
	return extract_palette(load(path))

static func _extract_from_image(img: Image) -> Array:
	var seen := {}
	var colors: Array = []
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var k := "%d_%d_%d" % [int(round(c.r * 255.0)), int(round(c.g * 255.0)), int(round(c.b * 255.0))]
			if not seen.has(k):
				seen[k] = true
				colors.append(c)
	colors.sort_custom(func(a, b): return a.get_luminance() < b.get_luminance())
	return colors

# Textura Nx1 a partir de un array de Color (para los uniforms del shader).
static func make_palette_texture(colors: Array) -> ImageTexture:
	var n: int = max(1, colors.size())
	var img := Image.create(n, 1, false, Image.FORMAT_RGBA8)
	for i in range(colors.size()):
		img.set_pixel(i, 0, colors[i])
	return ImageTexture.create_from_image(img)

# Material que recolorea key_colors -> target_colors (mismo orden y tamaño).
static func make_material(key_colors: Array, target_colors: Array) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("key_palette", make_palette_texture(key_colors))
	mat.set_shader_parameter("target_palette", make_palette_texture(target_colors))
	mat.set_shader_parameter("color_count", key_colors.size())
	return mat

# Aplica una variante a un sprite (Sprite2D, AnimatedSprite2D, etc.).
static func apply_variant(sprite: CanvasItem, normal_colors: Array, target_colors: Array) -> void:
	if sprite == null:
		return
	sprite.material = make_material(normal_colors, target_colors)

static func clear_variant(sprite: CanvasItem) -> void:
	if sprite:
		sprite.material = null
