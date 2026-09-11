shader_type canvas_item;
render_mode unshaded;

uniform int clear_count = 0;
uniform vec4 clear_regions[32];
uniform vec4 empty_color : source_color = vec4(0.02745, 0.08235, 0.14902, 1.0);

void fragment() {
	vec2 pixel = UV * vec2(textureSize(TEXTURE, 0));
	vec4 ink = texture(TEXTURE, UV);
	for (int i = 0; i < clear_count; i++) {
		vec4 r = clear_regions[i];
		if (pixel.x >= r.x && pixel.y >= r.y && pixel.x < r.x + r.z && pixel.y < r.y + r.w) {
			ink = empty_color;
		}
	}
	COLOR = ink;
}
