shader_type spatial;
render_mode diffuse_burley;
uniform vec4 thread_color : source_color = vec4(0.8,0.3,0.2,1.0);
varying vec3 local_position;
void vertex(){local_position=VERTEX;}
void fragment(){
 float phase=dot(local_position,vec3(510.0,790.0,630.0));
 float fade=1.0-smoothstep(0.8,3.0,fwidth(phase));
 ALBEDO=thread_color.rgb*(0.97+0.025*sin(phase)*fade);
 ROUGHNESS=0.94;
 SPECULAR=0.16;
}
