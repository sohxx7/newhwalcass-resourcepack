#version 330
#extension GL_ARB_separate_shader_objects : require
#include <minecraft:globals.glsl>
#include <hwalcass:kasimo_drops.glsl>
uniform sampler2D InSampler;
uniform sampler2D OriginalSampler;
uniform sampler2D DropsSampler;
layout(std140) uniform DropConfig {float Motion;float Speed;};
layout(location=0) in vec2 texCoord;
layout(location=0) out vec4 fragColor;
float hash1(float n){return fract(sin(n*127.1+311.7)*43758.5453);}
void main(){
    vec4 scene=texture(InSampler,texCoord);
    vec2 uv=vec2(texCoord.x,1.0-texCoord.y);
    float motion=clamp(Motion,0.0,1.0);
    if(motion<=0.0){vec4 original=texture(OriginalSampler,uv);fragColor=vec4(mix(scene.rgb,original.rgb,original.a),scene.a);return;}
    vec2 pixel=uv*vec2(1546.0,868.0);
    if(pixel.y>160.0&&pixel.y<680.0){fragColor=scene;return;}
    float phase=GameTime*1200.0*Speed*6.28318530718/6.0;
    vec3 color=scene.rgb;
    for(int i=0;i<DROP_COUNT;++i){
        vec4 box=DROP_BOX[i];
        if(abs(pixel.x-(box.x+box.z*.5))>box.z*.5+8.0)continue;
        float seed=hash1(float(i)+19.0)*6.28318530718;
        float amplitude=5.0+hash1(float(i)+41.0)*7.0;
        float dx=4.5*sin(phase+seed);
        float dy=amplitude*(.78*sin(phase+seed*1.7)+.22*sin(phase*2.0+seed));
        if(box.y<.5)dy=-amplitude*(.5+.5*sin(phase+seed));
        if(box.y+box.w>867.5)dy=amplitude*(.5+.5*sin(phase+seed));
        if(box.x<.5)dx=-abs(dx);
        if(box.x+box.z>1545.5)dx=abs(dx);
        vec2 local=pixel-box.xy-vec2(dx,dy)*motion;
        if(any(lessThan(local,vec2(-.5)))||any(greaterThan(local,box.zw+vec2(.5))))continue;
        vec2 atlasUV=(DROP_ATLAS[i]+local)/1024.0;
        vec4 drop=texture(DropsSampler,atlasUV);
        color=mix(color,drop.rgb,drop.a);
    }
    fragColor=vec4(color,scene.a);
}
