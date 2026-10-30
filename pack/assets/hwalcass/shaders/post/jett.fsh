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

// Seven overlapping gust banks per side. Every bank contains a wide translucent
// brush stroke and four distinct filaments, with its own upward travel rate.
float gust(vec2 p,float time,float side,float bundle,float strand,float aa) {
    float seed=bundle*17.0+side*79.0;
    float r=random1(seed);
    float cycles=3.0+mod(bundle,3.0);
    float age=fract(time*cycles/8.0+r);
    float head=1.10-age*3.20;
    float length=1.65+random1(seed+3.0)*.32;
    float along=(p.y-head)/length;
    if(along<=0.0||along>=1.0) return 0.0;

    float broad=1.0-step(.5,strand);
    float spread=(strand-2.5)*(.009+.003*r)*(1.0-broad);
    float center=.012+bundle*.026+spread;
    center+=.048*sin(along*5.3+r*TAU);
    center+=.018*sin(along*1.8+bundle*2.0+side);
    center+=.026*pow(2.0*p.y-1.0,2.0);
    // Subtle differences inside each stroke avoid a comb of parallel lines.
    center+=.0035*sin(along*6.0+strand*1.3)*(1.0-broad);
    float taper=pow(max(sin(along*3.14159265),0.0),.65);
    float fineWidth=.0035+.006*random1(seed+strand*3.0+8.0);
    float width=mix(fineWidth,.025+.020*r,broad)*taper;
    float distance=abs(p.x-center);
    float body=1.0-smoothstep(width*.20,width+aa,distance);
    float softness=1.0-smoothstep(width,width*2.1+aa,distance);
    float opacity=mix(.050+.050*random1(seed+strand),.140+.075*r,broad);
    return (body+softness*.09)*opacity*taper;
}

// Foreground wisps pass through the broad banks faster, so several independent
// layers remain legible instead of all wind deforming together.
float wisp(vec2 p,float time,float side,float lane,float aa) {
    float r=random1(lane*19.0+side*113.0+201.0);
    float age=fract(time*(5.0+mod(lane,3.0))/8.0+r);
    float head=1.12-age*2.85;
    float along=(p.y-head)/(1.12+r*.48);
    if(along<=0.0||along>=1.0)return 0.0;
    float taper=pow(max(sin(along*3.14159265),0.0),.8);
    float center=.025+lane*.026+.038*sin(along*3.8+r*TAU);
    center+=.038*pow(2.0*p.y-1.0,2.0);
    float width=(.005+.009*r)*taper;
    return (1.0-smoothstep(width*.1,width+aa,abs(p.x-center)))*taper*(.055+.045*r);
}

void main() {
    vec4 scene=texture(InSampler,texCoord);
    vec2 uv=vec2(texCoord.x,1.0-texCoord.y);
    float edge=min(uv.x,1.0-uv.x);
    float aa=max(fwidth(uv.x),.0003);
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
            density+=gust(p,time,side,float(b),float(s),aa);
    for(int i=0;i<7;i++)density+=wisp(p,time,side,float(i),aa);
    float mask=1.0-smoothstep(.22,.30,edge);
    // More wind area without turning the outer screen into an opaque white wall.
    float alpha=.47*(1.0-exp(-density/.47))*mask;
    vec3 animated=mix(scene.rgb,vec3(.87,.91,.93),alpha);
    vec3 reference=mix(scene.rgb,original.rgb,original.a);
    fragColor=vec4(mix(reference,animated,motion),scene.a);
}
