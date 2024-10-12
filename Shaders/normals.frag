#version 140

// visualization shader

varying vec3 vNormal;

void main()
{
    // Example color based on normal
    vec3 color = normalize(vNormal) * 0.5 + 0.5;
    gl_FragColor = vec4(color, 1.0);
}
