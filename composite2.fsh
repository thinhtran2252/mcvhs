#include "lib/Version.glsl"

#include "lib/Common.glsl"

const bool colortex0MipmapEnabled = true;

#include "lib/TextureIncludes.glsl"

uniform float viewWidth;
uniform float viewHeight;
uniform ivec2 eyeBrightnessSmooth;

uniform vec3 cameraPosition;

uniform float frameTimeCounter;
uniform vec3 previousCameraPosition;

in vec2 texCoord;

/* DRAWBUFFERS:01 */
layout(location = 0) out vec4 outColor0;
layout(location = 1) out vec4 outColor1;

#define USE_STATIC true //[false true]
#define STATIC_STRENGTH 0.2 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

#define USE_LENS_DISTORTION true //[false true]
#define LENS_DISTORTION_STRENGTH 0.01 //[0.01 0.02 0.03 0.04 0.05]

#define ASPECT_RATIO true //[false true]

#define USE_INTERLACING true //[false true]
#define INTERLACING_STRENGTH 20.0 //[5.0 10.0 15.0 20.0 25.0 30.0 35.0 40.0]

#define AUTO_EXPOSURE true //[false true]
#define MANUAL_EXPOSURE 1.0 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

#define USE_MORE_STATIC true //[false true]

vec3 rgb2yuv(vec3 rgb)
{
    float y = 0.299 * rgb.r + 0.587 * rgb.g + 0.114 * rgb.b;
    return vec3(y, 0.493 * (rgb.b - y), 0.877 * (rgb.r - y));
}

vec3 yuv2rgb(vec3 yuv)
{
    float y = yuv.x;
    float u = yuv.y;
    float v = yuv.z;
    
    return vec3
    (
        y + 1.0 / 0.877 * v,
        y - 0.39393 * u - 0.58081 * v,
        y + 1.0 / 0.493 * u
    );
}

void main()
{
    vec2 uv = texCoord;

    if(ASPECT_RATIO)
    {
        uv = vec2
        (
            (uv.x - 0.5) * 1.2 + 0.5,
            uv.y
        );
    }

    if(USE_LENS_DISTORTION)
    {
        uv = uv * 2.0 - 1.0;
        uv *= 1.0 + LENS_DISTORTION_STRENGTH * dot(uv, uv);
        uv = uv * 0.5 + 0.5;
    }

    if(USE_INTERLACING)
    {
        float interlaceOffset = fract(uv.y * (viewHeight / 10.0)) > 0.5 ? 1.0 : 0.0;
        interlaceOffset *= (2.0 / viewWidth);
        interlaceOffset *= length(cameraPosition - previousCameraPosition) * INTERLACING_STRENGTH;
        uv.x += interlaceOffset;
    }

    vec4 inputColour = texture(colortex0, uv);

    if(USE_STATIC)
    {
        ivec2 pixels = ivec2(viewWidth, viewHeight);
        ivec2 pixelCoord = ivec2(texCoord * vec2(pixels));
        pixelCoord = ivec2(floor(vec2(pixelCoord) / 4.0) * 4.0);
        uint pixelIndex = uint(pixelCoord.y * pixels.x + pixelCoord.x);
        uint rnd = pixelIndex + uint(fract(frameTimeCounter) * viewHeight * viewHeight);

        inputColour.rgb = rgb2yuv(inputColour.rgb);
        inputColour.yz += RandomDirection(rnd).xy * STATIC_STRENGTH;
        inputColour.rgb = yuv2rgb(inputColour.rgb);
    }

    inputColour.rgb = (inputColour.rgb + inputColour.rgb) / (2.0 - inputColour.rgb);

    if(AUTO_EXPOSURE)
    {
        float averageLuma = rgb2yuv(textureLod(colortex0, vec2(0.5), 8.0).rgb).x + 0.5;
        inputColour.rgb /= averageLuma;
    }
    inputColour.rgb *= MANUAL_EXPOSURE;

    if(USE_MORE_STATIC)
    {
        float whiteBits = texture(colortex6, texCoord + fract(frameTimeCounter)).r > 0.7 ? 1.0 : 0.0;
        whiteBits *= texture(colortex6, texCoord - fract(frameTimeCounter)).g > 0.6 ? 1.0 : 0.0;
        inputColour.rgb = mix(inputColour.rgb, vec3(1.0), whiteBits);
    }

    inputColour.rgb = clamp(inputColour.rgb, vec3(0.0), vec3(10.0));

    vec3 emissionData = texture(colortex0, uv).rgb;
    vec3 emission = emissionData * smoothstep(1.0, 2.0, length(emissionData));

    if(uv.x < 0.0 || uv.x > 1.0)
    {
        inputColour.rgb = vec3(0.0);
        emission = vec3(0.0);
    }

    outColor0 = inputColour;
    outColor1 = vec4(emission, 1.0);
}