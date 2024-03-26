#version 330 core

layout(triangles) in;
layout(triangle_strip, max_vertices = 3) out;

in ATTRIB_OUT
{
    vec3 position;
    vec2 texCoords;
} attribIn[];

out ATTRIB_VS_OUT
{
    vec2 texCoords;    
    vec3 emission;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
} attribOut;

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
        float delta = cos(radians(spotOpeningAngle));
        if (spotDot > delta)
        {
            if (useDirect3D)
            {
                spotFactor = smoothstep(pow(delta, 1.01 + spotExponent / 2), delta, spotDot);
            }
            else
            { 
                spotFactor = pow(spotDot, spotExponent);
            }
        }
    }
    return spotFactor;
}

vec3 getNormalVector(){
   vec3 a = vec3(attribIn[0].position) - vec3(attribIn[1].position);
   vec3 b = vec3(attribIn[2].position) - vec3(attribIn[1].position);
   return -cross(a,b);
}

void main()
{
    
    Light lightInfo;
    
    vec3 normal=normalMatrix*getNormalVector();
    vec3 obsPos=vec3(modelView * vec4((attribIn[0].position+attribIn[1].position+attribIn[2].position)/3, 1.0f));
    
    vec3 N = normalize(normal);
    vec3 O = normalize(-obsPos);
    for (int i = 0; i < 3; i++) {
        vec3 L = normalize(vec3(view * vec4(lights[i].position, 1.0f)).xyz - obsPos);
        vec3 D = normalize(mat3(view) * -lights[i].spotDirection);

        Light temp = calcLight(L, N, O, lights[i]);

        if (useSpotlight)
        {
            float spotFactor = calcSpot(D, L, N);
            lightInfo.diffuse += temp.diffuse * calcSpot(D, L, N);
            lightInfo.specular += temp.specular * calcSpot(D, L, N); 
        }
        else {
            lightInfo.diffuse += temp.diffuse;
            lightInfo.specular += temp.specular;
        }
    }

    attribOut.texCoords = attribIn[0].texCoords;
    attribOut.emission=vec3(mat.emission);
    attribOut.ambient=vec3(mat.ambient * (lightModelAmbient +
        lights[0].ambient +
        lights[1].ambient +
        lights[2].ambient));
    attribOut.diffuse=lightInfo.diffuse;
    attribOut.specular=lightInfo.specular;

    for( int i = 0 ; i<gl_in.length() ; i++){
       gl_Position= gl_in[i].gl_Position;
       EmitVertex();
    }
    
}
