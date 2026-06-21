shader_type canvas_item;
// Filtro "pantalla digital" tipo Pokédex (tinte rojo + scanlines + viñeta + leve brillo).
// Se aplica como material del Sprite2D del mapa mundi en la vista de categorías de la Pokédex.

uniform vec3 screen_tint : source_color = vec3(0.86, 0.13, 0.16);
uniform float tint_strength : hint_range(0.0, 1.0) = 0.55;
uniform float scan_intensity : hint_range(0.0, 1.0) = 0.16;
uniform float scan_count = 260.0;
uniform float vignette : hint_range(0.0, 2.0) = 1.1;
uniform float brightness = 1.06;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float l = dot(tex.rgb, vec3(0.299, 0.587, 0.114));   // luminancia
	vec3 col = mix(tex.rgb, screen_tint * (0.35 + l), tint_strength);
	col *= brightness;
	// scanlines horizontales
	float sl = sin(UV.y * scan_count * 3.14159265) * 0.5 + 0.5;
	col *= 1.0 - scan_intensity * sl;
	// viñeta
	float vig = smoothstep(0.85, 0.25, length(UV - vec2(0.5)) * vignette * 1.5);
	col *= mix(0.6, 1.0, vig);
	COLOR = vec4(col, tex.a);
}
