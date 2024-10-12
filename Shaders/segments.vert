#version 140

// visualization shader

attribute vec3 position; // Input vertex position
attribute vec2 label;    // Now using vec2 of floats

uniform mat4 matModelView;

varying vec3 vColor;
varying float vLabel;
varying float vLabelConfidence;

// Constants remain the same (ensure they are floats)
const float ICOLOR = 5.0;
const float DELTACOLOR = (256.0 / ICOLOR);
const float minColorVal = 256.0 / ICOLOR;
const float rangeColor = (256.0 / ICOLOR) * (ICOLOR - 1.0);
const float PRIME_NUMBER = 997.0;

vec3 decodeColor(float c)
{
    if (c == 0.0)
        return vec3(0.0, 0.0, 0.0);

    float numColor = (c * PRIME_NUMBER);

    vec3 col;
    col.r = minColorVal + mod(numColor, rangeColor);
    numColor = floor(numColor / rangeColor);
    col.g = minColorVal + mod(numColor, rangeColor);
    numColor = floor(numColor / rangeColor);
    col.b = minColorVal + mod(numColor, rangeColor);
    return col / 255.0; // Normalize color components
}

void main()
{
    float labelValue = label.x;
    float labelConfidenceValue = label.y;

    vColor = decodeColor(labelValue);
    vLabel = labelValue;
    vLabelConfidence = labelConfidenceValue;

    gl_Position = matModelView * vec4(position, 1.0);
}
