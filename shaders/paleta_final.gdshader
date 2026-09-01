shader_type canvas_item;

// Paleta 1-bit final do jogo:
// todo preto ou quase-preto vira exatamente #27272F.
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	vec4 c = textureLod(screen_texture, SCREEN_UV, 0.0);
	float maior_canal = max(c.r, max(c.g, c.b));
	if (maior_canal < 0.22) {
		c.rgb = vec3(39.0 / 255.0, 39.0 / 255.0, 47.0 / 255.0);
	}
	COLOR = c;
}
