shader_type spatial;
render_mode diffuse_burley;
varying vec3 p;
void vertex() { p = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
float hash(vec2 q) { return fract(sin(dot(q,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 q) {
    vec2 i=floor(q),f=fract(q); f=f*f*(3.0-2.0*f);
    return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void fragment() {
    float broad=noise(p.xz*8.0);
    vec2 cell=fract(p.xz/0.75);
    vec2 edge=min(cell,vec2(1.0)-cell);
    float inset=smoothstep(0.005,0.022,min(edge.x,edge.y));
    ALBEDO=COLOR.rgb*(0.97+0.04*broad)*mix(0.83,1.0,inset);
    ROUGHNESS=0.79;
    SPECULAR=0.24;
}
