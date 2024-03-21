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


struct Light
{
    vec3 diffuse;
    vec3 specular;
};

Light calcLight(in vec3 L, in vec3 N, in vec3 O, UniversalLight light)
{
    Light lightVecs = Light(
        vec3(0, 0, 0),
        vec3(0, 0, 0)
    );

    float NdotL = max(0.0, dot(N, L));

    if (NdotL > 0.0)
    {
        lightVecs.diffuse = mat.diffuse *
            light.diffuse * NdotL;

        float spec = (useBlinn ?
            dot(normalize(L + O), N) :
            dot(reflect(-L, N), O));

        if (spec > 0) lightVecs.specular = mat.specular * light.specular * pow(spec, mat.shininess);
    }

    return lightVecs;
}

void main()
{
    // TODO

    //FragColor = texture(diffuseSampler, attribIn.texCoords) + texture(specularSampler, attribIn.texCoords);

    vec3 N = normalize(gl_FrontFacing ? attribIn.normal : -attribIn.normal);
    vec3 O = normalize(attribIn.obsPos);

    Light lightVecs;
    lightVecs.diffuse = vec3(0);
    lightVecs.specular = vec3(0);

    for (int i = 0; i < 3; i++) {
        //vec3 lumDir = lights[i].position + attribIn.obsPos;
        vec3 L = normalize(attribIn.lightDir[i]);
        Light temp = calcLight(L, N, O, lights[i]);

        lightVecs.diffuse += temp.diffuse;
        lightVecs.specular += temp.specular;
    }
    
    //vec4 color = vec4(mat.emission + lightVecs.ambient + lightVecs.diffuse + lightVecs.specular, 1.0f);
    vec4 color = vec4(mat.emission + mat.ambient * (lightModelAmbient +
        lights[0].ambient +
        lights[1].ambient +
        lights[2].ambient), 1.0f);

    FragColor = texture(diffuseSampler, attribIn.texCoords) * vec4(lightVecs.diffuse, 1.0f);
    FragColor += texture(specularSampler, attribIn.texCoords) * vec4(lightVecs.specular, 1.0f);
    FragColor += clamp(color, 0.0, 1.0);
}
