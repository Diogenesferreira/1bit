shader_type canvas_item;

uniform vec4 cor_primaria : source_color = vec4(0.85, 0.40, 0.29, 1.0);
uniform float intensidade : hint_range(0.0, 1.0) = 0.52;
uniform bool multicolor = false;

// Wild usa as mesmas cinco cores dos aliados em setores largos. A mistura
// com o sprite original segura a saturacao e evita uma aparencia neon.
vec3 cor_wild(vec2 uv) {
	float angulo = atan(uv.y - 0.5, uv.x - 0.5) + 3.14159265;
	float setor = floor(angulo / (6.28318530 / 5.0));
	if (setor < 1.0) return vec3(0.725, 0.396, 0.322); // dragao
	if (setor < 2.0) return vec3(0.408, 0.514, 0.592); // cavaleiro
	if (setor < 3.0) return vec3(0.424, 0.525, 0.369); // natureza
	if (setor < 4.0) return vec3(0.729, 0.635, 0.341); // luz
	return vec3(0.475, 0.412, 0.557);                  // trevas
}

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec3 alvo = multicolor ? cor_wild(UV) : cor_primaria.rgb;
	vec3 tingido = base.rgb * alvo;
	COLOR = vec4(mix(base.rgb, tingido, intensidade), base.a);
}
