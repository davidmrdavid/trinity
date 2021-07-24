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

# This file implements the Normalized Matrix interface in R, which in turn
# delegates its operator semantics to MorpheusDSL.

source("matrixLibAdapter.r")

# Adapter, stores NM as member variable
NormalizedMatrix <- setClass(
   "NormalizedMatrix",
   slot = c(morpheus = "ANY")
)

# Adapter constructor
asNormalizedMatrix <- function(S, Ks, Rs, Sparse=FALSE) {

    # Obtain NM constructor, execute it, store it in adapter object,
    # return adapter
    morpheusBuilder <- eval.polyglot("morpheusDSL", "")

    Sempty <- FALSE
    if(nrow(S)*ncol(S) == 0){
        Sempty <- TRUE
    }
    avatar <- MatrixLibAdapter2(Sparse=Sparse)
    morpheus <- morpheusBuilder@build(S, Ks, Rs, Sempty, avatar)
    normMatrix <- NormalizedMatrix(morpheus=morpheus)
    return(normMatrix)
}

setMethod("show", "NormalizedMatrix", function(object){
    print("A NormalizedMatrix")
})

setMethod("+", c("numeric", "NormalizedMatrix"), function(e1, e2) {
    result <- e2@morpheus@scalarAddition(e1)
    newNormalizedMatrix <- NormalizedMatrix(morpheus=result)
    return(newNormalizedMatrix)
})

setMethod("+", c("NormalizedMatrix", "numeric"), function(e1, e2) {
    result <- e1@morpheus@scalarAddition(e2)
    newNormalizedMatrix <- NormalizedMatrix(morpheus=result)
    return(newNormalizedMatrix)
})

setMethod("-", c("numeric", "NormalizedMatrix"), function(e1, e2) {
    result <- e2@morpheus@scalarAddition(e1)
    newNormalizedMatrix <- NormalizedMatrix(morpheus=result)
    return(newNormalizedMatrix)
})

setMethod("-", c("NormalizedMatrix", "numeric"), function(e1, e2) {
    result <- e1@morpheus@scalarAddition(e2)
    newNormalizedMatrix <- NormalizedMatrix(morpheus=result)
    return(newNormalizedMatrix)
})

setMethod("*", c("numeric", "NormalizedMatrix"), function(e1, e2) {
    result <- e2@morpheus@scalarMultiplication(e1)
    newNormalizedMatrix <- NormalizedMatrix(morpheus=result)
    return(newNormalizedMatrix)
})

setMethod("*", c("NormalizedMatrix", "numeric"), function(e1, e2) {
    result <- e1@morpheus@scalarMultiplication(e2)
    newNormalizedMatrix <- NormalizedMatrix(morpheus=result)
    return(newNormalizedMatrix)
})

setMethod("/", c("numeric", "NormalizedMatrix"), function(e1, e2) {
    preppedArg <- 1/e2
    e1@morpheus = e1@morpheus@scalarMultiplication(preppedArg)
    newNormalizedMatrix <- NormalizedMatrix(morpheus=result)
    return(newNormalizedMatrix)
})

setMethod("/", c("NormalizedMatrix", "numeric"), function(e1, e2) {
    preppedArg <- 1/e1
    result <- e2@morpheus@scalarMultiplication(preppedArg)
    newNormalizedMatrix <- NormalizedMatrix(morpheus=result)
    return(newNormalizedMatrix)
})

# TODO: In the past, we've encountered a few instances of
# exponentiation yielding the wrong output shape / datatype.
# For correctness' sake, this could use further testing,
# but it isn't used in the paper's evaluation
setMethod("^", c("NormalizedMatrix", "numeric"), function(e1, e2) {
    result <- e1@morpheus@scalarExponentiation(e2)
    newNormalizedMatrix <- NormalizedMatrix(morpheus=result)
    return(newNormalizedMatrix)
})

setMethod("^", c("numeric", "NormalizedMatrix"), function(e1, e2) {
    result <- e2@morpheus@scalarExponentiation(e1)
    newNormalizedMatrix <- NormalizedMatrix(morpheus=result)
    return(newNormalizedMatrix)
})

setMethod("%*%", c("ANY", "NormalizedMatrix"), function(x, y) {
    result <- y@morpheus@rightMatrixMultiplication(x)
    return(result);
})

setMethod("%*%", c("NormalizedMatrix", "ANY"), function(x, y) {
    result <- x@morpheus@leftMatrixMultiplication(y)
    return(result);
})


setMethod("sum", c("NormalizedMatrix"), function(x) {
    result <- x@morpheus@elementWiseSum()
    return(result);
})

setMethod("rowSums", c("NormalizedMatrix"), function(x) {
    result <- x@morpheus@rowSum()
    return(result)
})

setMethod("colSums", c("NormalizedMatrix"), function(x) {
    result <- x@morpheus@columnSum()
    return(result)
})

't.NormalizedMatrix' <- function(x) {
    result <- x@morpheus@transpose()
    newNormalizedMatrix <- NormalizedMatrix(morpheus=result)
    return(newNormalizedMatrix)
}

setMethod("crossprod", c("NormalizedMatrix", "ANY"), function(x, y = NULL) {
    result <- x@morpheus@crossProduct();
    return(result);
})
