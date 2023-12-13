function multiplyMatrixVector(matrix, vector) {
    var result = [0, 0, 0];

    for (var i = 0; i < 3; i++) {
        for (var j = 0; j < 3; j++) {
            result[i] += matrix[i][j] * vector[j];
        }
    }

    return result;
}

function rotateX(theta) {
    var c = Math.cos(theta);
    var s = Math.sin(theta);

    return [
        [1, 0, 0],
        [0, c, -s],
        [0, s, c]
    ];
}

function rotateY(theta) {
    var c = Math.cos(theta);
    var s = Math.sin(theta);

    return [
        [c, 0, s],
        [0, 1, 0],
        [-s, 0, c]
    ];
}

function addVectors(v1, v2) {
    return [v1[0] + v2[0], v1[1] + v2[1], v1[2] + v2[2]];
}

// ==========================

let mIdentity = () => [ 1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1 ];

let mInverse = m => {
   let dst = [], det = 0, cofactor = (c, r) => {
      let s = (i, j) => m[c+i & 3 | (r+j & 3) << 2];
      return (c+r & 1 ? -1 : 1) * ( (s(1,1) * (s(2,2) * s(3,3) - s(3,2) * s(2,3)))
                                  - (s(2,1) * (s(1,2) * s(3,3) - s(3,2) * s(1,3)))
                                  + (s(3,1) * (s(1,2) * s(2,3) - s(2,2) * s(1,3))) );
   }
   for (let n = 0 ; n < 16 ; n++) dst.push(cofactor(n >> 2, n & 3));
   for (let n = 0 ; n <  4 ; n++) det += m[n] * dst[n << 2]; 
   for (let n = 0 ; n < 16 ; n++) dst[n] /= det;
   return dst;
}
let matrixMultiply = (a, b) => {
   let dst = [];
   for (let n = 0 ; n < 16 ; n++)
      dst.push(a[n&3]*b[n&12] + a[n&3|4]*b[n&12|1] + a[n&3|8]*b[n&12|2] + a[n&3|12]*b[n&12|3]);
   return dst;
}
let mTranslate = (tx,ty,tz, m) => {
   return matrixMultiply(m, [1,0,0,0, 0,1,0,0, 0,0,1,0, tx,ty,tz,1]);
}
let mRotateX = (theta, m) => {
   let c = Math.cos(theta), s = Math.sin(theta);
   return matrixMultiply(m, [1,0,0,0, 0,c,s,0, 0,-s,c,0, 0,0,0,1]);
}
let mRotateY = (theta, m) => {
   let c = Math.cos(theta), s = Math.sin(theta);
   return matrixMultiply(m, [c,0,-s,0, 0,1,0,0, s,0,c,0, 0,0,0,1]);
}
let mRotateZ = (theta, m) => {
   let c = Math.cos(theta), s = Math.sin(theta);
   return matrixMultiply(m, [c,s,0,0, -s,c,0,0, 0,0,1,0, 0,0,0,1]);
}
let mScale = (sx,sy,sz, m) => {
   return matrixMultiply(m, [sx,0,0,0, 0,sy,0,0, 0,0,sz,0, 0,0,0,1]);
}
let mPerspective = (fl, m) => {
   return matrixMultiply(m, [1,0,0,0, 0,1,0,0, 0,0,1,-1/fl, 0,0,0,1]);
}