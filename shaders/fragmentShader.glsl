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

vec3 bgColor = vec3(0.23, 0.6, 0.12);


// Rotation matrix around the X axis.
mat3 rotateX(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(vec3(1, 0, 0), vec3(0, c, -s), vec3(0, s, c));
}

// Rotation matrix around the Y axis.
mat3 rotateY(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(vec3(c, 0, s), vec3(0, 1, 0), vec3(-s, 0, c));
}


float rayCylinder(vec3 rayOrigin, vec3 rayDir) {
    vec3 center = vec3(0.,0.,-1.);
    float radius = 0.00001;
    vec3 adjustedRayOrigin = rayOrigin - center;
    float a = pow(rayDir.x, 2.0) + pow(rayDir.y, 2.0);
    float b = 2.0 * (adjustedRayOrigin.x * rayDir.x + adjustedRayOrigin.y * rayDir.y);
    float c = pow(adjustedRayOrigin.x, 2.0) + pow(adjustedRayOrigin.y, 2.0) - radius;

    float discriminant = pow(b, 2.0) - 4.0 * a * c;
    if (discriminant < 0.0) return -1.0;

    float t1 = (-b - sqrt(discriminant)) / (2.0 * a);
    float t2 = (-b + sqrt(discriminant)) / (2.0 * a);

    float z1 = adjustedRayOrigin.z + t1 * rayDir.z;
    float z2 = adjustedRayOrigin.z + t2 * rayDir.z;
    return z1; 

    // if (discriminant < 0.0) {
    //     return -1.0;
    // }

}

float raySphere(vec3 rayOrigin, vec3 rayDir) {
    vec3 center = vec3(0.,0.,-1.);
    float a = dot(rayDir, rayDir);
    float b = 2.0 * dot(rayOrigin - center, rayDir);
    float c = dot(rayOrigin - center, rayOrigin - center) - 1.0;

    float discriminant = pow(b, 2.0) - 4.0 * a * c;
    float t = (-b - sqrt(discriminant)) / (2.0 * a);
    return t;
}

void main(void) {
    // initialize camera ray and color 
    vec3 color = vec3(0.0, 0.0, 0.0);
    color = bgColor;
    vec3 cameraOrigin = uCamera;
    vec3 cameraDir = normalize(vec3(vPos.xy, -uFL));
    cameraDir *= rotateY(-uCameraDirection.x);
    cameraDir *= rotateX(-uCameraDirection.y);

    // ray trace to a single cylinder
    // float t = raySphere(cameraOrigin, cameraDir);
    float t = rayCylinder(cameraOrigin, cameraDir);
    if (t > 0.0 && t < 3.) {
        color = vec3(1.0, 0.0, 0.0);
    } 



    gl_FragColor = vec4(color, 1.0);
}