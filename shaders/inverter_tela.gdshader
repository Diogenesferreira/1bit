shader_type canvas_item;

// O "screen flash" do handoff: a tela INTEIRA inverte por 100ms quando
// uma fusao da certo. Le o que ja foi desenhado (screen texture) em vez
// de pintar por cima, para ser inversao de verdade e nao um veu branco.

uniform sampler2D tela : hint_screen_texture, filter_nearest;
uniform float quantidade : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec3 c = texture(tela, SCREEN_UV).rgb;
	COLOR = vec4(mix(c, vec3(1.0) - c, quantidade), 1.0);
}
