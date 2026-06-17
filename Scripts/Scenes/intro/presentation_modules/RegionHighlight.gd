extends Node2D
# Caja de resaltado pulsante para una región (rect en coordenadas de pantalla).

var rect: Rect2 = Rect2()
var active: bool = false
var _t: float = 0.0

func show_rect(r: Rect2) -> void:
	rect = r
	active = true
	_t = 0.0
	queue_redraw()

func hide_rect() -> void:
	active = false
	queue_redraw()

func _process(delta: float) -> void:
	if active:
		_t += delta
		queue_redraw()

func _draw() -> void:
	if not active or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var pulse: float = 0.5 + 0.5 * sin(_t * 4.0)
	draw_rect(rect, Color(1.0, 0.9, 0.3, 0.10 + 0.10 * pulse), true)
	draw_rect(rect, Color(1.0, 0.9, 0.3, 0.6 + 0.4 * pulse), false, 4.0)
