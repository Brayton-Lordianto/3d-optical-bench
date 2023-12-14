const int NLIGHTS = 2;
const int NSPHERES = 1;
precision mediump float;

uniform float uTime, uFL;
varying vec3 vPos;

uniform vec3 uCamera;
uniform vec3 uCameraDirection;
uniform vec3 uColor;
varying vec3 vNor;
varying float fApplyTransform;


void main(void) {
    vec3 color = vec3(0.0, 0.0, 0.0);
    gl_FragColor = vec4(color, 1.0);
}