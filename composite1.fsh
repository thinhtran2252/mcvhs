#include "lib/Version.glsl"

const bool colortex0MipmapEnabled = true;

#include "lib/Common.glsl"
#include "lib/TextureIncludes.glsl"

uniform float viewWidth;
uniform float viewHeight;
uniform float near;
uniform float far;
uniform vec3 cameraPosition;
uniform vec3 skyColor;
uniform vec3 fogColor;

uniform mat4 gbufferProjection;
uniform mat4 gbufferModelView;

uniform int isEyeInWater;

in vec2 texCoord;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 outColor0;

#define SSR false //[false true]
#define SSR_STEPS 32 //[8 16 32 64 128 256]
#define REFLECT_SKY true //[false true]

vec3 fresnelSchlick(float cosTheta, vec3 F0)
{
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

float AddFog(float x, float w)
{
    return w / (x * x + w);
}

vec3 CalculateSkyColor(vec3 pos)
{
    float upDot = dot(pos, gbufferModelView[1].xyz);
    return mix(skyColor, fogColor, AddFog(max(upDot, 0.0), 0.25));
}

void main()
{
    vec4 inputColour = texture(colortex0, texCoord);

    float depth = texture(depthtex0, texCoord).r;
    float linDepth = linearizeDepth(depth, near, far);

    ivec2 pixels = ivec2(viewWidth, viewHeight);
    ivec2 pixelCoord = ivec2(texCoord * vec2(pixels));
    uint pixelIndex = uint(pixelCoord.y * pixels.x + pixelCoord.x);
    uint rnd = pixelIndex;
    
    //r = roughness g = metallic b = ??? a = emission
    vec4 specularData = texture(colortex1, texCoord);
    //rgb = normal[0-1] a = height?
    vec4 normalData = texture(colortex2, texCoord);
    normalData.xyz = normalData.xyz * 2.0 - 1.0;
    vec3 normalVS = (vec4(normalData.xyz, 1.0) * gbufferModelViewInverse).xyz;

    vec3 geoNormal = texture(colortex5, texCoord).rgb * 2.0 - 1.0;
    vec3 geoNormalVS = (vec4(geoNormal, 1.0) * gbufferModelViewInverse).xyz;

    vec3 positionCS = vec3(texCoord, depth) * 2.0 - 1.0;
    vec4 positionVS = gbufferProjectionInverse * vec4(positionCS, 1.0);
    positionVS.xyz /= positionVS.w;
    //Centered around camera
    vec3 positionWS = (gbufferModelViewInverse * positionVS).xyz;
    //Get view direction here, rather than calculate it somewhere else
    vec3 viewDir = normalize(positionWS);
    //Now its actually in world space
    positionWS += cameraPosition;

    vec3 worldReflection = reflect(viewDir, normalData.xyz);

    //Raymarching stuff

    vec3 reflectionColour = REFLECT_SKY ? CalculateSkyColor(worldReflection) : vec3(0);
    if(positionCS.z != 1.0 && specularData.x < 0.9 && SSR)
    {
        float stepSize = 1.0 / float(SSR_STEPS);

        vec3 rayOrigin = positionVS.xyz + geoNormalVS * stepSize;
        vec3 rayDir = reflect(normalize(positionVS.xyz), normalVS);

        for(int i = 0; i < SSR_STEPS; i++)
        {
            //add a little offset to the step size to cover a larger area
            stepSize += RandomValue(rnd) * stepSize;

            rayOrigin += rayDir * stepSize;

            vec4 rayPositionHS = gbufferProjection * vec4(rayOrigin, 1.0);
            vec3 rayPositionNDC = rayPositionHS.xyz / rayPositionHS.w;
            vec3 rayPositionSS = rayPositionNDC * 0.5 + 0.5;

            float depthAtRay = texture(depthtex0, rayPositionSS.xy).r;
            float linearDepthAtRay = linearizeDepth(depthAtRay, near, far);
            float linearRayDepth = linearizeDepth(rayPositionSS.z, near, far);

            if(abs(rayPositionSS.x - 0.5) > 0.5 || abs(rayPositionSS.y - 0.5) > 0.5)
            {
                break;
            }

            if(depthAtRay != 1.0 && linearRayDepth > linearDepthAtRay && abs(linearRayDepth - linearDepthAtRay) < stepSize)
            {
                reflectionColour = texture(colortex0, rayPositionSS.xy).rgb;
                break;
            }
        }
    }
    if(positionCS.z != 1.0 && (REFLECT_SKY || SSR))
    {
        //Mask based on roughness.
        reflectionColour *= (1.0 - specularData.x);

        float refractive_ratio = isEyeInWater == 1 ? 1.0 / 1.45 : 1.333;
        float cos_critical = refractive_ratio < 1.0 ?
            sqrt(1.0 - refractive_ratio * refractive_ratio) :
            0.0;

        vec3 F0 = vec3(0.04);
        float fresnel = saturate(fresnelSchlick(max(0.0, dot(-viewDir, normalData.xyz)), F0)).g;
        if(isEyeInWater != 1)
            fresnel = mix(fresnel, 0.0, specularData.x);

        inputColour.rgb = mix
        (
            mix(inputColour.rgb, reflectionColour, fresnel),
            inputColour.rgb * reflectionColour,
            specularData.y
        );
    }

    outColor0 = inputColour;
}