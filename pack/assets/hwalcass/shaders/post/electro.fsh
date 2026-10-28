#version 330
#extension GL_ARB_separate_shader_objects : require
#include <minecraft:globals.glsl>
#include <hwalcass:electro_noise.glsl>
layout(std140) uniform ElectroConfig {
    float Intensity;
    float EdgeHeight;
    float Speed;
    float Distortion;
};
layout(location=0) in vec2 texCoord;
layout(location=0) out vec4 fragColor;
float rough(float x,float seed) {
    return mix(random2(vec2(floor(x),seed)),random2(vec2(floor(x)+1.0,seed)),fract(x))*2.0-1.0;
}
float route(float x,float seed) {
    float base=0.070+random2(vec2(seed,401.0))*0.050;
    return base+rough(x*3.5,seed)*0.075
               +rough(x*10.3,seed+17.0)*0.026
               +rough(x*31.7,seed+109.0)*0.008;
}
vec2 leader(float index,float seed) {
    float x=(index+(random2(vec2(index,seed+43.0))-0.5)*1.65)*0.035;
    float y=route(x,seed)+(random2(vec2(index,seed+57.0))-0.5)*0.028;
    return vec2(x,y);
}
vec3 arcLight(float d,float width,float pixel,float power) {
    float core=1.0-smoothstep(width*0.30,width+pixel*0.5,d);
    float corona=exp(-d/(width*2.4));
    float glow=exp(-d/0.010);
    return power*(vec3(0.92,1.0,0.84)*core*3.8
                 +vec3(0.020,0.75,0.040)*corona*0.80
                 +vec3(0.004,0.15,0.012)*glow*0.23);
}
vec2 branchPoint(int joint,vec2 root,float lengthX,float bend,float seed) {
    float u=float(joint)/7.0;
    float x=root.x+u*lengthX;
    float y=root.y+bend*u;
    float taper=1.0-abs(u*2.0-1.0);
    y+=rough(u*4.3,seed+71.0)*0.032*taper;
    x+=rough(u*6.1,seed+91.0)*0.036*taper;
    return vec2(x,y);
}
void main() {
    float edge=min(texCoord.y,1.0-texCoord.y);
    float height=clamp(EdgeHeight,0.10,0.30);
    if(edge>=height || Intensity<=0.0) { fragColor=vec4(0); return; }
    float side=step(0.5,texCoord.y);
    float time=GameTime*1200.0*Speed;
    float aspect=ScreenSize.x/max(ScreenSize.y,1.0);
    float pixel=1.0/max(ScreenSize.y,1.0);
    vec2 p=vec2(texCoord.x*aspect,edge/(height/0.24));
    float fade=1.0-smoothstep(height*0.77,height,edge);
    vec3 radiance=vec3(0);
    float coverage=0.0;
    for(int channel=0;channel<3;++channel) {
        float id=float(channel)+side*11.0;
        float phase=time*(5.3+float(channel)*0.63)+id*0.417;
        float epoch=floor(phase),age=fract(phase);
        float seed=epoch*29.0+id*137.0;
        float flash=exp(-age*4.8);
        float strength=(channel==0 ? 1.15 : 0.72)*(0.64+flash*0.94);
        float width=(channel==0 ? 0.0019 : 0.00125)*(1.0+flash*0.40);
        float nearest=10.0;
        float knot=floor(p.x/0.035);
        for(int offset=-2;offset<=2;++offset) {
            float k=knot+float(offset);
            vec2 a=leader(k,seed),b=leader(k+1.0,seed);
            float localWidth=width*(0.57+random2(vec2(floor(k/4.0),seed+307.0))*0.82);
            vec2 d=b-a;
            vec2 normal=normalize(vec2(-d.y,d.x));
            vec2 mid=a+d*0.43+normal*(random2(vec2(k,seed+997.0))-0.5)*0.011;
            float distanceToLeader=min(segmentDistance(p,a,mid),segmentDistance(p,mid,b));
            nearest=min(nearest,distanceToLeader*width/localWidth);
        }
        float charge=0.65+0.65*(rough(p.x*8.0,seed+301.0)*0.5+0.5);
        radiance+=arcLight(nearest,width,pixel,strength*charge);
        coverage=max(coverage,exp(-nearest/0.007)*strength*0.62);
        if(channel<2) {
            float cell=floor(p.x/0.48);
            for(int neighbor=-1;neighbor<=1;++neighbor) {
                float branchId=cell+float(neighbor);
                if(random2(vec2(branchId,seed+607.0))<0.28) continue;
                float rootK=floor((branchId*0.48+0.10+random2(vec2(branchId,seed+509.0))*0.24)/0.035);
                vec2 root=leader(rootK,seed);
                float direction=random2(vec2(branchId,seed+809.0))<0.5 ? -1.0 : 1.0;
                float span=direction*(0.20+random2(vec2(branchId,seed+907.0))*0.19);
                float bend=0.040+random2(vec2(branchId,seed+701.0))*0.080;
                float bSeed=seed+branchId*53.0,dist=10.0;
                float progress=clamp((p.x-root.x)/span,0.0,1.0);
                float branchWidth=width*mix(0.90,0.22,progress);
                vec2 previous=root;
                for(int joint=1;joint<=7;++joint) {
                    vec2 next=branchPoint(joint,root,span,bend,bSeed);
                    dist=min(dist,segmentDistance(p,previous,next));previous=next;
                }
                radiance+=arcLight(dist,branchWidth,pixel,strength*pow(1.0-progress,0.55)*0.90);
            }
        }
    }
    radiance*=Intensity*fade;
    fragColor=vec4(1.0-exp(-radiance*0.9),clamp(coverage*fade,0.0,1.0));
}
