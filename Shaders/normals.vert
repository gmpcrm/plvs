#version 140

// visualization shader

// First vertex shader which processes one vertex at a time

attribute vec3 position; // input from glEnableVertexAttribArray(0)
attribute vec3 normal;   // input from glEnableVertexAttribArray(1)
// Remove uvec3 color if not used

uniform mat4 matModelView;

varying vec3 vPosition;
varying vec3 vNormal;

void main()
{
    vPosition = position;
    vNormal   = normal;

    gl_Position = matModelView * vec4(position.xyz, 1.0);
}
