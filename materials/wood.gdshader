shader_type spatial;
render_mode diffuse_burley;
#include "res://materials/triplanar.gdshaderinc"

uniform vec4 timber : source_color = vec4(0.57,0.36,0.18,1.0);
uniform vec3 grain_axis = vec3(1.0,0.0,0.0);
uniform float variation_seed = 0.0;
uniform sampler2D color_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D roughness_map : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 texture_average : source_color = vec4(0.54,0.41,0.28,1.0);
uniform float meters_per_tile : hint_range(0.1,3.0) = 0.5;
uniform float texture_strength : hint_range(0.0,1.0) = 0.8;
uniform float relief_strength : hint_range(0.0,1.0) = 0.3;
varying vec3 local_position;
varying vec3 local_normal;

void vertex() {
    local_position = VERTEX * object_scale(MODEL_MATRIX);
    local_normal = NORMAL;
}

void fragment() {
    vec3 a = normalize(grain_axis);
    vec3 b = abs(a.y) > 0.9 ? vec3(0.0,0.0,1.0) : vec3(0.0,1.0,0.0);
    vec3 c = normalize(cross(a,b));
    mat3 orientation = mat3(a,b,c);
    vec3 p = transpose(orientation) * local_position / meters_per_tile;
    p += vec3(variation_seed * 0.137, variation_seed * 0.319, variation_seed * 0.173);
    vec3 n = normalize(transpose(orientation) * local_normal);
    vec3 weights = projection_weights(n);
    vec3 surface_color = project_texture(color_map,p,weights);
    vec3 grain = clamp(surface_color / max(texture_average.rgb,vec3(0.01)),vec3(0.35),vec3(1.9));
    ALBEDO = timber.rgb * mix(vec3(1.0),grain,texture_strength);
    ROUGHNESS = clamp(project_texture(roughness_map,p,weights).r * 0.65 + 0.22,0.55,0.9);
    SPECULAR = 0.25;
    vec3 perturbed = orientation * project_normal(normal_map,p,n,weights,relief_strength);
    NORMAL = normalize(mat3(VIEW_MATRIX) * MODEL_NORMAL_MATRIX * perturbed);
}
