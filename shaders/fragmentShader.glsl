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

vec3 red = vec3(1.,0.,0.), green = vec3(0.,1.,0.), blue = vec3(0.,0.,1.), white = vec3(1.,1.,1.), black = vec3(0.,0.,0.), yellow = vec3(1.,1.,0.), purple = vec3(1.,0.,1.), cyan = vec3(0.,1.,1.), orange = vec3(1.,0.5,0.), pink = vec3(1.,0.5,0.5), brown = vec3(0.5,0.25,0.);
# define OBJECTS_SIZE 10
# define LINES_SIZE OBJECTS_SIZE * 2
# define OPTICAL_COMPONENTS_SIZE OBJECTS_SIZE

# define LINE_RADIUS 0.0001; 
struct Line { vec3 point1, point2, color; }; // a capsule is a line with two spheres on the end
struct Lines { Line at[LINES_SIZE]; int size; };
struct Sphere { vec3 center, color; float radius;  };
struct Box { vec3 center, color; float radius; };
Line exampleLine = Line(vec3(-1.,0.,-5.), vec3(1.,2.,-3.), vec3(1.,1.,1.)); Line exampleLine2 = Line(vec3(1.,2.,-3.), vec3(1.,-2.,-3.), vec3(1.,1.,1.));
Sphere exampleSphere = Sphere(vec3(0.6,0.,-5.), vec3(1.,0.,0.), 1.); Sphere exampleSphere2 = Sphere(vec3(-0.6,0.,-5.), vec3(1.,0.,0.), 01.);

// a convex lens is twos spheres intersecting 
// a concave lens is a box subtracted from two spheres
struct LensProperties { float focalLength, thickness, angle; vec3 coordinate; };
struct ConvexLens { Sphere sphere1, sphere2; LensProperties properties; }; 
struct ConcaveLens { Sphere sphere1, sphere2; Box box; LensProperties properties; };
struct OpticalComponent { ConvexLens convexLens; ConcaveLens concaveLens; bool isConvex; };
struct OpticalComponents { OpticalComponent at[OPTICAL_COMPONENTS_SIZE]; int size; };
ConvexLens nullConvexLens = ConvexLens(Sphere(vec3(0.,0.,0.), vec3(0.,0.,0.), 0.), Sphere(vec3(0.,0.,0.), vec3(0.,0.,0.), 0.), LensProperties(0., 0., 0., vec3(0.,0.,0.)));
ConcaveLens nullConcaveLens = ConcaveLens(Sphere(vec3(0.,0.,0.), vec3(0.,0.,0.), 0.), Sphere(vec3(0.,0.,0.), vec3(0.,0.,0.), 0.), Box(vec3(0.,0.,0.), vec3(0.,0.,0.), 0.), LensProperties(0., 0., 0., vec3(0.,0.,0.)));

OpticalComponents opticalComponents;
uniform Lines lines;

// ====================================================================
// MATHEMATICAL UTILITIES
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

// get SDF with the intent of choosing an SDF to an intersection of two spheres
float smoothmax(float distanceToA, float distanceToB, float smoothness) {
    float h = clamp(0.5 + 0.5 * (distanceToB - distanceToA) / smoothness, 0.0, 1.0);
    return mix(distanceToA, distanceToB, h) + smoothness * h * (1.0 - h);
}

// ====================================================================
// OTHER UTILITIES
// ====================================================================

vec3 O = vec3(0.,0.,0.);

// returns the second if x < y
// otherwise return the default value
float ReturnSecondIfXltEdge(float edge, float x, float second, float defaultVal) {
    // if x < edge, step(edge, x) returns 0
    return mix(second, defaultVal, step(edge, x));
}

vec3 ReturnSecondIfXltEdge(float edge, float x, vec3 second, vec3 defaultVal) {
    // if x < edge, step(edge, x) returns 0
    return mix(second, defaultVal, step(edge, x));
}

#define HEIGHT_OF_PLANE -1. // change this to change the height of the floor plane
float getHeightOfPlane() {
    return HEIGHT_OF_PLANE < 1. ? 1000000. : HEIGHT_OF_PLANE;
}

Line line(vec3 from, vec3 to) {
    return Line(from, to, vec3(1.,1.,1.));
}

Sphere SphereWithRadius(float radius) {
    return Sphere(vec3(0.,0.,0.), vec3(1.,1.,1.), radius);
}

// TODO: calculations
OpticalComponent createConcaveLens(vec3 coordinate, float unadjustedThickness) {
    float thickness = unadjustedThickness - 0.15; // now thickness from convex and concave lens are the same by scale
    float rbox = thickness; 
    float a = (sqrt(3.) / 4.) * rbox;
    float xOffset = rbox + a; 
    float rsphere = sqrt(pow(rbox, 2.) + pow(a, 2.));
    float diff = rbox / 0.1 * 0.03; // from experimentation
    float constant = 0.6; // from experimentation
    xOffset += constant;
    rsphere += constant + diff;

    Sphere sphere3 = SphereWithRadius(rsphere); Sphere sphere4 = SphereWithRadius(rsphere);
    Box box = Box(coordinate, vec3(1.,0.,0.), rbox);
    sphere3.center += coordinate; sphere4.center += coordinate;
    sphere3.center.x += xOffset; sphere4.center.x -= xOffset;
    LensProperties properties2 = LensProperties(1., rbox, 0.5, coordinate);
    ConcaveLens concaveLens = ConcaveLens(sphere3, sphere4, box, properties2);
    return OpticalComponent(nullConvexLens, concaveLens, false);
}

OpticalComponent createConvexLens(vec3 coordinate, float unadjustedThickness) {
    // if thickness <= 0.5, give thickness - 1, else give .4. Done through experimentation. if you increase this, the lens will be more concave but also smaller (as long as within bounds of thickness)
    // float xOffset = ReturnSecondIfXltEdge(0.51, thickness, thickness - .08, 0.4); // DEPRECATED
    float thickness = unadjustedThickness; // we are using the convex len's thickness as the ground truth
    float diff = 0.3 * thickness;
    float xOffset = thickness - diff;
    float radius = thickness; 
    Sphere sphere1 = SphereWithRadius(radius); Sphere sphere2 = SphereWithRadius(radius);
    sphere1.center.x += xOffset; sphere2.center.x -= xOffset;
    sphere1.center += coordinate; sphere2.center += coordinate;
    LensProperties properties = LensProperties(1., 0.5, 0.5, vec3(0.,0.,-5.5));
    ConvexLens convexLens = ConvexLens(sphere1, sphere2, properties);
    OpticalComponent convexLensComponent = OpticalComponent(convexLens, nullConcaveLens, true);
    return convexLensComponent;
}

// ==========================================================
// RAY MARCHING
// ====================================================================

#define MAX_STEPS 100
#define MAX_DIST 100.
#define MIN_DIST 0.01
#define SURF_DIST 0.05

vec4 sphereScene[100];
vec4 box = vec4(0.,0.,-5.,0.5);

struct RayMarchHit { float distance; vec3 colorOfObject; };

RayMarchHit sdfBox(Box B, vec3 P) {
    vec3 C = B.center;
    float r = B.radius;
    vec3 d = abs(P - C) - vec3(r);
    return RayMarchHit(length(max(d, 0.)), B.color);
}

RayMarchHit sdfSphere(vec3 p, Sphere sphere) {
    vec3 C = sphere.center;
    float r = sphere.radius;
    return RayMarchHit(length(p - C) - r, sphere.color);
}

RayMarchHit sdfLine(vec3 p, Line line) {
    vec3 sphere1toSphere2 = line.point2 - line.point1;
    vec3 sphere1toP = p - line.point1;
    float stepsInDirectionOfMidLine = dot(sphere1toP, sphere1toSphere2) / dot(sphere1toSphere2, sphere1toSphere2);
    float clampedStepsInDirectionOfMidLine = clamp(stepsInDirectionOfMidLine, 0., 1.);
    vec3 closestPointOnLine = line.point1 + clampedStepsInDirectionOfMidLine * sphere1toSphere2;
    float distanceToCapsuleSurface = length(p - closestPointOnLine) - LINE_RADIUS;
    return RayMarchHit(distanceToCapsuleSurface, line.color);
}

RayMarchHit sdfConvexLens(vec3 p, ConvexLens lens) {
    float smoothness = 0.05;
    float distToSphere1 = sdfSphere(p, lens.sphere1).distance;
    float distToSphere2 = sdfSphere(p, lens.sphere2).distance;
    float d = smoothmax(distToSphere1, distToSphere2, smoothness);
    return RayMarchHit(d, lens.sphere1.color);
}

RayMarchHit sdfConcaveLens(vec3 p, ConcaveLens lens) { 
    float boxDist = sdfBox(lens.box, p).distance, sphere1Dist = sdfSphere(p, lens.sphere1).distance, sphere2Dist = sdfSphere(p, lens.sphere2).distance;
    float d = boxDist;
    d = max(d, -sphere1Dist);
    d = max(d, -sphere2Dist);
    
    // MARK: CHANGE THIS LATER 
    if (d == boxDist) return RayMarchHit(d, lens.box.color);
    if (d == -sphere1Dist) return RayMarchHit(d, lens.sphere1.color);
    if (d == -sphere2Dist) return RayMarchHit(d, lens.sphere2.color);
    return RayMarchHit(d, lens.sphere1.color);
}

// sdf of all the optical components and lines
RayMarchHit sdfScene(vec3 p) {
    float d = getHeightOfPlane();
    vec3 color = vec3(1.,1.,1.);
    RayMarchHit rayMarchHit;
    for (int i = 0; i < OPTICAL_COMPONENTS_SIZE; i++) {
        if (i >= opticalComponents.size) break;

        OpticalComponent component = opticalComponents.at[i];
        if (component.isConvex) rayMarchHit = sdfConvexLens(p, component.convexLens);
        else rayMarchHit = sdfConcaveLens(p, component.concaveLens);
        color = ReturnSecondIfXltEdge(rayMarchHit.distance, d, rayMarchHit.colorOfObject, color);
        d = min(d, rayMarchHit.distance);
    }
    for (int i = 0; i < LINES_SIZE; i++) {
        if (i >= lines.size) break;

        Line line = lines.at[i];
        rayMarchHit = sdfLine(p, line);
        color = ReturnSecondIfXltEdge(rayMarchHit.distance, d, rayMarchHit.colorOfObject, color);
        d = min(d, rayMarchHit.distance);
    }
    return RayMarchHit(d, color);
}

float sdfSceneDistance(vec3 p) { return sdfScene(p).distance; }

RayMarchHit rayMarch(vec3 rayOrigin, vec3 rayDir) {
    float accDstToScene = 0.; 
    for (int i = 0; i<MAX_STEPS; i++) {
        vec3 pointOnSphereCast = rayOrigin + rayDir * accDstToScene;
        RayMarchHit rayMarchHit = sdfScene(pointOnSphereCast);
        float currDstToScene = rayMarchHit.distance;
        accDstToScene += currDstToScene;
        if (accDstToScene > MAX_DIST || currDstToScene < MIN_DIST) break; 
    }
    return RayMarchHit(accDstToScene, vec3(0.82, 0.09, 0.09));
}

float rayMarchDistance(vec3 rayOrigin, vec3 rayDir) {
    return rayMarch(rayOrigin, rayDir).distance;
}

// ====================================================================
// LIGHTING ON RAY MARCHING
// ====================================================================

// this calculates the normal of the point for lighting purposes. It does so by calculating little gradients
vec3 calculateNormal(in vec3 p) {
    const vec3 small_step = vec3(0.001, 0.0, 0.0);

    // this uses a swizzle
    float gradient_x = sdfSceneDistance(p + small_step.xyy) - sdfSceneDistance(p - small_step.xyy);
    float gradient_y = sdfSceneDistance(p + small_step.yxy) - sdfSceneDistance(p - small_step.yxy);
    float gradient_z = sdfSceneDistance(p + small_step.yyx) - sdfSceneDistance(p - small_step.yyx);

    vec3 normal = vec3(gradient_x, gradient_y, gradient_z);

    return normalize(normal);
}

// getting shadows with ray marching. It is as simple as ray marching from the intersection point, and checking if that sdf is less than the distance to the light
bool isShadowed(vec3 intersectedPoint, vec3 lightPos) {
    // we have to add the intersected point by a small amount in the direction of the normal, otherwise we will get self-intersection
    vec3 adjustedIntersectedPoint = intersectedPoint + calculateNormal(intersectedPoint) * SURF_DIST;
    float sdtTowardsLight = rayMarchDistance(adjustedIntersectedPoint, lightPos - adjustedIntersectedPoint);
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
    vec3 lightPos = vec3(0.,3.,-2.); // vec3(0., 1., 0.);
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

void initializeLines() {
    // lines.at[0] = line(vec3(-3.,0.,-5.),  opticalComponents.at[0].concaveLens.box.center + opticalComponents.at[0].concaveLens.properties.thickness * vec3(1.,1.,1.));
    // lines.at[1] = line(opticalComponents.at[0].concaveLens.box.center + opticalComponents.at[0].concaveLens.properties.thickness * vec3(1.,1.,1.), opticalComponents.at[1].convexLens.properties.coordinate + opticalComponents.at[1].convexLens.properties.thickness * vec3(0.,1.,1.));
    // lines.at[2] = line(opticalComponents.at[1].convexLens.properties.coordinate + opticalComponents.at[1].convexLens.properties.thickness * vec3(0.,1.,1.), vec3(1.,0.,-5.));
    // lines.at[2] = Line(vec3(1.,-2.,-3.), vec3(-1.,0.,-5.), vec3(1.,1.,1.));
    // lines.size = 3;
}

void initializeOpticalComponents() {
    float radius = .6;

    // concave lens
    OpticalComponent concaveLensComponent = createConcaveLens(vec3(-2.,0.,-5.), radius);
    opticalComponents.at[0] = concaveLensComponent;

    // convex lens
    OpticalComponent convexLensComponent = createConvexLens(vec3(0.,0.,-5.), radius);
    opticalComponents.at[1] = convexLensComponent;


    opticalComponents.size = 2;
}

void initialize(inout vec3 color, inout vec3 cameraOrigin, inout vec3 cameraDir) {
    color = vec3(0.0, 0.0, 0.0);
    color = bgColor;
    cameraOrigin = uCamera;
    cameraDir = normalize(vec3(vPos.xy, -uFL));
    cameraDir *= rotateY(-uCameraDirection.x);
    cameraDir *= rotateX(-uCameraDirection.y);

    // initialize the optical components and lines
    // order matters here
    initializeOpticalComponents();
    initializeLines();
}

void main(void) {
    // initialize camera ray and color 
    vec3 color, cameraOrigin, cameraDir; initialize(color, cameraOrigin, cameraDir);

    RayMarchHit rayMarchHit = rayMarch(cameraOrigin, cameraDir);
    float dstToScene = rayMarchHit.distance;
    if (dstToScene < MAX_DIST) {
        vec3 intersectionPoint = cameraOrigin + cameraDir * dstToScene;
        color = getColor(intersectionPoint) * rayMarchHit.colorOfObject;
    }


    gl_FragColor = vec4(color, 1.0);
}