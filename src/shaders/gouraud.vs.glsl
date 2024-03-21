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

struct Reflections
{
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};

float attenuation = 1.0;

Reflections calcReflection(in vec3 L, in vec3 N, in vec3 O) {
    Reflections result = Reflections(
        vec3(0, 0, 0),
        vec3(0, 0, 0),
        vec3(0, 0, 0)
    );


    result.ambient = mat.ambient *
        (lightModelAmbient +
        lights[0].ambient +
        lights[1].ambient +
        lights[2].ambient);

    float NdotL = max(0.0, dot(N, L));
    if (NdotL > 0.0) {
        result.diffuse = attenuation * mat.diffuse *
            (lights[0].ambient +
            lights[1].ambient +
            lights[2].ambient) * NdotL;
        float spec = (useBlinn ?
            dot(normalize(L + O), N) :
            dot(reflect(-L, N), O));

        if (spec > 0)  result.specular = attenuation * mat.specular *
            (lights[0].specular + lights[1].specular + lights[2].specular) * 
            pow(spec, mat.shininess);
    }

    return result;
}

void main()
{
    // TODO
    gl_Position = mvp * vec4(position, 1.0f);
    attribOut.texCoords = texCoords;
    attribOut.emission = mat.emission + mat.ambient * (lightModelAmbient +
        lights[0].ambient +
        lights[1].ambient +
        lights[2].ambient);
   
    vec3 pos = vec3(mvp * vec4(position, 1.0f));   
    vec3 lumDir = (lights[0].position + lights[1].position + lights[2].position).xyz;
    vec3 obsVec = (-pos);

    vec3 N = normalize(normalMatrix * normal);
    vec3 L = normalize(lumDir);
    vec3 O = normalize(obsVec);

    Reflections reflection = calcReflection(L, N, O);

    //attribOut.ambient = reflection.ambient;
    //attribOut.diffuse = reflection.diffuse;
    //attribOut.specular = reflection.specular;
}
