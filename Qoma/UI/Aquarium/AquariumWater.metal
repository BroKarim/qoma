#include <metal_stdlib>
using namespace metal;

// The floor alone is shaded. Creatures are rendered above it so silhouettes stay crisp.
[[ stitchable ]] half4 aquariumWater(float2 position, half4 color, float2 size, float time, float effects) {
    float2 uv = position / max(size, float2(1.0));
    float2 p = position * 0.027;
    float t = time * 0.19;
    float2 warped = p + effects * float2(sin(p.y * 0.8 + t), cos(p.x * 0.7 - t)) * 0.22;
    float2 tile = abs(fract(warped / 1.8) - 0.5);
    float grout = smoothstep(0.476, 0.498, max(tile.x, tile.y));
    float checker = fmod(floor(warped.x / 1.8) + floor(warped.y / 1.8), 2.0);
    float3 base = mix(float3(0.64, 0.84, 0.89), float3(0.78, 0.92, 0.94), uv.y);
    base += checker * 0.013 - grout * 0.025;

    // Two slowly moving interference fields form soft, irregular light ribbons.
    float a = sin(p.x + sin(p.y * 0.91 + t)) + cos(p.y * 1.12 - t * 0.8);
    float b = sin(p.x * 0.73 - p.y * 0.64 + t * 0.6) + cos(p.y * 0.81 + sin(p.x + t));
    float light = pow(max(0.0, 1.0 - abs(a * b)), 18.0);
    base += effects * light * 0.12;
    float edge = pow(max(abs(uv.x - 0.5), abs(uv.y - 0.5)) * 2.0, 9.0);
    base -= edge * 0.065;
    return half4(half3(base), color.a);
}
