#version 140

// visualization shader

varying vec3 vColor;
varying float vLabel;
varying float vLabelConfidence;

uniform float labelConfidenceThreshold;

void main()
{
    if (vLabel > 0.0 && vLabelConfidence >= labelConfidenceThreshold)
    {
        gl_FragColor = vec4(vColor, 1.0);
    }
    else
    {
        discard; // Skip rendering this fragment
    }
}
