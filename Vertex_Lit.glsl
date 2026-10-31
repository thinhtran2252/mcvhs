#include "Version.glsl"

in vec3 vaPosition;
in vec2 vaUV0;
in vec4 vaColor;
in ivec2 vaUV2;
in vec3 vaNormal;
in vec4 at_tangent;
in vec3 mc_Entity;

uniform vec3 chunkOffset;
uniform mat4 projectionMatrix;
uniform mat4 modelViewMatrix;

out vec2 texCoord;
out vec2 lightMapCoord;
out vec4 vertexColour;
out vec3 tangent;
out vec3 normal;
out vec3 binormal;
out mat3 TBN;
out vec3 viewDirection;
out vec3 entity;

void main()
{
    texCoord = vaUV0;
    lightMapCoord = vaUV2 * (1.0 / 256.0) + (1.0 / 32.0);

    vertexColour = vaColor;

    tangent = normalize(at_tangent.xyz);
    normal = normalize(vaNormal);
    binormal = normalize(cross(normal, tangent));
    TBN = mat3
    (
        tangent.x, binormal.x, normal.x,
        tangent.y, binormal.y, normal.y,
        tangent.z, binormal.z, normal.z
    );

    vec3 position = vaPosition + chunkOffset;
    viewDirection = position;

    entity = mc_Entity;

    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}