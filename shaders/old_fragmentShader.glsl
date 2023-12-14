const int NLIGHTS = 2;
const int NSPHERES = 80;
precision mediump float;

uniform float uTime, uFL;
uniform vec3 uCursor;
uniform vec3 uLC[NLIGHTS];
uniform vec3 uLD[NLIGHTS];
uniform vec4 uSphere[NSPHERES];
uniform vec3 uAmbient[NSPHERES];
uniform vec3 uDiffuse[NSPHERES];
uniform vec4 uSpecular[NSPHERES];
varying vec3 vPos;

uniform vec3 uCamera;
uniform vec3 uCameraDirection;
uniform vec3 uColor;
varying vec3 vNor;
varying float fApplyTransform;

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

float raySphere(vec3 V, vec3 W, vec4 S) {
    V -= S.xyz;
    float b = dot(V, W);
    float c = dot(V, V) - S.w * S.w;
    float d = b * b - c;
    return d > 0. ? -b - sqrt(d) : -1.;
}

float raySphereExit(vec3 V, vec3 W, vec4 S) {
    V -= S.xyz;
    float b = dot(V, W);
    float c = dot(V, V) - S.w * S.w;
    float d = b * b - c;
    return d > 0. ? -b + sqrt(d) : -1.;
}

vec3 shadeSurface(vec3 P, vec3 N, vec3 ambient, vec3 diffuse, vec4 specular, vec3 W) {
    // AMBIENT
    vec3 color = ambient;

    for(int l = 0; l < NLIGHTS; l++) {

        float t = -1.;

        // SHADOWS
        float epsilon = 0.001;
        // shoot a ray to each light, if it hits something, then the light is blocked
        for(int n = 0; n < NSPHERES; n++)
            // why do we trace from some point to uLD[l]? 
            // what is uLD[l]? It is the direction of the light
            // so we are tracing from the point to the light, and seeing if it hits sphere n
            // recall ray sphere has V and W, V is the origin, W is the direction
            // here, V is the point, and W is the direction of the light
            t = max(t, raySphere(P + epsilon, uLD[l], uSphere[n]));

        if(t < 0.) {

        // DIFFUSE AND SPECULAR

        // reflection vector 
            vec3 R = 2. * dot(uLD[l], N) * N - uLD[l];

        // diffuse vector -- which is really just how much the light is aligned with the normal
            color += diffuse * max(0., dot(N, uLD[l])) * uLC[l];

        // specular vector -- which is really just how much the reflection is aligned with the view
            color += specular.rgb * pow(max(0., dot(R, -W)), specular.a) * uLC[l];
        }
    }

    return color;
}

vec3 refractRay(vec3 W, vec3 N, float n) {
    vec3 Wv = N * dot(W, N);
    vec3 Wu = (W - Wv) / n;
    return Wu + normalize(Wv) * sqrt(1. - dot(Wu, Wu));
}

vec3 bgColor = vec3(0., 0., .05);

// returns the coordinate of intersection if the camera ray of the pixel defined by V and W hits the line defined by lineDirection
// last parameter will be 1 if it hits the line, 0 if it doesn't
vec4 rayToLine(vec3 V, vec3 W, vec3 lineDirection) {
    vec3 lineOrigin = vec3(0., 0., -3.);
    float pixelOffset = 0.0001;

    // test if it first hits the line
    vec3 crossOfDirections = cross(W, lineDirection);
    float determiningFactor = dot(crossOfDirections, (V - lineOrigin));
    float hitTheRay = (determiningFactor > 0. && determiningFactor < pixelOffset) ? 1. : 0.;

    // if it hits the line, then we need to find the point of intersection
    if(hitTheRay == 1.) {
        float t = dot(crossOfDirections, (lineOrigin - V)) / dot(crossOfDirections, W);
        vec3 P = V + t * W;
        return vec4(P, hitTheRay);
    }

    return vec4(0., 0., 0., hitTheRay);
}

float distanceFromBothLines(vec3 V, vec3 W, vec3 lineOrigin, vec3 lineDirection) {
    vec3 n = cross(W, lineDirection);
    n /= normalize(n);
    float d = dot(n, V - lineOrigin);
    return d;
}

vec3 normalizeDirection(vec3 direction) {
    vec3 normalizedDirection = vec3(0., 0., 0.);
    normalizedDirection.x = (direction.x - 0.5) * 2.;
    normalizedDirection.y = (direction.y - 0.5) * 2.;
    normalizedDirection.z = direction.z;
    return normalizedDirection;
}

vec3 isectLinePlane(vec3 p0, vec3 p1, vec3 planePoint, vec3 planeNormal) {
    float epsilon = 0.000001;
    vec3 u = p1 - p0;
    float dotProduct = dot(planeNormal, normalize(u));

    if (abs(dotProduct) > epsilon) {
        // The factor of the point between p0 -> p1 (0 - 1)
        // if 'fac' is between (0 - 1) the point intersects with the segment.
        // Otherwise:
        //  < 0.0: behind p0.
        //  > 1.0: in front of p1.
        vec3 w = p0 - planePoint;
        float fac = -dot(planeNormal, w) / dotProduct;
        u *= fac;
        return p0 + u;
    }

    // The segment is parallel to the plane.
    return vec3(0.0); // Return a default value indicating no intersection
}

// float distanceOfLinesInPlane(vec3 linePoint1fromRay, vec3 lineDir1fromRay, vec3 linePoint2, vec3 lineDir2) {
    
//     return d;
// }

float distanceToLine2_hardcoded(vec3 rayPoint, vec3 rayDir, vec3 linePoint, vec3 lineDir) {
    // 1. Get the plane that contains the line 
    vec3 planePoint = vec3(-10.,-1,12);
    vec3 planeNormal = vec3(0.,0.,-1.);

    // 2. Get the intersection of the ray and the plane
    vec3 intersectionPoint = isectLinePlane(rayPoint, rayPoint + rayDir, planePoint, planeNormal);

    // 3. if intersecting, get the shortest distance from (P to intesection) to Line
    if (intersectionPoint.z == 12.) {
        vec3 lineToIntersection = intersectionPoint - linePoint;
        // vec3 projectionVector = dot(lineToIntersection, lineDir);
    }
    return 0.;
}

// void main() {} 

void main(void) {
    vec3 color = vec3(0., 0., 0.);
    if (fApplyTransform == 1.) {
        float c = .05 + max(0., dot(normalize(vNor), vec3(.57)));
        vec3 color = c * uColor;
        gl_FragColor = vec4(sqrt(color), 1.);
        return;
    }

    // SET BACKGROUND COLOR

    //vec3 
    color = bgColor;

    // FORM THE RAY FOR THIS PIXEL

    // vec3 V = vec3(0.,0.,uFL);
    // normalize the camera directions xy to be from -0.5 to 0.5
    vec3 normalizedCameraDirection = normalizeDirection(uCameraDirection);
    vec3 V = uCamera;
    vec3 W = normalize(vec3(vPos.xy, -uFL));
    W *= rotateY(-uCameraDirection.x);
    W *= rotateX(-uCameraDirection.y);

    // try to render a ray 
    vec3 lineOrigin = vec3(0., -1., .12);
    vec3 lineDirection = normalize(vec3(1., 0., 0.));
    float distance = distanceFromBothLines(V, W, lineOrigin, lineDirection);
    float thickness = 0.01;
    // if (distance < thickness && distance > -thickness) {
    if(distance < 3.85 && distance > 3.85 - thickness) {
        color = vec3(1., 0., 0.);
    }

    if (distanceToLine2_hardcoded(V, W, lineOrigin, lineDirection) == 1.) {
        color = vec3(1., 0., 0.);
        gl_FragColor = vec4(sqrt(color), 1.);
        return; 
    } else {
        color = vec3(0., 0., 1.);
        gl_FragColor = vec4(sqrt(color), 1.);
        return;
    }

    // vec4 rayToLineResult = rayToLine(V, W, rayDirection);
    // float hitTheRay = rayToLineResult.w;
    // float zVal = rayToLineResult.z;
    // if (hitTheRay == 1.) {
    //     color = vec3(1.,0.,0.);
    // }

    // RAY TRACE TO EACH SPHERE, CHOOSING THE NEAREST ONE

    float tMin = 1000.;
    for(int n = 0; n < NSPHERES; n++) {
        float t = raySphere(V, W, uSphere[n]);
        if(t > 0. && t < tMin) {
            tMin = t;
            vec3 P = V + t * W;
            vec3 N = normalize(P - uSphere[n].xyz);
        // if (hitTheRay == 1. && P.z > zVal) continue;
            color = shadeSurface(P, N, uAmbient[n], uDiffuse[n], uSpecular[n], W);

        //   // REFRACTION

        // float ior = 2.5;
        // vec3  Win  = refractRay(W, N, ior);
        // float tout = raySphereExit(P, Win, uSphere[n]);
        // vec3  Pout = P + tout * Win;
        // vec3  Nout = normalize(Pout - uSphere[n].xyz);
        // vec3  Wout = refractRay(Win, Nout, 1./ior);

        // //   vec3 Cg = bgColor; // GLASS COLOR
        // vec3 Cg = color; // GLASS COLOR 
        // float tgMin = 1000.;
        // for (int j = 0 ; j < NSPHERES ; j++) {
        //     float t = raySphere(Pout, Wout, uSphere[j]);
        //     if (t > 0. && t < tgMin) {
        //         tgMin = t;
        //         vec3 P = Pout + t * Wout;
        //         vec3 N = normalize(P - uSphere[j].xyz);
        //         Cg = shadeSurface(P, N, uAmbient[j],
        //                                 uDiffuse[j],
        //                                 uSpecular[j], Wout);
        //     }
        // }
        // color = mix(color, Cg, .9);

        // //   // REFLECTION
        // vec3 Cm = bgColor; // MIRROR COLOR
        // vec3 Wm = 2. * dot(-W, N) * N + W; // direction of the ray going into the mirror
        // float tjMin = 1000.;
        // for (int j = 0 ; j < NSPHERES ; j++) {
        //     float tj = raySphere(P, Wm, uSphere[j]);
        //     if (tj > 0. && tj < tjMin) {
        //         tjMin = tj;
        //         vec3 Pj = P + tj * Wm;
        //         vec3 Nj = normalize(Pj - uSphere[j].xyz);
        //         Cm = shadeSurface(Pj, Nj, uAmbient[j],
        //                                 uDiffuse[j],
        //                                 uSpecular[j], Wm);
        //     }
        // }
        // //color = mix(color, Cm , .5);//* uSpecular[n].rgb, .5);

        // why do we have to muliptly by uSpecular[n]
        // color = mix(color, Cm * uSpecular[n].rgb, .5);
        }
    }

    // if (vPos.x < 0.) color = vec3(1.,0.,0.);

    gl_FragColor = vec4(sqrt(color), 1.);
}