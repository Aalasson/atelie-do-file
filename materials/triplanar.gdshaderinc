// Projeção em três planos: atende também malhas locais sem UV/tangentes.
vec3 projection_weights(vec3 n) {
	vec3 w = pow(abs(n), vec3(6.0));
	return w / max(dot(w, vec3(1.0)), 0.0001);
}

vec3 project_texture(sampler2D image_map, vec3 p, vec3 weights) {
	return texture(image_map, p.zy).rgb * weights.x
		+ texture(image_map, p.xz).rgb * weights.y
		+ texture(image_map, p.xy).rgb * weights.z;
}

vec3 project_normal(sampler2D image_map, vec3 p, vec3 n, vec3 weights, float strength) {
	// Usa RG; o canal azul pode ser descartado na compressão de normal maps.
	vec2 x = texture(image_map, p.zy).rg * 2.0 - 1.0;
	vec2 y = texture(image_map, p.xz).rg * 2.0 - 1.0;
	vec2 z = texture(image_map, p.xy).rg * 2.0 - 1.0;
	vec3 slope = vec3(0.0, x.y, x.x) * weights.x
		+ vec3(y.x, 0.0, y.y) * weights.y
		+ vec3(z.x, z.y, 0.0) * weights.z;
	// Perturbação no plano tangente. Normal neutra (0.5,0.5,1) preserva a malha.
	slope -= n * dot(n, slope);
	return normalize(n + slope * strength);
}

vec3 object_scale(mat4 model) {
	return vec3(length(model[0].xyz), length(model[1].xyz), length(model[2].xyz));
}
