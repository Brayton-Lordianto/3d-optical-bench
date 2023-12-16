const int NLIGHTS = 2;
const int NSPHERES = 100;
precision mediump float;

uniform float uTime, uFL;
varying vec3 vPos;

uniform vec3 uCamera;
uniform vec3 uCameraDirection;
uniform vec3 uColor;
varying vec3 vNor;
varying float fApplyTransform;

vec3 bgColor = vec3(0.23, 0.6, 0.12);

// ====================================================================
// OBJECTS
// ====================================================================

struct Sphere { vec3 center, color; float radius;  };
struct Box { vec3 center, color; float radius; };
struct Line { vec3 centerOfSphere1, centerOfSphere2, color; float radius; }; // a capsule is a line with two spheres on the end

// a convex lens is twos spheres intersecting 
// a concave lens is a box subtracted from two spheres
struct LensProperties { float focalLength, thickness, angle; vec3 coordinate; };
struct ConvexLens { Sphere sphere1, sphere2; LensProperties properties; }; 
struct ConcaveLens { Sphere sphere1, sphere2; Box box; LensProperties properties; };
struct OpticalComponent { ConvexLens convexLens; ConcaveLens concaveLens; bool isConvex; };
struct OpticalComponents { OpticalComponent components[100]; int size; };

// ====================================================================
// ROTATION MATRICES
// ====================================================================
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
// ==========================================================
// RAY MARCHING
// ====================================================================

#define MAX_STEPS 100
#define MAX_DIST 100.
#define MIN_DIST 0.01
#define SURF_DIST 0.05
#define HEIGHT_OF_PLANE -1. // change this to change the height of the floor plane

vec4 sphereScene[100];
vec4 box = vec4(0.,0.,-5.,0.5);

float sdfBox(vec4 B, vec3 P) {
    vec3 C = B.xyz;
    float r = B.w;
    vec3 d = abs(P - C) - vec3(r);
    return length(max(d, 0.)); 
}

float sdfBox(Box B, vec3 P) {
    return sdfBox(vec4(B.center, B.radius), P);
}

void initSpheres() {
    for (int i = 0; i < NSPHERES; i++) sphereScene[i] = vec4(0.,0.,0.,0.);

    float r = 1.; // = 0.001; // = 1.0;
    sphereScene[0] = vec4(0.5,0.,-5.,r);
    sphereScene[1] = vec4(-0.5,0.,-5.,r);
}

// the distance function for a sphere
float sdfSphere(vec4 S, vec3 P) {
    vec3 C = S.xyz;
    float r = S.w;
    return length(P - C) - r;
}

float sdfSphere(Sphere S, vec3 P) {
    return sdfSphere(vec4(S.center, S.radius), P);
}

float getHeightOfPlane() {
    return HEIGHT_OF_PLANE < 1. ? 1000000. : HEIGHT_OF_PLANE;
}

// get shortest SDF from a point to any sphere
float sdfScene(vec3 p) {
    // the sdf to a plane is simply the height of the plane
    float heightOfPlane = HEIGHT_OF_PLANE; 
    float d = heightOfPlane < 1. ? 1000000. : heightOfPlane; 
    // for (int i = 0; i < NSPHERES; i++) {
    //     if (sphereScene[i].w == 0.) break; 
    //     d = min(d, sdfSphere(sphereScene[i], p));
    // }
    d = min(d, sdfBox(box, p));
    return d;
}

// this calculates the normal of the point for lighting purposes. It does so by calculating little gradients
vec3 calculateNormal(in vec3 p) {
    const vec3 small_step = vec3(0.001, 0.0, 0.0);

    // this uses a swizzle
    float gradient_x = sdfScene(p + small_step.xyy) - sdfScene(p - small_step.xyy);
    float gradient_y = sdfScene(p + small_step.yxy) - sdfScene(p - small_step.yxy);
    float gradient_z = sdfScene(p + small_step.yyx) - sdfScene(p - small_step.yyx);

    vec3 normal = vec3(gradient_x, gradient_y, gradient_z);

    return normalize(normal);
}

// ray marches the scene and returns the distance to the scene that the ray directly hits
float rayMarch(vec3 rayOrigin, vec3 rayDir) {
    float accDstToScene = 0.; 
    for (int i = 0; i<MAX_STEPS; i++) {
        vec3 pointOnSphereCast = rayOrigin + rayDir * accDstToScene;
        float currDstToScene = sdfScene(pointOnSphereCast);
        accDstToScene += currDstToScene;
        if (accDstToScene > MAX_DIST || currDstToScene < MIN_DIST) break; 
    }
    return accDstToScene;
} 

// ====================================================================
// BOOLEAN OPERATIONS ON RAY MARCHING
// ====================================================================

// get SDF with the intent of choosing an SDF to a subtraction of two spheres 
float sdfSubtraction(vec3 p) {
    float heightOfPlane = getHeightOfPlane();
    float d = max(-sdfSphere(sphereScene[0], p), sdfSphere(sphereScene[1], p));
    d = min(d, heightOfPlane);
    return d;
}

float testSubtractionRayMarch(vec3 rayOrigin, vec3 rayDir) {
    float accDstToScene = 0.; 
    for (int i = 0; i<MAX_STEPS; i++) {
        vec3 pointOnSphereCast = rayOrigin + rayDir * accDstToScene;
        float currDstToScene = sdfSubtraction(pointOnSphereCast);
        accDstToScene += currDstToScene;
        if (accDstToScene > MAX_DIST || currDstToScene < MIN_DIST) break; 
    }
    return accDstToScene;
}

// get SDF with the intent of choosing an SDF to a union of two spheres
float smoothmin(float distanceToA, float distanceToB, float smoothness) {
    float h = clamp(0.5 + 0.5 * (distanceToB - distanceToA) / smoothness, 0.0, 1.0);
    return mix(distanceToB, distanceToA, h) - smoothness * h * (1.0 - h);
}

float sdfUnion(vec3 p, float smoothness) {
    float heightOfPlane = HEIGHT_OF_PLANE;
    float d = heightOfPlane < 1. ? 1000000. : heightOfPlane;
    d = smoothmin(d, sdfSphere(sphereScene[0], p), smoothness);
    d = smoothmin(d, sdfSphere(sphereScene[1], p), smoothness);
    return d;
}

float testUnionRayMarch(vec3 rayOrigin, vec3 rayDir, float smoothness) {
    float accDstToScene = 0.; 
    for (int i = 0; i<MAX_STEPS; i++) {
        vec3 pointOnSphereCast = rayOrigin + rayDir * accDstToScene;
        float currDstToScene = sdfUnion(pointOnSphereCast, smoothness);
        accDstToScene += currDstToScene;
        if (accDstToScene > MAX_DIST || currDstToScene < MIN_DIST) break; 
    }
    return accDstToScene;
}

// get SDF with the intent of choosing an SDF to an intersection of two spheres
float smoothmax(float distanceToA, float distanceToB, float smoothness) {
    float h = clamp(0.5 + 0.5 * (distanceToB - distanceToA) / smoothness, 0.0, 1.0);
    return mix(distanceToA, distanceToB, h) + smoothness * h * (1.0 - h);
}

float sdfIntersection(vec3 p) {
    float heightOfPlane = HEIGHT_OF_PLANE < 1. ? 1000000. : HEIGHT_OF_PLANE;
    float d = smoothmax(sdfSphere(sphereScene[0], p), sdfSphere(sphereScene[1], p), 0.05);
    d = min(d, heightOfPlane);
    return d;
}

float testIntersectionRayMarch(vec3 rayOrigin, vec3 rayDir) {
    float accDstToScene = 0.; 
    for (int i = 0; i<MAX_STEPS; i++) {
        vec3 pointOnSphereCast = rayOrigin + rayDir * accDstToScene;
        float currDstToScene = sdfIntersection(pointOnSphereCast);
        accDstToScene += currDstToScene;
        if (accDstToScene > MAX_DIST || currDstToScene < MIN_DIST) break; 
    }
    return accDstToScene;
}

struct RayMarchHit { float distance; vec3 colorOfObject; };

RayMarchHit sdfConcaveTest(vec3 p) {
    // make 2 spheres and a box
    float sphereX = 0.75;
    Sphere sphere1 = Sphere(vec3(-sphereX,0.,-1.), vec3(1.,0.,0.), 0.75);
    Sphere sphere2 = Sphere(vec3(sphereX,0.,-1.), vec3(0.,0.,1.), 0.75);
    Box box = Box(vec3(0.,0.,-1.), vec3(1.,1.,1.), .25);

    float heightOfPlane = getHeightOfPlane();
    float d = max(sdfBox(box, p), -sdfSphere(sphere1, p));
    d = max(d, -sdfSphere(sphere2, p));
    // float d = max(-sdfBox(box, p), sdfSphere(sphere1, p));
    // float d; 
    float d1 = sdfBox(box, p);
    float d2 = sdfSphere(sphere1, p);
    float d3 = sdfSphere(sphere2, p);
    // d = min(min(d1, d2), d3);
    if (d == d1) return RayMarchHit(d, box.color);
    if (d == d2) return RayMarchHit(d, sphere1.color);
    // if (d == d3) return RayMarchHit(d, sphere2.color);
    return RayMarchHit(d, sphere1.color);
    // return min(d, heightOfPlane);

}

RayMarchHit testMakeConcaveRayMarch(vec3 rayOrigin, vec3 rayDir) {
    // march to subtraction of box with sphere 
    float accDstToScene = 0.;
    vec3 colorOfObject = vec3(1.,0.,0.);
    for (int i = 0; i<MAX_STEPS; i++) {
        vec3 pointOnSphereCast = rayOrigin + rayDir * accDstToScene;
        RayMarchHit rayMarchHit = sdfConcaveTest(pointOnSphereCast);
        float currDstToScene = rayMarchHit.distance;
        accDstToScene += currDstToScene;
        colorOfObject = rayMarchHit.colorOfObject;
        if (accDstToScene > MAX_DIST || currDstToScene < MIN_DIST) break; 
    }
    return RayMarchHit(accDstToScene, colorOfObject);
}

Line exampleLine = Line(vec3(-1.,0.,-5.), vec3(1.,2.,-3.), vec3(1.,1.,1.), 0.0001);
Line exampleLine2 = Line(vec3(1.,2.,-3.), vec3(1.,-2.,-3.), vec3(1.,1.,1.), 0.0001);

RayMarchHit sdfLine(vec3 p, Line line) {
    vec3 sphere1toSphere2 = line.centerOfSphere2 - line.centerOfSphere1;
    vec3 sphere1toP = p - line.centerOfSphere1;
    float stepsInDirectionOfMidLine = dot(sphere1toP, sphere1toSphere2) / dot(sphere1toSphere2, sphere1toSphere2);
    float clampedStepsInDirectionOfMidLine = clamp(stepsInDirectionOfMidLine, 0., 1.);
    vec3 closestPointOnLine = line.centerOfSphere1 + clampedStepsInDirectionOfMidLine * sphere1toSphere2;
    float distanceToCapsuleSurface = length(p - closestPointOnLine) - line.radius;
    return RayMarchHit(distanceToCapsuleSurface, line.color);
}

RayMarchHit sdfTwoLines(vec3 p) {
    RayMarchHit rayMarchHit1 = sdfLine(p, exampleLine);
    RayMarchHit rayMarchHit2 = sdfLine(p, exampleLine2);
    return RayMarchHit(min(rayMarchHit1.distance, rayMarchHit2.distance), rayMarchHit1.colorOfObject);
}

RayMarchHit testMakeCapsuleRayMarch(vec3 rayOrigin, vec3 rayDir) {
    // march to subtraction of box with sphere 
    float accDstToScene = 0.;
    vec3 colorOfObject = vec3(1.,0.,0.);
    for (int i = 0; i<MAX_STEPS; i++) {
        vec3 pointOnSphereCast = rayOrigin + rayDir * accDstToScene;
        RayMarchHit rayMarchHit = sdfTwoLines(pointOnSphereCast);
        float currDstToScene = rayMarchHit.distance;
        accDstToScene += currDstToScene;
        colorOfObject = rayMarchHit.colorOfObject;
        if (accDstToScene > MAX_DIST || currDstToScene < MIN_DIST) break; 
    }
    return RayMarchHit(accDstToScene, colorOfObject);
}

// ====================================================================
// LIGHTING ON RAY MARCHING
// ====================================================================

// getting shadows with ray marching. It is as simple as ray marching from the intersection point, and checking if that sdf is less than the distance to the light
bool isShadowed(vec3 intersectedPoint, vec3 lightPos) {
    // we have to add the intersected point by a small amount in the direction of the normal, otherwise we will get self-intersection
    vec3 adjustedIntersectedPoint = intersectedPoint + calculateNormal(intersectedPoint) * SURF_DIST;
    float sdtTowardsLight = rayMarch(adjustedIntersectedPoint, lightPos - adjustedIntersectedPoint);
    float dstFromLight = length(lightPos - adjustedIntersectedPoint);
    return sdtTowardsLight < dstFromLight;
}

// if it is in the shadow, apply the shadow effect 
vec3 applyShadow(vec3 diffuse) {
    return diffuse * 1.;
}

// this gets the lighting for a single point which has been hit by the ray 
float getLight(vec3 point, vec3 lightPos, vec3 lightColor) {
    vec3 lightDir = normalize(lightPos - point);
    vec3 normal = calculateNormal(point);
    float diffuse = max(dot(normal, lightDir), 0.0);
    return diffuse;
}

vec3 getColor(vec3 point) {
    vec3 lightPos = vec3(0.,6.,-5.); // vec3(0., 1., 0.);
    vec3 lightColor = vec3(1., 1., 1.);
    float diffuse = getLight(point, lightPos, lightColor);
    vec3 diffuseComponent = vec3(diffuse); 
    if (isShadowed(point, lightPos)) diffuseComponent = applyShadow(diffuseComponent);
    vec3 ambientComponent = vec3(.5);
    return diffuseComponent + ambientComponent;
}

// ====================================================================
// MAIN
// ====================================================================

void initialize(inout vec3 color, inout vec3 cameraOrigin, inout vec3 cameraDir) {
    color = vec3(0.0, 0.0, 0.0);
    color = bgColor;
    cameraOrigin = uCamera;
    cameraDir = normalize(vec3(vPos.xy, -uFL));
    cameraDir *= rotateY(-uCameraDirection.x);
    cameraDir *= rotateX(-uCameraDirection.y);
    initSpheres();
}

void main(void) {
    // initialize camera ray and color 
    vec3 color, cameraOrigin, cameraDir; initialize(color, cameraOrigin, cameraDir);

    // ray march for spheres and render them 
    vec4 sphere = vec4(1.,0.,0.,1.);
    // float dstToScene = rayMarch(cameraOrigin, cameraDir);
    // float dstToScene = testSubtractionRayMarch(cameraOrigin, cameraDir);
    // float dstToScene = testUnionRayMarch(cameraOrigin, cameraDir, 0.2);
    // float dstToScene = testIntersectionRayMarch(cameraOrigin, cameraDir);
    // float dstToScene = testMakeConcaveRayMarch(cameraOrigin, cameraDir);
    // RayMarchHit rayMarchHit = testMakeConcaveRayMarch(cameraOrigin, cameraDir);
    RayMarchHit rayMarchHit = testMakeCapsuleRayMarch(cameraOrigin, cameraDir);
    float dstToScene = rayMarchHit.distance;
    if (dstToScene < MAX_DIST) {
        vec3 intersectionPoint = cameraOrigin + cameraDir * dstToScene;
        color = getColor(intersectionPoint);
        color = getColor(intersectionPoint) * rayMarchHit.colorOfObject;
    }


    gl_FragColor = vec4(color, 1.0);
}