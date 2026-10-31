#define PI 3.14159274
#define I_PI 0.31830989
#define TWO_PI 6.28318530
#define I_TWO_PI 0.15915494

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

float saturate(float x) { return clamp(x, 0.0, 1.0); }
vec2 saturate(vec2 xy) { return clamp(xy, vec2(0.0), vec2(1.0)); }
vec3 saturate(vec3 xyz) { return clamp(xyz, vec3(0.0), vec3(1.0)); }

float linearizeDepth(float depth, float near, float far) 
{
    return (near * far) / (depth * (near - far) + far);
}

vec3 WorldPositionFromDepth(float depth, vec2 uv)
{
    vec3 positionCS = vec3(uv, depth) * 2.0 - 1.0;
    vec4 positionVS = gbufferProjectionInverse * vec4(positionCS, 1.0);
    positionVS.xyz /= positionVS.w;
    vec3 positionWS = (gbufferModelViewInverse * positionVS).xyz;
    return positionWS;
}

vec3 WorldPositionFromDepth(float depth, vec2 uv, out vec3 viewPos)
{
    vec3 positionCS = vec3(uv, depth) * 2.0 - 1.0;
    vec4 positionVS = gbufferProjectionInverse * vec4(positionCS, 1.0);
    positionVS.xyz /= positionVS.w;
    viewPos = positionVS.xyz;
    vec3 positionWS = (gbufferModelViewInverse * positionVS).xyz;
    return positionWS;
}

float RandomValue(inout uint state)
{
    state = state * 747796405u + 2891336453u;
    uint result = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
    result = (result >> 22u) ^ result;
    state *= result;
    return float(result) / 4294967295.0;
}

float RandomValueNormalDistribution(inout uint n)
{
    float theta = 2.0 * PI * RandomValue(n);
    float rho = sqrt(-2.0 * log(RandomValue(n)));
    n += uint(rho * cos(theta));
    return rho * cos(theta);
}

vec3 RandomDirection(inout uint n)
{
    float x = RandomValueNormalDistribution(n);
    float y = RandomValueNormalDistribution(n);
    float z = RandomValueNormalDistribution(n);
    return normalize(vec3(x, y, z));
}

#define PRESET