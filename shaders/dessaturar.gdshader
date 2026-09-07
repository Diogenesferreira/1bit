shader_type canvas_item;

// Morte de unidade: grayscale(1) + brightness(.45) do contrato de animacao
// (ANIMACOES.md secao 4). Lê o alpha da textura, entao acompanha a silhueta.
// `quantidade` = 0 desliga, 1 aplica por completo.

uniform float quantidade : hint_range(0.0, 1.0) = 0.0;
uniform float brilho : hint_range(0.0, 2.0) = 0.45;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float luma = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 cinza = vec3(luma) * brilho;
	COLOR = vec4(mix(c.rgb, cinza, quantidade), c.a) * COLOR;
}
