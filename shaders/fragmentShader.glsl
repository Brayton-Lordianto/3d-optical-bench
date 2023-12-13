const int NLIGHTS = 2;
const int NSPHERES = 1;
precision mediump float;

uniform float uTime, uFL;
uniform vec3  uCursor;
uniform vec3  uLC[NLIGHTS];
uniform vec3  uLD[NLIGHTS];
uniform vec4  uSphere[NSPHERES];
uniform vec3  uAmbient[NSPHERES];
uniform vec3  uDiffuse[NSPHERES];
uniform vec4  uSpecular[NSPHERES];

varying vec3  vPos;

void main(void) {
    // USER CAMERA RAY
    vec3 cameraOrigin = vPos; 
    vec3 cameraDirection = normalize(vec3(vPos.xy, -uFL));

}