shader_type canvas_item;

// Inversao 1-bit (o `filter: invert(1)` do prototipo HTML).
//
// Serve para duas coisas do handoff:
//   - icones de elemento sobre o CHAO CLARO da arena (o traco branco
//     vira preto e volta a ser legivel);
//   - o "hit flash": a unidade e a barra de vida piscam invertidas por
//     220ms quando tomam dano.
//
// `quantidade` = 0 desliga, 1 inverte por completo.

uniform float quantidade : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	COLOR = vec4(mix(c.rgb, vec3(1.0) - c.rgb, quantidade), c.a) * COLOR;
}
