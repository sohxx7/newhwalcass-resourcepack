#version 330
#extension GL_ARB_separate_shader_objects : require
#include <minecraft:globals.glsl>
uniform sampler2D InSampler;
uniform sampler2D OverlaySampler;
layout(std140) uniform JettConfig { float Motion; float Speed; };
layout(location=0) in vec2 texCoord;
layout(location=0) out vec4 fragColor;

void main() {
    vec4 scene=texture(InSampler,texCoord);
    vec2 uv=vec2(texCoord.x,1.0-texCoord.y);
    float edge=min(uv.x,1.0-uv.x);
    if(edge>=.31) { fragColor=scene; return; }
    float right=step(.5,uv.x);
    float side=mix(-1.0,1.0,right);
    float time=GameTime*1200.0*Speed;
    float phase=time*6.28318530718/6.0;
    float sidePhase=right*1.9;
    float y=uv.y;
    // Large soft billows travel upward, with a smaller, faster ripple on each side.
    // All time harmonics share a seamless six-second cycle; there is no texture reset.
    float billow=.012*sin(y*6.28318530718*1.15+phase+sidePhase)
                +.004*sin(y*6.28318530718*2.7+phase*2.0+sidePhase*.7)
                +.0012*sin(y*6.28318530718*5.8+phase*3.0+sidePhase);
    float flow=.024*sin(y*6.28318530718*.8+phase+sidePhase+.8);
    float weight=clamp(Motion,0.0,1.0)*(1.0-smoothstep(.22,.30,edge));
    vec2 sampleUV=uv;
    sampleUV.x+=side*billow*weight;
    // Pin the top and bottom to avoid seams or exposing the texture's cut edges.
    sampleUV.y+=flow*(4.0*y*(1.0-y))*weight;
    sampleUV=clamp(sampleUV,vec2(0),vec2(1));
    vec4 wind=texture(OverlaySampler,sampleUV);
    fragColor=vec4(mix(scene.rgb,wind.rgb,wind.a),scene.a);
}
