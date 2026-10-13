shader_type spatial;
#include "res://materials/triplanar.gdshaderinc"

uniform vec4 fabric_color : source_color = vec4(0.78,0.70,0.53,1.0);
uniform sampler2D color_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D roughness_map : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 texture_average : source_color = vec4(0.6,0.6,0.5,1.0);
uniform float meters_per_tile : hint_range(0.05,2.0) = 0.5;
uniform float texture_strength : hint_range(0.0,1.0) = 0.45;
uniform float relief_strength : hint_range(0.0,1.0) = 0.55;
varying vec3 local_position;
varying vec3 local_normal;

void vertex() {
    // Coordenadas do próprio objeto: a trama acompanha o movimento da roupa.
    local_position = VERTEX * object_scale(MODEL_MATRIX);
    local_normal = NORMAL;
}

void fragment() {
    vec3 p = local_position / meters_per_tile;
    vec3 n = normalize(local_normal);
    vec3 weights = projection_weights(n);
    vec3 surface_color = project_texture(color_map,p,weights);
    vec3 luminance = vec3(0.2126,0.7152,0.0722);
    float thread_value = dot(surface_color,luminance) / max(dot(texture_average.rgb,luminance),0.01);
    ALBEDO = fabric_color.rgb * mix(1.0,clamp(thread_value,0.3,1.7),texture_strength);
    ROUGHNESS = clamp(project_texture(roughness_map,p,weights).r * 0.25 + 0.72,0.8,0.98);
    SPECULAR = 0.12;
    vec3 perturbed = project_normal(normal_map,p,n,weights,relief_strength);
    NORMAL = normalize(mat3(VIEW_MATRIX) * MODEL_NORMAL_MATRIX * perturbed);
}
