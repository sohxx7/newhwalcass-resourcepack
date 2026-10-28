#ifndef HWALCASS_ELECTRO_NOISE
#define HWALCASS_ELECTRO_NOISE
uint scramble(uint n) {
    n^=n>>16u; n*=0x7feb352du; n^=n>>15u; n*=0x846ca68bu;
    return n^(n>>16u);
}
float random2(vec2 p) {
    uvec2 cell=uvec2(ivec2(floor(p)));
    return float(scramble(cell.x^scramble(cell.y+7919u))>>8u)/16777216.0;
}
vec2 randomPair(vec2 p) { return vec2(random2(p),random2(p+vec2(137,311))); }
float segmentDistance(vec2 p,vec2 a,vec2 b) {
    vec2 delta=b-a;
    float u=clamp(dot(p-a,delta)/max(dot(delta,delta),.000001),0,1);
    return length(p-a-delta*u);
}
#endif
