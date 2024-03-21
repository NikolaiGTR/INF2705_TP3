#version 330 core

in ATTRIB_VS_OUT
{
    vec2 texCoords;
    vec3 emission;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
} attribIn;

uniform sampler2D diffuseSampler;
uniform sampler2D specularSampler;

out vec4 FragColor;

void main()
{

    vec4 col = vec4(attribIn.emission + attribIn.ambient, 1.0f);
    FragColor = texture(diffuseSampler, attribIn.texCoords) * vec4(attribIn.diffuse, 1.0f);
    FragColor += texture(specularSampler, attribIn.texCoords) * vec4(attribIn.specular, 1.0f);
    
    FragColor += col;
    
}
