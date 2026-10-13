shader_type spatial;
render_mode unshaded;
// Paisagem ilustrativa sem marco geográfico específico, vista além do vidro.
varying vec2 window_uv;
void vertex() {
    window_uv=VERTEX.xy/vec2(2.05,1.74)+vec2(0.5);
    window_uv.y=1.0-window_uv.y;
}
void fragment() {
    vec3 sky=mix(vec3(0.53,0.70,0.75),vec3(0.86,0.89,0.80),smoothstep(0.0,0.55,window_uv.y));
    vec3 water=mix(vec3(0.39,0.59,0.60),vec3(0.29,0.49,0.48),smoothstep(0.50,1.0,window_uv.y));
    float ripples=sin(window_uv.y*210.0+sin(window_uv.x*42.0))*0.012;
    vec3 color=mix(sky,water+vec3(ripples),smoothstep(0.48,0.51,window_uv.y));
    float bank=0.505+sin(window_uv.x*18.0)*0.008+sin(window_uv.x*49.0)*0.004;
    color=mix(color,vec3(0.39,0.48,0.38),smoothstep(bank-0.005,bank,window_uv.y)*(1.0-smoothstep(bank+0.012,bank+0.024,window_uv.y)));
    ALBEDO=color;
}
