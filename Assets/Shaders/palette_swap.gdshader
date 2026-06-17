shader_type canvas_item;

// Reemplazo de paleta por color-clave.
// Úsalo SOLO para shiny / recolores: el aspecto normal sale del PNG sin material.
// Requiere filtro nearest (el proyecto ya lo usa) para que el match de color sea exacto.

const int MAX_COLORS = 32;

uniform sampler2D key_palette : filter_nearest;     // colores normales del sprite (Nx1)
uniform sampler2D target_palette : filter_nearest;  // colores de la variante (Nx1, mismo orden)
uniform int color_count = 16;

void fragment() {
	vec4 src = texture(TEXTURE, UV);
	vec3 result = src.rgb;
	for (int i = 0; i < MAX_COLORS; i++) {
		if (i >= color_count) { break; }
		float u = (float(i) + 0.5) / float(color_count);
		vec3 key = texture(key_palette, vec2(u, 0.5)).rgb;
		if (distance(src.rgb, key) < 0.02) {
			result = texture(target_palette, vec2(u, 0.5)).rgb;
			break;
		}
	}
	COLOR = vec4(result, src.a);
}
