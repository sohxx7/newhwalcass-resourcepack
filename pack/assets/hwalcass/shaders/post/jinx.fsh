#version 330
#extension GL_ARB_separate_shader_objects : require
#include <minecraft:globals.glsl>
#include <hwalcass:jinx_rays.glsl>
uniform sampler2D InSampler;
uniform sampler2D OriginalSampler;
uniform sampler2D SidesSampler;
uniform sampler2D RaysSampler;
layout(std140) uniform JinxConfig {float Motion;float Speed;};
layout(location=0) in vec2 texCoord;
layout(location=0) out vec4 fragColor;
float hash1(float n){return fract(sin(n*127.1+311.7)*43758.5453);}
void main(){
    vec4 scene=texture(InSampler,texCoord);
    vec2 uv=vec2(texCoord.x,1.0-texCoord.y);
    vec4 original=texture(OriginalSampler,uv);
    float motion=clamp(Motion,0.0,1.0);
    if(motion<=0.0){fragColor=vec4(mix(scene.rgb,original.rgb,original.a),scene.a);return;}
    float seconds=GameTime*1200.0*Speed;
    float lane=floor(uv.x*667.0/9.0);
    float direction=uv.x<.5 ? 1.0:-1.0;
    float rate=1.0+floor(hash1(lane+17.0)*3.0);
    vec2 sideUV=vec2(uv.x,fract(uv.y+direction*seconds*rate/6.0));
    vec4 sides=texture(SidesSampler,sideUV);
    vec2 delta=uv-.5;
    float angle=atan(delta.y*400.0,delta.x*667.0);
    float nearest=10.0,index=0.0;
    for(int i=0;i<44;++i){
        float a=angle-RAY_ANGLES[i];float distance=abs(atan(sin(a),cos(a)));
        if(distance<nearest){nearest=distance;index=float(i);}
    }
    float age=fract(seconds*(2.0+mod(index,2.0))+hash1(index+97.0));
    float scale=1.0+.20*age;
    vec4 rays=texture(RaysSampler,.5+delta/scale);
    float flash=smoothstep(0.0,.10,age)*(1.0-smoothstep(.78,1.0,age));
    rays.a*=flash;
    vec3 animated=mix(scene.rgb,sides.rgb,sides.a);
    animated=mix(animated,rays.rgb,rays.a);
    vec3 reference=mix(scene.rgb,original.rgb,original.a);
    fragColor=vec4(mix(reference,animated,motion),scene.a);
}
