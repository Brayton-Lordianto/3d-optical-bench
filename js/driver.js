function driverScript() {
    gl = start_gl(canvas1, meshData, vertexSize, vertexShader, fragmentShader);

    // INITIALIZE POSITION, VELOCITY AND PHONG PARAMETERS OF EACH SPHERE

    let V = [],
        S = [],
        ambient = [],
        diffuse = [],
        specular = [];
    let sphereRadius = 0.12;
    for (let n = 0; n < 4 * NSPHERES; n++) {
        if (n % 4 < 3) {
            S.push(2 * Math.random() - 1);
            V.push(0);
            let c = Math.random();
            ambient.push(.2 * c);
            diffuse.push(.8 * c);
            specular.push(1);
        } else {
            S.push(sphereRadius);
            specular.push(20);
        }
    }

    // FIND LOCATIONS IN GPU PROGRAM OF UNIFORM VARIABLES

    let uFL = gl.getUniformLocation(gl.program, "uFL");
    let uTime = gl.getUniformLocation(gl.program, "uTime");
    let uCursor = gl.getUniformLocation(gl.program, "uCursor");
    let uLC = gl.getUniformLocation(gl.program, "uLC");
    let uLD = gl.getUniformLocation(gl.program, "uLD");
    let uSphere = gl.getUniformLocation(gl.program, "uSphere");
    let uAmbient = gl.getUniformLocation(gl.program, "uAmbient");
    let uDiffuse = gl.getUniformLocation(gl.program, "uDiffuse");
    let uSpecular = gl.getUniformLocation(gl.program, "uSpecular");
    
    let uCamera = gl.getUniformLocation(gl.program, "uCamera");
    let uCameraDirection = gl.getUniformLocation(gl.program, "uCameraDirection");
    let uColor = gl.getUniformLocation(gl.program, "uColor");
    let uMatrix    = gl.getUniformLocation(gl.program, "uMatrix");
    let uInvMatrix = gl.getUniformLocation(gl.program, "uInvMatrix");

    // ANIMATE AND RENDER EACH ANIMATION FRAME


    let startTime = Date.now() / 1000;
    setInterval(() => {
        gl.uniform3fv(uCamera, camera);
        gl.uniform3fv(uCameraDirection, cameraDirection);
    });
    setInterval(() => {

        // HANDLE SPHERES BEHAVIOR FOR THIS ANIMATION FRAME

        for (let n = 0, i = 0; n < S.length; n++)
            if (n % 4 < 3) {
                // V[i] = .99 * V[i] + .02 * (Math.random() - .5);
                // S[n] += .1 * V[i];
                // if (Math.abs(S[n]) > 1)
                //     V[i] = -.2 * Math.sign(S[n]);
                // i++;
                // console.log(S)
            }

        // MAKE SPHERES BOUNCE OFF ONE ANOTHER

        for (let i = 0; i < S.length - 4; i += 4)
            for (let j = i + 4; j < S.length; j += 4) {
                let A = S.slice(i, i + 3),
                    ra = S[i + 3];
                let B = S.slice(j, j + 3),
                    rb = S[j + 3];
                let D = [B[0] - A[0], B[1] - A[1], B[2] - A[2]];
                let d = Math.sqrt(D[0] * D[0] + D[1] * D[1] + D[2] * D[2]);
                if (d < ra + rb) {
                    let iv = i * 3 / 4;
                    let jv = j * 3 / 4;
                    for (let k = 0; k < 3; k++) {
                        V[iv + k] -= .1 * D[k];
                        V[jv + k] += .1 * D[k];
                    }
                }
            }

        // SET ALL UNIFORM VARIABLES

        gl.uniform1f(uTime, Date.now() / 1000 - startTime);
        gl.uniform3fv(uCursor, cursor);
        gl.uniform1f(uFL, 3);

        // this is the light sources intensity and their directions
        // LC is the color intensity of the light source
        let r3 = Math.sqrt(1 / 3);
        gl.uniform3fv(uLC, [1, 1, 1, .3, .2, .1]);
        gl.uniform3fv(uLD, [r3, r3, r3, -r3, -r3, -r3])
        //   gl.uniform3fv(uLC, [1,1,1,      .3,.2,.1]);
        //   gl.uniform3fv(uLD, [r3,r3,r3, -r3,-r3,-r3]);


        gl.uniform4fv(uSphere, S);
        gl.uniform3fv(uAmbient, ambient);
        gl.uniform3fv(uDiffuse, diffuse);
        gl.uniform4fv(uSpecular, specular);

        // RENDER THE FRAME
        let m = mIdentity();
        m = mScale(.16, .16, .16, m);

        


        for (let n = 0; n < meshData.length; n++) {
            gl.uniform3fv      (uColor    , meshData[n].color);
            gl.uniformMatrix4fv(uMatrix   , false, m);
            gl.uniformMatrix4fv(uInvMatrix, false, mInverse(m));

            let mesh = meshData[n].mesh;
            gl.bufferData(gl.ARRAY_BUFFER, mesh, gl.STATIC_DRAW);
            gl.drawArrays(meshData[n].type ? gl.TRIANGLE_STRIP : gl.TRIANGLES, 0, mesh.length / vertexSize);
        }
    }, 30);
}