attribute vec3 aPos, aNor;
varying vec3 vPos, vNor;
varying float fApplyTransform;
attribute float applyTransform; // the below matrices are only applied if this is true
uniform mat4 uMatrix, uInvMatrix;
void main() {
    fApplyTransform = applyTransform;
    if(true) {
        vec4 pos = uMatrix * vec4(aPos, 1.0);
        vec4 nor = vec4(aNor, 0.0) * uInvMatrix;
        vPos = pos.xyz;
        vNor = nor.xyz;
        gl_Position = pos * vec4(1.,1.,-.1,1.);
        return;
    }

    gl_Position = vec4(aPos, 1.0);
    vPos = aPos;
}
