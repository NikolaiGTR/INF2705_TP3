#version 330 core

layout (location = 0) in vec3 position;
layout (location = 2) in vec3 normal;

uniform mat4 mvp;

float growthFactor = 0.1f;

void main()
{
    // TODO
    position = position + (normalize(normal) * growthFactor);
    gl_Position = mvp * vec4(position, 1.0f);
}
 