shader_type canvas_item;
// 흑백으로 그린다(가방의 코어 조각 칸: 아직 모으는 중이라 색을 빼서 흐리게). dim = 밝기 배율.
uniform float dim = 0.75;

void fragment() {
	vec4 color = texture(TEXTURE, UV) * COLOR;
	float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114)) * dim;
	COLOR = vec4(vec3(gray), color.a);
}
