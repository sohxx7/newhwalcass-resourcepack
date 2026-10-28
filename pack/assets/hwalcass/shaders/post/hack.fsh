#version 330
#extension GL_ARB_separate_shader_objects : require
#include <minecraft:globals.glsl>

uniform sampler2D InSampler;
uniform sampler2D OverlaySampler;
layout(std140) uniform HackConfig {
    float Motion;
    float Speed;
};
layout(location=0) in vec2 texCoord;
layout(location=0) out vec4 fragColor;

float hash1(float n) {
    return fract(sin(n*127.1+311.7)*43758.5453);
}
void main() {
    vec4 scene=texture(InSampler,texCoord);
    vec2 uv=vec2(texCoord.x,1.0-texCoord.y);
    vec4 original=texture(OverlaySampler,uv);
    if(original.a<=0.0) { fragColor=scene; return; }
    float seconds=GameTime*1200.0*Speed;
    float motion=clamp(Motion,0.0,1.0);
    float y=uv.y*1024.0;

    // Rectangular rows slide independently. No sinusoidal screen distortion.
    float row=floor(y/22.0);
    float direction=hash1(row+19.0)<.5 ? -1.0:1.0;
    float drift=seconds*direction*(10.0+hash1(row+51.0)*18.0);
    float narrowRow=floor(y/6.0);
    float beat=seconds*2.6+hash1(narrowRow+97.0);
    float event=floor(beat);
    float enabled=step(.79,hash1(narrowRow*13.0+event*7.0));
    float kick=(hash1(narrowRow*17.0+event*23.0)-.5)*30.0;
    float burst=enabled*(1.0-smoothstep(.04,.24,fract(beat)));
    float offset=(drift+kick*burst)*motion;
    vec2 sampleUV=vec2(fract(uv.x+offset/1536.0),uv.y);
    vec4 moved=texture(OverlaySampler,sampleUV);

    // Keep the reference silhouette and its alpha, including the thin stray scan lines.
    // Near transparent source edges, fall back to the original color instead of importing black.
    float valid=smoothstep(.01,.18,moved.a);
    vec3 color=mix(original.rgb,moved.rgb,valid);
    fragColor=vec4(mix(scene.rgb,color,original.a),scene.a);
}
