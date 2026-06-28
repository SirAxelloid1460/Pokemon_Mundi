class_name MenuIcon
extends Control
# Icono de menú dibujado por código (placeholder hasta tener arte propio).

const LINE_NORMAL := Color(0.90, 0.92, 0.97)
const LINE_SEL := Color(1.0, 0.88, 0.35)

var kind := ""
var selected := false

func setup(k: String, sel: bool) -> void:
	kind = k
	selected = sel
	queue_redraw()

func _draw() -> void:
	var col := LINE_SEL if selected else LINE_NORMAL
	var c := size * 0.5
	var u: float = min(size.x, size.y) * 0.30
	var w := 3.0

	match kind:
		"mapa":
			draw_arc(c, u, 0.0, TAU, 28, col, w)
			var d := PackedVector2Array([
				c + Vector2(0, -u * 0.95), c + Vector2(u * 0.45, 0),
				c + Vector2(0, u * 0.95), c + Vector2(-u * 0.45, 0),
				c + Vector2(0, -u * 0.95)])
			draw_polyline(d, col, w)
		"bag":
			draw_rect(Rect2(c.x - u, c.y - u * 0.4, u * 2.0, u * 1.4), col, false, w)
			draw_line(c + Vector2(-u, -u * 0.4), c + Vector2(-u * 0.4, -u * 1.1), col, w)
			draw_line(c + Vector2(u, -u * 0.4), c + Vector2(u * 0.4, -u * 1.1), col, w)
			draw_line(c + Vector2(-u, u * 0.2), c + Vector2(u, u * 0.2), col, w)
		"pokedex":
			draw_rect(Rect2(c.x - u * 0.95, c.y - u, u * 1.9, u * 2.0), col, false, w)
			draw_arc(c + Vector2(-u * 0.4, -u * 0.45), u * 0.3, 0.0, TAU, 16, col, w)
			draw_line(c + Vector2(-u * 0.95, u * 0.25), c + Vector2(u * 0.95, u * 0.25), col, w)
		"equipo":
			draw_arc(c, u, 0.0, TAU, 28, col, w)
			draw_line(c + Vector2(-u, 0), c + Vector2(u, 0), col, w)
			draw_arc(c, u * 0.32, 0.0, TAU, 16, col, w)
		"personaje":
			draw_rect(Rect2(c.x - u, c.y - u * 0.7, u * 2.0, u * 1.4), col, false, w)
			draw_arc(c + Vector2(-u * 0.4, -u * 0.1), u * 0.32, 0.0, TAU, 16, col, w)
			draw_line(c + Vector2(0, -u * 0.3), c + Vector2(u * 0.75, -u * 0.3), col, w)
			draw_line(c + Vector2(0, u * 0.05), c + Vector2(u * 0.75, u * 0.05), col, w)
		"home":
			# tejado
			draw_polyline(PackedVector2Array([
				c + Vector2(-u, -u * 0.1), c + Vector2(0, -u), c + Vector2(u, -u * 0.1)]), col, w)
			# cuerpo
			draw_rect(Rect2(c.x - u * 0.7, c.y - u * 0.1, u * 1.4, u * 1.1), col, false, w)
			# puerta
			draw_rect(Rect2(c.x - u * 0.22, c.y + u * 0.35, u * 0.44, u * 0.65), col, false, w)
