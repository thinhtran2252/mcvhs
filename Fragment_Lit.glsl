#include "Version.glsl"

#include "Common.glsl"

uniform sampler2D gtexture;
uniform sampler2D specular;
uniform sampler2D normals;
uniform sampler2D lightmap;

uniform mat4 gbufferModelView;

uniform vec3 sunPosition;
uniform vec3 skyColor;
uniform vec3 fogColor;

uniform float rainStrength;

/*
const int colortex0Format = RGBA32F;
*/

/* DRAWBUFFERS:012345 */
layout(location = 0) out vec4 outColor0; // Colour
layout(location = 1) out vec4 outColor1; // Specular Data
layout(location = 2) out vec4 outColor2; // Normal Data
layout(location = 3) out vec4 outColor3; // Lightmap
layout(location = 4) out vec4 outColor4; // Base Colour
layout(location = 5) out vec4 outColor5; // Geo Normals

in vec2 texCoord;
in vec2 lightMapCoord;
in vec3 vertexColour;
in vec3 tangent;
in vec3 normal;
in vec3 binormal;
in mat3 TBN;
in vec3 viewDirection;

#define BLOCK_LIGHT_FALLOFF 3.0 //[1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0]
#define BLOCK_LIGHT_STRENGTH 2.0 //[0.5 1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0]

#define LIT_SURFACE

#define TEXTURE_EMISSION true //[false true]
#define EMISSION_STRENGTH 2.0 //[1.0 2.0 3.0 4.0 5.0]

#include "Lighting.glsl"

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
    vec4 inputColour = texture(gtexture, texCoord);

    //Cutout transparencey
    if(inputColour.a < 0.1)
    {
        discard;
    }

    vec4 specularData = texture(specular, texCoord);
    //Perceptual smoothness to roughness
    specularData.x = pow(1.0 - specularData.x, 2.0);

    vec4 normalData = texture(normals, texCoord);
    //Tangent normals to world space
    normalData.xyz = (normalData.xyz * 2.0 - 1.0) * TBN;

    //sRGB to linear
    inputColour.rgb = pow(inputColour.rgb, vec3(2.2));
    vec3 baseColour = inputColour.rgb * pow(vertexColour, vec3(2.2));
    
    if(BASIC_LIGHTING)
    {
        inputColour.rgb *= pow(vertexColour, vec3(2.2));

        vec3 sunDir = normalize(vec4(sunPosition, 1.0) * gbufferModelView).xyz;
        vec3 diffuse = saturate(dot(normalData.xyz, sunDir)) * 2.0 + skyColor * 0.5;

        float sunHeightMask = pow(max(sunDir.y, 0.0), 0.25);

        inputColour.rgb = inputColour.rgb * diffuse;

        inputColour.rgb *= pow(lightMapCoord.y, 3.0) * sunHeightMask;

        inputColour.rgb += baseColour * pow(lightMapCoord.x, BLOCK_LIGHT_FALLOFF) * BLOCK_LIGHT_STRENGTH;
    }
    else
    {
        //Get basic minecraft lighting
        vec3 lightColour = pow(texture(lightmap, lightMapCoord).rgb, vec3(2.2));

        //Apply vertex colours (grass, AO, etc...) & lighting
        inputColour.rgb *= pow(vertexColour, vec3(2.2)) * lightColour;
    }

    float rainMask = rainStrength * pow(lightMapCoord.y, 5.0);
    specularData.x = mix(specularData.x, 0.0, rainMask);
    //specularData.y = mix(specularData.y, 0.5, rainMask);
    inputColour.rgb *= mix(1.0, 0.25, rainMask);
    normalData.xyz = mix(normalData.xyz, normal, rainMask);

    if(TEXTURE_EMISSION)
    {
        float emission = specularData.a;
        if(emission > 0.997) emission = 0.0;
        inputColour.rgb += baseColour * emission * EMISSION_STRENGTH;
        baseColour *= emission * EMISSION_STRENGTH + 1.0;
    }

    // Linear to sRGB
    inputColour.rgb = pow(inputColour.rgb, vec3(1.0 / 2.2));
    baseColour = pow(baseColour, vec3(1.0 / 2.2));

    //[-1, 1] to [0, 1] Normals
    normalData.xyz = normalData.xyz * 0.5 + 0.5;

    outColor0 = inputColour;
    outColor1 = specularData;
    outColor2 = normalData;
    outColor3 = vec4(lightMapCoord, 0.0, 0.0);
    outColor4 = vec4(baseColour, 1.0);
    outColor5 = vec4(normal * 0.5 + 0.5, 1.0);
}