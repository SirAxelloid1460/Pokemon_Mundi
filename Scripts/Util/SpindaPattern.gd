class_name SpindaPattern
extends RefCounted
# Genera el patrón de manchas único de Spinda a partir de su PID (32 bits), fiel al juego.
# Cada una de las 4 manchas se desplaza según un par de nibbles del PID (offset 0-15 px en X e Y),
# dando ~4.290 millones de combinaciones. El PID se guarda por individuo (campo del Pokémon de la
# party, aún pendiente). Útil para Pokédex/combate cuando exista el sprite de Spinda.

# Coordenadas base de cada mancha sobre el sprite frontal (esquina sup-izq del bitmap de la mancha).
# PLACEHOLDER: ajustar a la cara real del sprite de Spinda (todavía no existe). Orden: ojo-izq,
# ojo-der, mejilla-izq, mejilla-der. Valores de referencia del juego (sprite 64px), reescalables.
const BASE_SPOTS: Array[Vector2] = [
	Vector2(8, 6),    # mancha 1 (sobre ojo izquierdo)
	Vector2(32, 7),   # mancha 2 (sobre ojo derecho)
	Vector2(14, 24),  # mancha 3 (mejilla izquierda)
	Vector2(26, 25),  # mancha 4 (mejilla derecha)
]

# Offsets (x,y) de las 4 manchas para un PID dado. Cada componente va de 0 a 15.
static func spot_offsets(pid: int) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for i in range(4):
		var shift := i * 8
		var x := (pid >> shift) & 0x0F
		var y := (pid >> (shift + 4)) & 0x0F
		out.append(Vector2(x, y))
	return out

# Posiciones finales (base + offset) de las 4 manchas.
static func spot_positions(pid: int) -> Array[Vector2]:
	var offs := spot_offsets(pid)
	var out: Array[Vector2] = []
	for i in range(4):
		out.append(BASE_SPOTS[i] + offs[i])
	return out

# PID aleatorio de 32 bits (al generar un Spinda salvaje/individual).
static func random_pid() -> int:
	return randi() & 0xFFFFFFFF

# Dibuja las 4 manchas sobre 'parent' con 'spot_texture' (cuando exista el asset).
# Devuelve los Sprite2D creados. El recorte al cuerpo (que la mancha no desborde) requiere
# enmascarar con el alfa del cuerpo (shader/BackBuffer); de momento solo las posiciona.
static func render_spots(parent: Node2D, pid: int, spot_texture: Texture2D) -> Array[Sprite2D]:
	var sprites: Array[Sprite2D] = []
	for pos in spot_positions(pid):
		var s := Sprite2D.new()
		s.texture = spot_texture
		s.centered = false
		s.position = pos
		parent.add_child(s)
		sprites.append(s)
	return sprites
