shader_type canvas_item;

uniform vec2 tiling = vec2(1.0, 1.0);
uniform vec2 offset = vec2(0.0, 0.0);

void fragment() {
	vec2 uv = UV * tiling + offset;
	COLOR = texture(TEXTURE, uv);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
