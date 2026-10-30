#version 330
#extension GL_ARB_separate_shader_objects : require
#include <minecraft:globals.glsl>
uniform sampler2D InSampler;
layout(std140) uniform FireConfig { float Strength; float Speed; float Width; };
layout(location=0) in vec2 texCoord;
layout(location=0) out vec4 fragColor;

const float TAU=6.28318530718;

vec2 gradient(vec2 p) {
    // Only the advected dimension repeats. No repeating strip across an edge.
    p.y=mod(p.y,16.0);
    vec3 q=fract(vec3(p.xyx)*vec3(.1031,.1030,.0973));
    q+=dot(q,q.yxz+33.33);
    return -1.0+2.0*fract((q.xx+q.yz)*q.zy);
}
float noise2(vec2 p) {
    vec2 i=floor(p),f=fract(p),u=f*f*f*(f*(f*6.0-15.0)+10.0);
    return mix(mix(dot(gradient(i),f),dot(gradient(i+vec2(1,0)),f-vec2(1,0)),u.x),
               mix(dot(gradient(i+vec2(0,1)),f-vec2(0,1)),dot(gradient(i+vec2(1)),f-vec2(1)),u.x),u.y);
}
float fbm(vec2 p) {
    float n=0.0,a=.56;
    for(int i=0;i<4;i++) {
        n+=a*noise2(p);
        p=p*2.0+vec2(17.31,5.17);
        a*=.5;
    }
    return .5+n*.85;
}

vec3 fireColor(float heat) {
    vec3 red=vec3(1.0,.11,.002);
    vec3 orange=vec3(1.0,.40,.008);
    vec3 yellow=vec3(1.0,.86,.10);
    vec3 core=vec3(1.0,.99,.66);
    vec3 color=mix(red,orange,smoothstep(.04,.34,heat));
    color=mix(color,yellow,smoothstep(.28,.68,heat));
    return mix(color,core,smoothstep(.64,1.0,heat));
}

vec4 flame(float along,float distance,float phase,float seed,float width) {
    float d=distance/width;
    if(d>=.21)return vec4(0);
    float drift=phase*16.0;
    float sway=.7*sin(phase*TAU+seed);
    vec2 low=vec2(along*7.0+seed+sway,d*12.0-drift);
    vec2 warp=vec2(fbm(low),fbm(low+vec2(19.1,6.7)))-.5;
    vec2 p=vec2(along*18.0+seed+sway,d*23.0-drift)+warp*3.8;
    float billow=fbm(p);
    float detail=fbm(p*2.0+vec2(11.9,3.7));
    float field=1.10-d*10.5+(billow-.5)*2.2+(detail-.5)*.32;
    float shape=smoothstep(-.035,.14,field);
    // Holes and folded hot sheets keep the fire from becoming a solid band.
    float folds=1.0-abs(detail*2.0-1.0);
    float heat=clamp(field*.60+(folds-.55)*.60,0.0,1.0);
    float alpha=shape*(.78+.20*folds);
    alpha*=1.0-smoothstep(.175,.21,d);
    return vec4(fireColor(heat),alpha);
}

void main() {
    vec4 scene=texture(InSampler,texCoord);
    float strength=clamp(Strength,0.0,1.0);
    float width=clamp(Width,.35,1.5);
    float aspect=ScreenSize.x/max(ScreenSize.y,1.0);
    vec2 p=vec2(texCoord.x*aspect,texCoord.y);
    float nearest=min(min(p.x,aspect-p.x),min(p.y,1.0-p.y));
    if(strength<=0.0||nearest>=.21*width) {fragColor=scene;return;}
    float phase=mod(GameTime*1200.0*max(Speed,0.0),8.0)/8.0;
    vec4 bottom=flame(p.x,p.y,phase,1.0,width);
    vec4 top=flame(aspect-p.x,1.0-p.y,phase,37.0,width);
    vec4 left=flame(1.0-p.y,p.x,phase,73.0,width);
    vec4 right=flame(p.y,aspect-p.x,phase,121.0,width);
    // Overlapping emission at the corners, without a diagonal edge-selection seam.
    float sum=bottom.a+top.a+left.a+right.a;
    vec3 color=(bottom.rgb*bottom.a+top.rgb*top.a+left.rgb*left.a+right.rgb*right.a)/max(sum,.00001);
    float alpha=1.0-(1.0-bottom.a)*(1.0-top.a)*(1.0-left.a)*(1.0-right.a);
    fragColor=vec4(mix(scene.rgb,color,alpha*strength),scene.a);
}
