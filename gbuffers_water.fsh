#include "lib/Version.glsl"

#include "lib/Common.glsl"

uniform sampler2D gtexture;
uniform sampler2D specular;
uniform sampler2D normals;
uniform sampler2D lightmap;
uniform sampler2D colortex8;

uniform mat4 gbufferModelView;

uniform vec3 sunPosition;
uniform vec3 skyColor;
uniform vec3 fogColor;
uniform vec3 cameraPosition;

uniform float rainStrength;

uniform float frameTimeCounter;

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
in vec3 entity;

#define LIT_SURFACE

#define WATER_WAVES true //[false true]
#define WAVE_STRENGTH 0.2 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

#include "lib/Lighting.glsl"

void main()
{
    vec4 inputColour = texture(gtexture, texCoord);

    //Cutout transparencey
    if(inputColour.a < 0.1)
    {
        discard;
    }

    vec4 specularData = vec4(0.0, 0.0, 0.0, 1.0);

    vec4 normalData = texture(normals, texCoord);
    //Tangent normals to world space
    normalData.xyz = (normalData.xyz * 2.0 - 1.0) * TBN;

    //waves (only on water)
    if((entity.y > 0.999 && entity.y < 1.001) && WATER_WAVES)
    {
        vec3 normalA = texture(colortex8, (viewDirection + cameraPosition).xz * 0.02 + frameTimeCounter * 0.05).rgb * 2.0 - 1.0;
        vec3 normalB = texture(colortex8, (viewDirection + cameraPosition).xz * 0.1 - frameTimeCounter * 0.1).rgb * 2.0 - 1.0;
        normalData.xyz = normalize(vec3(normalA.xy * normalB.z + normalB.xy * normalA.z, normalA.z * normalB.z));
        normalData.xyz = mix(normal, normalData.xyz * TBN, WAVE_STRENGTH);
    }

    //sRGB to linear
    inputColour.rgb = pow(inputColour.rgb, vec3(2.2));
    inputColour.rgb *= pow(vertexColour, vec3(2.2));
    vec3 baseColour = inputColour.rgb;

    if(BASIC_LIGHTING)
    {
        vec3 sunDir = normalize(vec4(sunPosition, 1.0) * gbufferModelView).xyz;
        inputColour.rgb *= max(0.0, dot(normalData.xyz, sunDir));
        inputColour.rgb *= pow(lightMapCoord.y, 3.0);
        inputColour.rgb += baseColour * pow(lightMapCoord.x, 3.0);
    }

    // Linear to sRGB
    inputColour.rgb = pow(inputColour.rgb, vec3(1.0 / 2.2));
    baseColour = pow(baseColour, vec3(1.0 / 2.2));

    outColor0 = inputColour;
    outColor1 = specularData;
    outColor2 = normalData * 0.5 + 0.5;
    outColor3 = vec4(lightMapCoord, 0.0, 0.0);
    outColor4 = vec4(baseColour, 1.0);
    outColor5 = vec4(normal * 0.5 + 0.5, 1.0);
}