shader_type canvas_item;

// Neutraliza apenas os acentos azulados da arte gerada. Vermelho da LIFE,
// marfim, grafite e transparencia permanecem intactos.
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	bool azulado = c.b > c.r * 1.10 && c.b >= c.g * 0.92;
	bool ciano = c.g > c.r * 1.18 && c.b > c.r * 1.18;
	if (azulado || ciano) {
		float luz = dot(c.rgb, vec3(0.24, 0.68, 0.08));
		c.rgb = vec3(luz * 0.96, luz * 0.97, luz);
	}
	COLOR = c;
}
