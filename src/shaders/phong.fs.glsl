#version 330 core

in ATTRIB_VS_OUT
{
    vec2 texCoords;
    vec3 normal;
    vec3 lightDir[3];
    vec3 spotDir[3];
    vec3 obsPos;
} attribIn;

struct Material
{
    vec3 emission;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    float shininess;
};

struct UniversalLight
{
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    vec3 position;
    vec3 spotDirection;
};

layout (std140) uniform LightingBlock
{
    Material mat;
    UniversalLight lights[3];
    vec3 lightModelAmbient;
    bool useBlinn;
    bool useSpotlight;
    bool useDirect3D;
    float spotExponent;
    float spotOpeningAngle;
};

uniform sampler2D diffuseSampler;
uniform sampler2D specularSampler;

out vec4 FragColor;

float attenuation = 1.0;

struct Reflections
{
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};

Reflections calcReflection(in vec3 L, in vec3 N, in vec3 O, float attenuation)
{
    Reflections result = Reflections(
        vec3(0, 0, 0),
        vec3(0, 0, 0),
        vec3(0, 0, 0)
    );


    result.ambient = mat.ambient * 
        ( lightModelAmbient + 
          lights[0].ambient + 
          lights[1].ambient + 
          lights[2].ambient );

    float NdotL = max(0.0, dot(N, L));

    if (NdotL > 0.0)
    {
        result.diffuse = mat.diffuse *
            (lights[0].ambient +
             lights[1].ambient +
             lights[2].ambient) * NdotL * attenuation;

        float spec = (useBlinn ?
            dot(normalize(L + O), N) :
            dot(reflect(-L, N), O));

        if (spec > 0) result.specular = attenuation * mat.specular * ( lights[0].specular + lights[1].specular + lights[2].specular) * pow(spec, mat.shininess);
    }

    return result;
}

void main()
{
    // TODO

    FragColor = texture(diffuseSampler, attribIn.texCoords);

    vec3 L = normalize(attribIn.lightDir[0] + attribIn.lightDir[1] + attribIn.lightDir[2]);
    vec3 N = normalize(gl_FrontFacing ? attribIn.normal : -attribIn.normal);
    vec3 O = normalize(attribIn.obsPos);

    Reflections reflections = calcReflection(L, N, O, attenuation);
    vec4 color = vec4(mat.emission + reflections.ambient + reflections.diffuse + reflections.specular, 1.0f);
    FragColor += clamp(color, 0.0, 1.0);
}
