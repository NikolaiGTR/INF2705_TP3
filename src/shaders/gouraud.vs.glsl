#version 330 core

layout (location = 0) in vec3 position;
layout (location = 1) in vec2 texCoords;
layout (location = 2) in vec3 normal;

out ATTRIB_VS_OUT
{
    vec2 texCoords;
    vec3 emission;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
} attribOut;

uniform mat4 mvp;
uniform mat4 view;
uniform mat4 modelView;
uniform mat3 normalMatrix;

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

struct Light
{
    vec3 diffuse;
    vec3 specular;
};


Light calcLight(in vec3 L, in vec3 N, in vec3 O, UniversalLight light) {
    Light result = Light(
        vec3(0, 0, 0),
        vec3(0, 0, 0)
    );

    float NdotL = max(0.0, dot(N, L));
    if (NdotL > 0.0) {
        result.diffuse = mat.diffuse * light.diffuse * NdotL;

        float spec = (useBlinn ?
            dot(normalize(L + O), N) :
            dot(reflect(-L, N), O));

        if (spec > 0) result.specular = mat.specular * light.specular * pow(spec, mat.shininess);
    }

    return result;
}

void main()
{
    // TODO
    gl_Position = mvp * vec4(position, 1.0f);

    attribOut.texCoords = texCoords;
    attribOut.emission = mat.emission;

    attribOut.ambient = mat.ambient * (lightModelAmbient +
        lights[0].ambient +
        lights[1].ambient +
        lights[2].ambient);

    vec3 pos = vec3(modelView * vec4(position, 1.0f));
    vec3 obsVec = (-pos);

    attribOut.diffuse = vec3(0);
    attribOut.specular = vec3(0);
    vec3 N = normalize(normalMatrix * normal);
    vec3 O = normalize(obsVec);

    for (int i = 0; i < 3; i++)
    {
        vec3 lumDir = (view * vec4(lights[i].position, 1.0f)).xyz - pos;        
        vec3 L = normalize(lumDir);
        
        Light lightVecs = calcLight(L, N, O, lights[i]);

        attribOut.diffuse += lightVecs.diffuse;
        attribOut.specular += lightVecs.specular;
    }
    
}
