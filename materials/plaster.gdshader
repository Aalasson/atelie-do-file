shader_type spatial;
#include "res://materials/triplanar.gdshaderinc"

uniform vec4 surface_color : source_color = vec4(0.87,0.85,0.81,1.0);
uniform sampler2D color_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D roughness_map : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 texture_average : source_color = vec4(0.65,0.62,0.56,1.0);
uniform float meters_per_tile : hint_range(0.2,6.0) = 2.23;
uniform float relief_strength : hint_range(0.0,1.0) = 0.35;
varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	// A posição global mantém continuidade entre os trechos da mesma parede.
	world_position = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
	world_normal = MODEL_NORMAL_MATRIX * NORMAL;
}

void fragment() {
	vec3 p = world_position / meters_per_tile;
	vec3 n = normalize(world_normal);
	vec3 weights = projection_weights(n);
	vec3 sample_color = project_texture(color_map,p,weights);
	vec3 variation = clamp(sample_color / max(texture_average.rgb,vec3(0.01)),vec3(0.6),vec3(1.4));
	ALBEDO = surface_color.rgb * mix(vec3(1.0),variation,0.8);
	ROUGHNESS = clamp(project_texture(roughness_map,p,weights).r * 0.25 + 0.7,0.8,1.0);
	SPECULAR = 0.16;
	NORMAL = normalize(mat3(VIEW_MATRIX) * project_normal(normal_map,p,n,weights,relief_strength));
}
