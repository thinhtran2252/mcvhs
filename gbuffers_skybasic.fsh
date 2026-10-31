#include "lib/Version.glsl"

#include "lib/Common.glsl"

uniform float viewHeight;
uniform float viewWidth;
uniform mat4 gbufferModelView;
uniform vec3 fogColor;
uniform vec3 skyColor;
uniform vec3 cameraPosition;
uniform vec3 sunPosition;

in vec4 starData;

float AddFog(float x, float w)
{
    return w / (x * x + w);
}

vec3 CalculateSkyColor(vec3 pos)
{
    float upDot = dot(pos, gbufferModelView[1].xyz);
    return mix(skyColor, fogColor, AddFog(max(upDot, 0.0), 0.25));
}

vec3 ScreenToView(vec3 screenPos)
{
    vec4 ndcPos = vec4(screenPos, 1.0) * 2.0 - 1.0;
    vec4 tmp = gbufferProjectionInverse * ndcPos;
    return tmp.xyz / tmp.w;
}

/*
const int colorFormat = RGBA32F;
*/

layout(location = 0) out vec4 color;
layout(location = 1) out vec4 outColor1;

void main()
{
    vec3 pos = ScreenToView(vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), 1.0));

    if(starData.a > 0.5)
        color = vec4(starData.rgb, 1.0);
    else
    {
		vec3 albedo = CalculateSkyColor(normalize(pos));
		color = vec4(albedo, 1.0);
		outColor1 = vec4(vec3(1.0),1.0);
    }
}