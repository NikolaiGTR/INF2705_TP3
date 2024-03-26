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
        lightVecs.diffuse = mat.diffuse * light.diffuse * NdotL;

        float spec = (useBlinn ?
            dot(normalize(L + O), N) :
            dot(reflect(-L, N), O));

        if (spec > 0) lightVecs.specular = mat.specular * light.specular * pow(spec, mat.shininess);
    }

    return lightVecs;
}

float calcSpot(in vec3 D, in vec3 L, in vec3 N) {
    float spotFactor = 0.0;
    if (dot(D, N) >= 0) {
        float spotDot = dot(L, D);
        if (spotDot > cos(radians(spotOpeningAngle)))
        {
            if (useDirect3D)
            {
                spotFactor = smoothstep(pow(cos(radians(spotOpeningAngle)), 1.01 + spotExponent/2), cos(radians(spotOpeningAngle)), cos(radians(spotDot)));
            }
            else
            { 
                spotFactor = pow(spotDot, spotExponent);
            }
        }
    }
    return spotFactor;
}

void main()
{
    // TODO

    vec3 N = normalize( attribIn.normal );
    vec3 O = normalize(attribIn.obsPos);
    

    Light lightVecs;
    lightVecs.diffuse = vec3(0);
    lightVecs.specular = vec3(0);

    vec4 color = vec4(mat.emission + mat.ambient * (lightModelAmbient +
        lights[0].ambient +
        lights[1].ambient +
        lights[2].ambient), 1.0f);

    for (int i = 0; i < 3; i++) {
        vec3 L = normalize(attribIn.lightDir[i]);
        vec3 D = normalize(attribIn.spotDir[i]);

        Light temp = calcLight(L, N, O, lights[i]);

        if (useSpotlight)
        {
            float spotFactor = calcSpot(D, L, N);
            color *= spotFactor;
            lightVecs.diffuse += temp.diffuse * calcSpot(D, L, N);
            lightVecs.specular += temp.specular * calcSpot(D, L, N); 
        }
        else {
            lightVecs.diffuse += temp.diffuse;
            lightVecs.specular += temp.specular;
        }
    }

    // La texture fournie écrase la lumière spéculaire bleue et verte
    // Pour les voir, supprimer la multiplication par la texture
    FragColor = texture(diffuseSampler, attribIn.texCoords) * vec4(lightVecs.diffuse, 1.0f);
    FragColor += texture(specularSampler, attribIn.texCoords) * vec4(lightVecs.specular, 1.0f);

    FragColor += color;
}
