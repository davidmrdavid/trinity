# Copyright 2021 David Justo, Shaoqing Yi, Nadia Polikarpova,
#     Lukas Stadler and, Arun Kumar
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This file exports our utility/helper functions for R experients.

library(Matrix)
library(data.table)
library("jsonlite")
source("normalizedMatrix.r")
source("macroBenchmarks.r")

# Helper Functions for the Polyglot (R + Python) experiment ==============

# Generates random matrices, in R, for the Python driver to request.
genRanMatrixForPy <- function(numRows, numCols) {
  area = numRows * numCols
  M = Matrix(runif(area, min=0, max=1), numRows, numCols)
  return(M);
}

# Generates a Materialized Matrix, its corresponding Normalized Matrix,
# and a target vector for use in Python, but represented in R datatypes ====
genMatricesForPy <- function(numRowsR, numColsS, tupRatio, featRatio) {
  
  # Computing matrix dims
  numRowsS = numRowsR * tupRatio 
  numColsR = numColsS * featRatio
  numRowsK = numRowsS
  numColsK = numRowsR

  # num of elements per matrix
  areaS = numRowsS * numColsS
  areaR = numRowsR * numColsR
  areaK = numRowsK * numColsK

  # generating the matrices
  S = Matrix(runif(areaS, min=0, max=1), numRowsS, numColsS)
  keys = sample.int(numColsK, numRowsK, replace=TRUE)
  K1 = sparseMatrix(i=1:length(keys), j=keys, dims=c(numRowsK, numColsK))
  R1 = Matrix(runif(areaR, min=0, max=1), numRowsR, numColsR)

  # generate materialized matrix
  KR = K1 %*% R1 
  materializedMatrix = cbind(S, KR)

  nMat = nrow(materializedMatrix)
  dMat = ncol(materializedMatrix)

  Y =((Matrix(runif(nMat, 0, 1), nMat, 1)) > 0.5)

  # package them and return
  matrices = list(
    S = S,
    K = list(K1),
    R = list(R1),
    matMatrix = materializedMatrix,
    target = Y,
    avatar = MatrixLibAdapter2(Sparse=FALSE)
  )

  return(matrices)
}

# Matrix/dataset loading and generation procedures ===============================
loadDataset <- function(mode, params) {

  SDir = params$SDir;
  FK1dir = params$FK1dir;
  FK2dir = params$FK2dir;
  R1dir = params$R1S;
  R2dir = params$R2S;
  Ydir = params$Ydir;
  binarizeTarget = params$binarizeTarget

  S = matrix(0,0,0);
  if(SDir != ""){
    if(params$outputMeta != "Walmart"){
      S <- readMM(file=SDir)
    }
    else {
      S <- as.matrix(read.table(SDir, header=TRUE));
    }
  }

  dS = nrow(S);
  JSet1 = as.matrix(read.table(FK1dir,header=TRUE)); 
  nS = nrow(JSet1);
  nR1 = max(JSet1);
  FK1 = sparseMatrix(i=c(1:nS),j=JSet1,x=1,dims=c(nS,nR1));
  R1S = readMM(file=R1dir)+0;
  dR1 = ncol(R1S);

  JSet2 = as.matrix(read.table(FK2dir,header=TRUE)); 
  nS = nrow(JSet2);
  nR2 = max(JSet2);
  FK2 = sparseMatrix(i=c(1:nS),j=JSet2,x=1,dims=c(nS,nR2));
  R2S = readMM(file=R2dir)+0;
  dR2 = ncol(R2S);

  Ytest = as.matrix((read.table(Ydir, header=TRUE)))

  Y = Ytest + 0
  if(binarizeTarget) {
    Y = (Ytest > 2.5)+0;
  }

  FK3 = 0;
  R3S = 0; 

  materializedMatrix <- cbind(FK1%*%R1S, FK2%*%R2S)
  if(params$outputMeta == "Flights") {
    
    FK3dir = params$FK3dir;
    R3dir = params$R3S;

    JSet3 = as.matrix(read.table(FK3dir,header=TRUE)); 
    nS = nrow(JSet3);
    nR3 = max(JSet3);
    FK3 = sparseMatrix(i=c(1:nS),j=JSet3,x=1,dims=c(nS,nR3));
    R3S = readMM(file=R3dir)+0;
    dR3 = ncol(R3S);

    materializedMatrix <- cbind(materializedMatrix, FK3%*%R3S)
    
  }

  if(SDir != "") {
    materializedMatrix <- cbind(S, materializedMatrix)
  }
  data <- materializedMatrix 
  if(mode == "trinity"){
    if(params$outputMeta == "Flights"){
      data <- asNormalizedMatrix(S, list(FK1, FK2, FK3), list(R1S, R2S, R3S), TRUE)
    }
    else{
      data <- asNormalizedMatrix(S, list(FK1, FK2), list(R1S, R2S), TRUE)
    }
  }
  else if(mode == "morpheusR"){
    if(params$outputMeta == "Flights"){
      data <- NormalMatrix(EntTable = list(S),
                   AttTables = list(R1S, R2S, R3S),
                   KFKDs = list(FK1, FK2, FK3),
                   Sparse = TRUE);


    }
    else{
      data <- NormalMatrix(EntTable = list(S),
                   AttTables = list(R1S, R2S),
                   KFKDs = list(FK1, FK2),
                   Sparse = TRUE);
    }
  }

  else{ 
    data <- materializedMatrix
  }
  
  nMat <- nrow(materializedMatrix)
  dMat <- ncol(materializedMatrix)
  matrices = list(
    data = data,
    matMatrix = materializedMatrix,
    target = Y,
    nMat = nMat,
    dMat = dMat
  ) 
  return(matrices)

}

genBaseMatrices <- function(numRowsR, numColsS, tupRatio, featRatio) {

  # Computing matrix dims
  numRowsS = numRowsR * tupRatio 
  numColsR = numColsS * featRatio
  numRowsK = numRowsS
  numColsK = numRowsR

  # num of elements per matrix
  areaS = numRowsS * numColsS
  areaR = numRowsR * numColsR
  areaK = numRowsK * numColsK

  # generating the matrices
  S = Matrix(runif(areaS, min=0, max=1), numRowsS, numColsS)
  keys = sample.int(numColsK, numRowsK, replace=TRUE)
  K = sparseMatrix(i=1:length(keys), j=keys, dims=c(numRowsK, numColsK))
  R = Matrix(runif(areaR, min=0, max=1), numRowsR, numColsR)


  nMat = numRowsS
  dMat = numColsS + numColsR

  # Packet base matrices
  matrices = list(
    S = S,
    K = K,
    R = R,
    nMat = nMat,
    dMat = dMat
  )

  return(matrices)
}

genBaseMatricesExtended <- function(numRowsR, numColsS, tupRatio, featRatio) {

  # Computing matrix dims
  numRowsS = numRowsR * tupRatio 
  numColsR = numColsS * featRatio
  numRowsK = numRowsS
  numColsK = numRowsR

  # num of elements per matrix
  areaS = numRowsS * numColsS
  areaR = numRowsR * numColsR
  areaK = numRowsK * numColsK

  # generating the matrices
  S = Matrix(runif(areaS, min=0, max=1), numRowsS, numColsS)
  keys = sample.int(numColsK, numRowsK, replace=TRUE)
  K1 = sparseMatrix(i=1:length(keys), j=keys, dims=c(numRowsK, numColsK))
  R1 = Matrix(runif(areaR, min=0, max=1), numRowsR, numColsR)
  K2 = sparseMatrix(i=1:length(keys), j=keys, dims=c(numRowsK, numColsK))
  R2 = Matrix(runif(areaR, min=0, max=1), numRowsR, numColsR)
  K3 = sparseMatrix(i=1:length(keys), j=keys, dims=c(numRowsK, numColsK))
  R3 = Matrix(runif(areaR, min=0, max=1), numRowsR, numColsR)
  K4 = sparseMatrix(i=1:length(keys), j=keys, dims=c(numRowsK, numColsK))
  R4 = Matrix(runif(areaR, min=0, max=1), numRowsR, numColsR)

  nMat = numRowsS
  dMat = numColsS + (numColsR*4)

  # Packet base matrices
  matrices = list(
    S = S,
    K1 = K1,
    R1 = R1,
    K2 = K2,
    R2 = R2,
    K3 = K3,
    R3 = R3,
    K4 = K4,
    R4 = R4,
    nMat = nMat,
    dMat = dMat
  )

  return(matrices)
}


genDatasetExtended <- function(mode, numRowsR, numColsS, tupRatio, featRatio) {
  
  matrices <- genBaseMatricesExtended(numRowsR, numColsS, tupRatio, featRatio)
  S <- matrices$S;
  K1 <- matrices$K1;
  R1 <- matrices$R1;
  K2 <- matrices$K2;
  R2 <- matrices$R2;
  K3 <- matrices$K3;
  R3 <- matrices$R3;
  K4 <- matrices$K4;
  R4 <- matrices$R4;
  
  nMat <- matrices$nMat
  dMat <- matrices$dMat

  if(mode == "trinity") {

    data <- asNormalizedMatrix(
      S,
      list(K1, K2, K3, K4),
      list(R1, R2, R3, R4)
    )
  }
  else if(mode == "materialized") {

    KR1 <- K1 %*% R1
    KR2 <- K2 %*% R2
    KR3 <- K3 %*% R3
    KR4 <- K4 %*% R4
    data <- cbind(S, KR1, KR2, KR3, KR4)
  }
  else {
    print("MorpheusR")
    data <- NormalMatrix(
      EntTable = list(S),
      AttTables = list(R1, R2, R3, R4),
      KFKDs = list(K1, K2, K3, K4),
      Sparse = FALSE
    );
  }

  Y =((Matrix(runif(nMat, 0, 1), nMat, 1)) > 0.5)

  exit(-1)

  matrices = list(
    data = data,
    matMatrix = cbind(S, K1 %*% R1, K2 %*% R2, K3 %*% R3, K4 %*% R4),
    target = Y,
    nMat = nMat,
    dMat = dMat
  ) 

  return(matrices)
}


genDataset <- function(mode, numRowsR, numColsS, tupRatio, featRatio) {

  matrices <- genBaseMatrices(numRowsR, numColsS, tupRatio, featRatio)
  S <- matrices$S;
  K <- matrices$K;
  R <- matrices$R;
  
  nMat <- matrices$nMat
  dMat <- matrices$dMat

  if(mode == "trinity") {

    data <- asNormalizedMatrix(
      S,
      list(K),
      list(R)
    )
  }
  else if(mode == "materialized") {

    KR <- K %*% R
    data <- cbind(S, KR)
  }
  else {

    data <- NormalMatrix(
      EntTable = list(S),
      AttTables = list(R),
      KFKDs = list(K),
      Sparse = FALSE
    );
  }

  Y =((Matrix(runif(nMat, 0, 1), nMat, 1)) > 0.5)
  matrices = list(
    data = data,
    matMatrix = cbind(S, K %*% R),
    target = Y,
    nMat = nMat,
    dMat = dMat
  ) 

  return(matrices)
}

# Procedures to run and evaluate correctness and perf  ===============================

# Captures the runtime performance of a test scenario over some matrix representation
benchmarkIt <- function(action, numTimes, fname) {
  gc()
  times <- c()

  # Warm-up
  for(i in seq(1:5)){
    gc()
    tStart <- as.numeric(Sys.time())*1000;
    print(sprintf("WARMING: %s/5", i));
    action();
    tEnd <- as.numeric(Sys.time()) * 1000;
    time <- tEnd - tStart;
    write(time, file=fname, append=TRUE)
    times <- c(times, time);
  }
  
  # warmed-up runs
  for(i in seq(1:20)){
    gc()
    tStart <- as.numeric(Sys.time())*1000;
    print(sprintf("BENCHMARKING: %s/20", i));
    action();
    tEnd <- as.numeric(Sys.time()) * 1000;
    time <- tEnd - tStart;
    write(time, file=fname, append=TRUE)
    times <- c(times, time);
  } 
  gc()
  return(times)
}

# Helper for testing the approximate equality between the output of operators
# on the normalized and materialized matrix representations. Needs to be modified
# with an approximate equality check between res1 and res, depending on the operation
# of choice.
checkEquivalence <- function(action1, action2) {
  gc();
  
  res1 <- action1();
  gc();
  
  res2 <- action2();
  gc();
  
  gc();
  return(0);
}

# Exports argument-less functions that execute a chosen benchmark over a given matrix
# representation. 
getTasks <- function(params, nMat, dMat, T, target, tasks) {
 
  lmmNumRows <- dMat
  lmmNumCols <- 2
  rmmNumRows <- 2
  rmmNumCols <- nMat
  lmmArgArea <-lmmNumRows * lmmNumCols
  rmmArgArea <-rmmNumRows * rmmNumCols
  lmmArg <- Matrix(runif(lmmArgArea, min=0, max=1), lmmNumRows, lmmNumCols)
  rmmArg <- Matrix(runif(rmmArgArea, min=0, max=1), rmmNumRows, rmmNumCols)

  logRegMaxIter = 20
  logRegGamma = 0.000001
  logRegWinit = Matrix(runif(dMat,0, 1), dMat, 1)

  components = 5;
  wGNMF = Matrix(runif(nMat*components,0, 1), nMat, components); 
  hinit = Matrix(runif(dMat*components,0, 1), components, dMat);

  centerNumber = 10;
  kCenter = as.matrix(t(T[1:centerNumber, 1:dMat]));
  nS = nMat

  allTaskPairs <- list(
    list(name="scalarAddition", runner=doScalarAddition),
    list(name="scalarMultiplication", runner=doScalarMultiplication),
    list(name="leftMatrixMultiplication", runner=function(x){
      doLeftMatrixMultiplication(x, lmmArg)
    }),
    list(name="rightMatrixMultiplication", runner=function(x){
      doRightMatrixMultiplication(x, rmmArg)
    }),
    list(name="transLefttMatrixMultiplication", runner=function(x){
      doTransLeftMatrixMultiplication(x, rmmArg)
    }),
    list(name="crossProduct", runner=function(x){
      doCrossProduct(x);
    }),
    list(name="rowWiseSum", runner=doRowWiseSum),
    list(name="columnWiseSum", runner=doColumnWiseSum),
    list(name="elementWiseSum", runner=doElementWiseSum),
    list(name="logisticRegression", runner=function(x) {
      doLogisticRegression(x, logRegMaxIter, logRegWinit, logRegGamma, target)
    }),
    list(name="linearRegression", runner=function(x) {
      doLinearRegression(x, logRegMaxIter, logRegWinit, logRegGamma, target)
    }),
    list(name="kMeansClustering", runner=function(x) {
      
      doKMeansClustering(x, logRegMaxIter, centerNumber, kCenter, nS)
    }),
    list(name="GNMFClustering", runner=function(x) {
      doGNMFClustering(x, logRegMaxIter, wGNMF, hinit)
    })
  )

  taskPairs <- list()
  selectedTasks <- tasks
  
  for(pair in allTaskPairs){

    if(pair$name %in% selectedTasks){
      taskPairs <- append(taskPairs, list(pair));
    }
  }
  
  return(taskPairs)
}

