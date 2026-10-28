#version 330
#extension GL_ARB_separate_shader_objects : require
#include <minecraft:globals.glsl>
#include <hwalcass:pool_waves.glsl>
uniform sampler2D InSampler;
layout(std140) uniform PoolConfig { float Motion; float Speed; };
layout(location=0) in vec2 texCoord;
layout(location=0) out vec4 fragColor;

float waveHeight(int index,float x,float time) {
    float side=index<5 ? 1.0:-1.0;
    float layer=float(index%5);
    float phase=time*6.28318530718/12.0;
    float shift=side*phase+0.035*(sin(phase*(1.0+mod(layer,2.0))+layer*.83)-sin(layer*.83));
    float height=W_MEAN[index];
    for(int n=0;n<6;++n) {
        float angle=float(n+1)*(x*6.28318530718-shift);
        vec2 c=W_COEFF[index*6+n];
        height+=c.x*cos(angle)+c.y*sin(angle);
    }
    return height;
}
void main() {
    vec4 scene=texture(InSampler,texCoord);
    float edge=min(texCoord.y,1.0-texCoord.y)*720.0;
    if(edge>155.0) {fragColor=scene;return;}
    int side=texCoord.y>.5 ? 0:5;
    float time=GameTime*1200.0*Speed*clamp(Motion,0.0,1.0);
    float aa=max(720.0/ScreenSize.y*.65,.5);
    float previous=0.0;
    vec3 color=W_COLOR[0];
    float outer=0.0;
    for(int layer=0;layer<5;++layer) {
        float boundary=max(waveHeight(side+layer,texCoord.x,time),previous+2.0);
        if(layer<4) color=mix(color,W_COLOR[layer+1],smoothstep(boundary-aa,boundary+aa,edge));
        else outer=boundary;
        previous=boundary;
    }
    float alpha=(130.0/255.0)*(1.0-smoothstep(outer-aa,outer+aa,edge));
    fragColor=vec4(mix(scene.rgb,color,alpha),scene.a);
}
