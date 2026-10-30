#version 330
#extension GL_ARB_separate_shader_objects : require
#include <minecraft:globals.glsl>
uniform sampler2D InSampler;
uniform sampler2D OverlaySampler;
layout(std140) uniform JettConfig { float Motion; float Speed; };
layout(location=0) in vec2 texCoord;
layout(location=0) out vec4 fragColor;

const float TAU=6.28318530718;

float random1(float n) { return fract(sin(n*127.1+31.7)*43758.5453); }

// A ribbon travels completely beyond the screen before its next launch. Its
// tapered head and tail stay attached to the flow, rather than wobbling in place.
float gust(vec2 p,float time,float side,float bundle,float strand) {
    float seed=bundle*17.0+side*79.0;
    float r=random1(seed);
    float cycles=3.0+mod(bundle,2.0);
    float age=fract(time*cycles/8.0+r);
    float head=1.50-age*4.50;
    float length=1.35+random1(seed+3.0)*.75;
    float along=(p.y-head)/length;
    if(along<=0.0||along>=1.0) return 0.0;

    // Neighbouring filaments share the same broad, swept brush stroke.
    // The bends move with each gust; the two banks are deliberately asymmetric.
    float spread=(strand-2.0)*(.006+.003*r);
    float center=.025+bundle*.025+spread;
    center+=.043*sin(along*3.7+r*TAU);
    center+=.023*pow(2.0*p.y-1.0,2.0);
    center+=.009*sin(along*2.0+bundle*1.8+side);
    float taper=pow(max(sin(along*3.14159265),0.0),.80);
    float width=(.003+.013*random1(seed+strand*3.0+8.0))*taper;
    float distance=abs(p.x-center);
    float aa=max(fwidth(distance),.0003);
    float ribbon=1.0-smoothstep(width*.25,width+aa,distance);
    float crest=1.0-smoothstep(aa,aa*2.3,abs(p.x-center+width*.30));
    float opacity=(.070+.100*random1(seed+strand))*taper;
    float veil=(1.0-smoothstep(width,width*3.3+aa,distance))*.13;
    return (ribbon+crest*.06+veil)*opacity;
}

void main() {
    vec4 scene=texture(InSampler,texCoord);
    vec2 uv=vec2(texCoord.x,1.0-texCoord.y);
    float edge=min(uv.x,1.0-uv.x);
    if(edge>=.30) { fragColor=scene; return; }
    vec4 original=texture(OverlaySampler,uv);
    float motion=clamp(Motion,0.0,1.0);
    if(motion<=0.0) {
        fragColor=vec4(mix(scene.rgb,original.rgb,original.a),scene.a);
        return;
    }
    float side=step(.5,uv.x);
    float time=mod(GameTime*1200.0*max(Speed,0.0),8.0);
    vec2 p=vec2(edge,uv.y);
    float density=0.0;
    for(int b=0;b<7;b++)
        for(int s=0;s<5;s++)
            density+=gust(p,time,side,float(b),float(s));
    float mask=1.0-smoothstep(.20,.29,edge);
    float alpha=(1.0-exp(-density))*mask;
    vec3 windColor=vec3(.87,.91,.93);
    vec3 animated=mix(scene.rgb,windColor,alpha);
    vec3 reference=mix(scene.rgb,original.rgb,original.a);
    fragColor=vec4(mix(reference,animated,motion),scene.a);
}
