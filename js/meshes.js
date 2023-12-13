
// TRIANGLE DATA (IN THIS CASE, ONE SQUARE)
let sphere = (nu, nv) => createMesh(nu, nv, (u,v) => {
    let theta = 2 * Math.PI * u;
    let phi = Math.PI * (v - .5);
    let x = Math.cos(phi) * Math.cos(theta),
        y = Math.cos(phi) * Math.sin(theta),
        z = Math.sin(phi);
    return [ x,y,z, x,y,z, 1 ];
 });

let createMesh = (nu, nv, p) => {
    let mesh = [];
    for (let j = nv ; j > 0 ; j--) {
        for (let i = 0 ; i <= nu ; i++)
            mesh.push(p(i/nu,j/nv), p(i/nu,j/nv-1/nv));
        mesh.push(p(1,j/nv-1/nv), p(0,j/nv-1/nv));
    }
    return mesh.flat();
}

// vNor and vApplyTransform is not used in the screen
let screen = [
    -1, 1, 0,     0,0,0,0,
     1, 1, 0,     0,0,0,0,
    -1,-1, 0,     0,0,0,0,
     1,-1, 0,     0,0,0,0,
]                  

let meshData = [
{ type: 1, color: [1.,.1,.1], mesh: new Float32Array(screen) }, 
{ type: 1, color: [1.,.1,.1], mesh: new Float32Array(sphere(20, 10)) },
];

// SET NUMBER OF LIGHTS AND NUMBER OF SPHERES IN THE SCENE

// VERTEX AND FRAGMENT SHADERS

let vertexSize = 7;