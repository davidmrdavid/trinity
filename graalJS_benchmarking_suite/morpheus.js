// Copyright 2021 David Justo, Shaoqing Yi, Nadia Polikarpova,
//     Lukas Stadler and, Arun Kumar
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//     http://www.apache.org/licenses/LICENSE-2.0
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// This file contains all of the code for the JS experiments, divided into
// sections for readability.

const fs = require('fs');
const mathjs = require('mathjs');

const math = mathjs.create(mathjs.all);

// The Normalized Matrix interface in R, which in turn
// delegates its operator semantics to MorpheusDSL. ===================
function NormMatrix (S, Ks, Rs, morph=null) {

    if(morph) {
        this.morph = morph;
        return this;
    }

    let constructor2 = Polyglot.eval("morpheusDSL", "");
    const dims = S.size();
    const sEmpty = dims[0] == dims[1] && dims [1] == 0;
    let avatar = new TensorFromMatrix();
    this.morph = constructor2.build(S, Ks, Rs, sEmpty, avatar);
    return this;
}

NormMatrix.prototype.isNormMatrix = true
NormMatrix.prototype.toString = function () {
    return 'NormMatrix:' + this.value
}

// define a new datatype
math.typed.addType({
    name: 'NormMatrix',
    test: function (x) {
        // test whether x is of type NormMatrix
        return x && x.isNormMatrix
    }
})
 
// Enable Math.JS operators to work on the NormalizedMatrix ==============
const addScalar = math.typed('addScalar', {
    'NormMatrix, number': function (a, b) {
        let newMorph = a.morph.scalarAddition(b);
        return new NormMatrix(null, null, null, newMorph);
    },
    'number, NormMatrix': function (a, b) {
        let newMorph = b.morph.scalarAddition(a);
        return new NormMatrix(null, null, null, newMorph);
    }
})

const subtract = math.typed('subtract', {
    'NormMatrix, number': function (a, b) {
        let newMorph = a.morph.scalarMultiplication(b);
        return new NormMatrix(null, null, null, newMorph);
    },
    'number, NormMatrix': function (a, b) {
        let newMorph = b.morph.scalarMultiplication(a);
        return new NormMatrix(null, null, null, newMorph);
    }
}) 

const multiply = math.typed('multiply', {
    'NormMatrix, number': function (a, b) {
        let newMorph = a.morph.scalarMultiplication(b);
        return new NormMatrix(null, null, null, newMorph);
    },
    'number, NormMatrix': function (a, b) {
        let newMorph = b.morph.scalarMultiplication(a);
        return new NormMatrix(null, null, null, newMorph);
    },
    'Matrix, NormMatrix': function (a, b) {
        let res = b.morph.rightMatrixMultiplication(a);
        return res;
    },
    'NormMatrix, Matrix': function (a, b) {
        let res = a.morph.leftMatrixMultiplication(b);
        return res;
    }
})

const dotPow = math.typed('dotPow', {
    'NormMatrix, number': function (a, b) {
        let newMorph = a.morph.scalarExponentiation(b);
        return new NormMatrix(null, null, null, newMorph);
    }
})

const transpose = math.typed('transpose', {
    'NormMatrix': function (a) {
        let newMorph = a.morph.transpose();
        
    let avatar = new TensorFromMatrix();


        return new NormMatrix(null, null, null, newMorph, avatar)
    }
})

const rowSum = math.typed('rowSum', {
    'Matrix': function (a) {
        return math.reshape(math.apply(a, 1, math.sum), [a.size()[0], 1]);

    },
    'NormMatrix': function (a) {
        let res = a.morph.rowSum();
        return res;

    }
})

const colSum = math.typed('colSum', {
    'Matrix': function (a) {
        return math.reshape(math.apply(a, 0, math.sum), [1, a.size()[1]]);
    },
    'NormMatrix': function (a) {
        let res = a.morph.columnSum();
        return res;

    }
})

const sum = math.typed('sum', {
    'NormMatrix': function (a) {
        let res = a.morph.elementWiseSum(); 
        return res.get([0, 0]);

    }
})


math.import({
    addScalar: addScalar,
    subtract: subtract,
    multiply: multiply, 
    dotPow: dotPow, 
    transpose: transpose,
    rowSum: rowSum,
    colSum: colSum,
    sum: sum
})

// Implement MatrixLib interface in terms of Math.JS operations ==============
class TensorFromMatrix {

    constructor() {
    }

    scalarAddition(matrix, number) {
        let res = math.add(matrix, number);
        return res;
    }

    scalarMultiplication(matrix, number) {
        let res = math.multiply(matrix, number);
        return res;
    }

    scalarExponentiation(matrix, number) {
        let res = math.exp(matrix);
        return res;
    }

    leftMatrixMultiplication(matrix, otherMatrix) {
        let res = math.multiply(matrix, otherMatrix);
        return res;
    }

    rightMatrixMultiplication(matrix, otherMatrix) {
        let res = math.multiply(otherMatrix, matrix);
        return res; 
    }

    crossProduct(matrix, otherMatrix) {
        return math.cross(matrix, otherMatrix);
    }

    rowSum(matrix) {
        let res = math.reshape(math.apply(matrix, 1, math.sum), [matrix.size()[0], 1]);
        return res;
    }

    columnSum(matrix) {
        let res = math.reshape(math.apply(matrix, 0, math.sum), [1, matrix.size()[1]]);
        return res;
    }

    elementWiseSum(matrix) {
        return math.sum(matrix);
    }

    rowWiseAppend(matrix, otherMatrix) {
        let res = math.concat(matrix, otherMatrix, 0);
        return res;
    }

    columnWiseAppend(matrix, otherMatrix) {
        let res = math.concat(matrix, otherMatrix, 1);
        return res;
    }

    matrixAddition(matrix, otherMatrix) {
        let res = math.add(matrix, otherMatrix);
        return res;
    }

    transpose(matrix) {
        let res = math.transpose(matrix);
        return res;
    }

    splice(matrix, rowBeg, rowEnd, colBeg, colEnd) {
        const rowRange = math.range(rowBeg, rowEnd + 1);
        const colRange = math.range(colBeg, colEnd + 1);
        let res = math.subset(matrix, math.index(rowRange, colRange));
        return res;
    }

    getNumRows(matrix) {
        return matrix.size()[0];
    }

    getNumCols(matrix) {
        return matrix.size()[1];
    }

    removeAbstractions() {
        return this.removeAbstractions(this.matrix);
    }

    unwrap() {
        return matrix;
    }
}


// Algorithm implementations in JS, many remained unused in the paper ==============
class NormalizedLinearRegression {

    constructor(iterations=20, gamma=0.000001){
        this.gamma = gamma
        this.iterations = iterations
    }

    fit(X, y, winit){
        this.w = winit
        let Xtrans = math.transpose(X)
        let newW = null;
        for(let i = 0; i < this.iterations; i++) {
            newW = math.multiply(X, this.w)
            newW = math.subtract(newW, y)
            newW = math.multiply(Xtrans, newW)
            this.w = math.subtract(this.w, math.multiply(this.gamma, newW))
        }
        return this
    }
}

class NormalizedLogisticRegression {

    constructor(iterations=20, gamma=0.000001){
        this.gamma = gamma
        this.iterations = iterations
    }

    fit(X, y, winit){
        this.w = winit
        let newW = null;
        let Xtrans = math.transpose(X)
        for(let i = 0; i < this.iterations; i++) {
            newW = math.multiply(X, this.w)

            newW = math.exp(newW)

            newW = math.add(1, newW)

            newW = math.dotDivide(y, newW)

            newW = math.multiply(Xtrans, newW)

            this.w = math.subtract(this.w, math.multiply(this.gamma, newW))
        }
        return this
    }
}

class NormalizedKMeans {

    constructor(iterations=20, centerNum=3, nRows=0){
        this.centerNum = centerNum
        this.iterations = iterations
        this.nRows = nRows
    }

    fit(X, kCenter){
        let values = this.kMeans(X, this.iterations, this.centerNum, kCenter, this.nRows);
        this.kCenter = values[0];
        this.ya = values[1];
        return this
    }

    kMeans(data, iterations, centerNum, kCenter, rows) {
        let allOne = math.ones(rows, 1)
        let allOneK = math.ones(1, centerNum) 
        let allOneC = math.ones(kCenter.size()[0], 1) 
        let t2Prev = math.rowSum(math.dotPow(data, 2));
        let t2 = math.multiply(t2Prev, allOneK)
        let t22 = math.multiply(data ,2)
        let ya = null
        let dataTrans = math.transpose(data)
        for(let i = 0; i < iterations; i++) {
            let kCenterPow = math.dotPow(kCenter, 2);
            let kCenterSum = math.reshape(math.apply(kCenterPow, 0, math.sum), [1, kCenterPow.size()[1]]);
            let allOneProd = math.multiply(allOne, kCenterSum);
            let t22BykCenter = math.multiply(t22, kCenter);
            let dist = math.subtract(t2, math.add(t22BykCenter, allOneProd));

            ya = math.equal(dist, math.multiply(math.reshape(math.min(dist,1), [dist.size()[0], 1]), allOneK))
            // ^^ Triple check that `ya` is correctly computed. Verify dims?

            //ya = math.equal(dist, math.multiply(math.min(dist,), allOneK))
            let yaSumRows = math.reshape(math.apply(ya, 0, math.sum), [1, ya.size()[1]]);

            let numerator = math.multiply(dataTrans, ya);

            let denominator = math.multiply(allOneC, yaSumRows);

            kCenter = math.dotDivide(numerator, denominator);
        }

        return [kCenter, ya];
    }
}

class GaussianNMF {

    constructor(iterations=20, components=5){
        this.components = components
        this.iterations = iterations
    }

    fit(X, winit, hinit) {
        this.w = winit
        this.h = hinit

        for(let i = 0; i < this.iterations; i++) {
            let wTrans = math.transpose(this.w)
            let numerator1 = math.multiply(wTrans, X)
            let denominator1 =  math.multiply(wTrans, math.multiply(this.w, this.h))
            let hProd = math.dotDivide(numerator1, denominator1)
            this.h = math.dotMultiply(this.h, hProd)

            let hTrans = math.transpose(this.h)
            let numerator2 = math.multiply(X, hTrans)
            let denominator2 =  math.multiply(this.w, math.multiply(this.h, hTrans))
            let wProd = math.dotDivide(numerator2, denominator2)
            this.w = math.dotMultiply(this.w, wProd) 
        }
        return this
    }
}

// Test runners ======================================================================
function doScalarAddition(x) {
    math.add(x, 42);
    return;
}

function doScalarMultiplication(x) {
    math.multiply(x, 42);
    return;
}

function doLeftMatrixMultiplication(x, lmmArg) {
    math.multiply(x, lmmArg);
    return;
}

function doRightMatrixMultiplication(x, rmmArg) {
    math.multiply(rmmArg, x);
    return;
}

function doRowWiseSum (x) {
    math.rowSum(x);
    return;
}

function doColumnWiseSum(x) {
    math.colSum(x);
    return;
}

function doElementWiseSum(x) {
    return;
}

function doLogisticRegression(x, logRegMaxIter, logRegWinit, logRegGamma, target) {
    m = new NormalizedLogisticRegression(logRegMaxIter, logRegGamma);
    m.fit(x, target, logRegWinit);
    return;
}

function doLinearRegression(x, logRegMaxIter, logRegWinit, logRegGamma, target) {
    m = new NormalizedLinearRegression(logRegMaxIter, logRegGamma);
    m.fit(x, target, logRegWinit);
    return;
}

function doKMeansClustering(x, logRegMaxIter, centerNumber, kCenter, nRows) {
    m = new NormalizedKMeans(logRegMaxIter, centerNumber, nRows);
    m.fit(x, kCenter);
    return;
}

// Helpers to run the experiments ====================================================

// Generate normalized matrix, its corresponding materialized matrix, and a target vector
function genMatrices(numRowsR, numColsS, tupRatio, featRatio) {

    // Computing matrix dims
    let numRowsS = numRowsR * tupRatio;
    let numColsR = numColsS * featRatio;
    let numRowsK = numRowsS;
    let numColsK = numRowsR;

    let S = math.random(math.matrix([numRowsS, numColsS]));
    let K = math.zeros(numRowsK, numColsK, 'sparse');
    for(let i = 0; i < numRowsK; i++) {
        K.set([i, math.randomInt(0, numColsK)], 1);
    }
    let R = math.random(math.matrix([numRowsR, numColsR]));
    KR = math.multiply(K, R)
    matMatrix = math.concat(S, KR, 1)
    Y = math.ones(math.matrix([numRowsS, 1]))


    let constructor = Polyglot.eval("morpheusDSL", "");

    // Build the norm matrix
    let morph = new NormMatrix(S, [K], [R]);

    let matrices = {
        "matMatrix": matMatrix,
        "target": Y,
        "normMatrix": morph
    }

    return matrices;
}

// Exports argument-less functions that execute a chosen benchmark over a given matrix
// representation. 
function getTasks(matrices, tasks) {

    let matDims = matrices.matMatrix.size();
    const nMat = matDims[0] ;
    const dMat = matDims[1];
    const nS = nMat;

    const lmmNumRows = dMat;
    const lmmNumCols = 2;
    const rmmNumRows = 2;
    const rmmNumCols = nMat;
    let lmmArg = math.random(math.matrix([lmmNumRows, lmmNumCols]));
    let rmmArg = math.random(math.matrix([rmmNumRows, rmmNumCols]));

    const logRegMaxIter = 20;
    const logRegGamma = 0.000001;
    let logRegWinit = math.random(math.matrix([dMat, 1]));

    const centerNumber = 10;
    const rowRange = math.range(0, centerNumber);
    const colRange = math.range(0, dMat);
    let kCenter = math.transpose(math.subset(matrices.matMatrix, math.index(rowRange, colRange)));

    // all tasks
    allTaskPairs = {
        "scalarAddition": doScalarAddition,
        "scalarMultiplication": doScalarMultiplication,
        "leftMatrixMultiplication": function(x) {
          doLeftMatrixMultiplication(x, lmmArg);
        },
        "rightMatrixMultiplication": function(x) {
          doRightMatrixMultiplication(x, rmmArg);
        },
        "transLefttMatrixMultiplication": function(x) {
          doTransLeftMatrixMultiplication(x, rmmArg);
        },
        "rowWiseSum": doRowWiseSum,
        "columnWiseSum": doColumnWiseSum,
        "elementWiseSum": doElementWiseSum,
        "logisticRegression": function(x) {
          doLogisticRegression(x, logRegMaxIter, logRegWinit, logRegGamma, matrices.target);
        },
        "linearRegression": function(x) {
          doLinearRegression(x, logRegMaxIter, logRegWinit, logRegGamma, matrices.target);
        },
        "kMeansClustering": function(x) {
          doKMeansClustering(x, logRegMaxIter, centerNumber, kCenter, nMat);
        }
    }

    let taskPairs = []
    let selectedTasks = tasks;
    for(let key of Object.keys(allTaskPairs)) {
        if(selectedTasks.includes(key)) {
            taskPairs.push({
                "name": key,
                "runner": allTaskPairs[key]
            });
        }
    }
    return taskPairs;
}

function getNanoSecTime() {
    const hrTime = process.hrtime();
    return hrTime[0] * 1000000000 + hrTime[1];

}

// compares the runtime difference between the materialized and normalized matrices
function compare(matrix, action, numTimes, numWarmups, fname) {

    let timeStart = 0;
    let timeEnd = 0;
    let timeDiff = 0;
    let result = 0;
    let times = [];
    var stream = fs.createWriteStream(fname, {flags:'a'});
    for(let i = 0; i < 25; i++) {
        timeStart = getNanoSecTime();
        result = action(matrix);
        timeEnd = getNanoSecTime();
        timeDiff = (timeEnd - timeStart)/1000000000;
        console.log("iteration: ", i,"/ 25 |","current timeDiff", timeDiff);
        stream.write(timeDiff.toString() + "\n");
        times.push(timeDiff);
    }
    stream.end();
    return result;
}

// aproximate equality check between the results of some operator across matrix representations
function compareEquality(matMat, normMat, action) {
    let res1 = action(matMat);
    let res2 = action(normMat);
    console.log(math.equal(res1, res2));
}

// The test driver, parses its cli arguments and runs the tests
function main () {
    // parse args
    const args = process.argv.slice(2);
    const fpath = args[0];
    const actionParam = args[1];
    const numTimes = args[2];
    const outputDir = args[3];
    const mode = args[4];
    const override = args[5];
    const TR = parseInt(args[6], 10);
    const FR = parseInt(args[7], 10);

    // read dataset metadata
    let rawdata = fs.readFileSync(fpath);
    let datasetMeta = JSON.parse(rawdata);

    // create outputDir
    if (!fs.existsSync(outputDir)){
        fs.mkdirSync(outputDir);
    }

    // tasks
    let algorithm_tasks = ["nogisticRegression", "kMeansClustering"];
    let microbench_tasks = [
        "scalarAddition", "scalarMultiplication",
        "leftMatrixMultiplication", "rightMatrixMultiplication",
        "rowWiseSum", "columnWiseSum", "elementWiseSum"
    ];

    // task selection
    let tasks = []
    if (actionParam == "all") {
        tasks = microbench_tasks.concat(algorithm_tasks);
    }
    else if (actionParam == "micro") {
        tasks = microbench_tasks
    }
    else if (actionParam == "algorithm") {
        tasks = algorithm_tasks
    }
    else if (actionParam == "test") {
        tasks = ["leftMatrixMultiplication", "rightMatrixMultiplication",
                 "rowWiseSum", "columnWiseSum", "elementWiseSum"]
    }
    else {
        tasks = [actionParam]
    }

    // benchmarking loop
    let TRs = [1];
    let FRs = [1];

    let dataIsSynthetic = datasetMeta["name"] == "synthesized";
    if (dataIsSynthetic) {
        TRs = datasetMeta["TRs"];
        FRs = datasetMeta["FRs"];
    }

   if(override == "T"){
       TRs = [TR]
       FRs = [FR]
   }

    console.log("Beginning benchmarking loop");
    for(let i = 0; i < TRs.length; i++) {
        for(let j = 0; j < FRs.length; j++) {
            let TR = TRs[i];
            let FR = FRs[j];
            let matrices = null;
            if(datasetMeta["name"] == "synthesized"){
                matrices = genMatrices(datasetMeta["nR"], datasetMeta["dS"], TR, FR);
            }
            else {
                matrices = loadDataset(mode, datasetMeta);
            }
            let taskPairs = getTasks(matrices, tasks);
            for(let k = 0; k < taskPairs.length; k++) {
                let pair = taskPairs[k];
                console.log(pair.name, "TR=", TR, "FR=", FR);
                let results = null;
                if(actionParam != "test"){

                  let fname = outputDir + "/" + pair.name  + "_" + "TR=" + TR + "_"  + "FR=" + FR + "_"+ mode + ".txt";
                  if(mode == "trinity"){
                      results = compare(matrices.normMatrix, pair.runner, numTimes, 0, fname);
                  }
                  else {
                      results = compare(matrices.matMatrix, pair.runner, numTimes, 0, fname);
                  }
                }
                else{
                    compareEquality(matrices.matMatrix, matrices.normMatrix, pair.runner);
                    let notLmm = pair.name != "leftMatrixMultiplication";
                    let notRmm = pair.name != "rightMatrixMultiplication";
                    let checkTrans = notLmm && notRmm;
                    if(checkTrans){
                        compareEquality(math.transpose(matrices.matMatrix), 
                                 math.transpose(matrices.normMatrix), pair.runner);
                    }
                }
            }
        }
    }



}

main()
