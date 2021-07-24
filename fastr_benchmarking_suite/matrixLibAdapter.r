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

# This file implements our MatrixLib adapter in R. It maps the MatrixLib
# interface we define in GraalVM to concrete operators in R. Additionally,
# it includes optimized operator implementations based on the input shape
# and representation.

library(Matrix)

MatrixLibAdapter2 <- setClass(
  "MatrixLibAdapter2",
   slot = c(
     Sparse = "logical",
     rowSum = "ANY",
     columnSum = "ANY",
     leftMatrixMultiplication = "ANY",
     rightMatrixMultiplication = "ANY",
     columnWiseAppend = "ANY",
     transpose = "ANY",
     crossProduct = "ANY",
     crossProductDuo = "ANY",
     elementWiseSqrt = "ANY",
     rowWiseAppend = "ANY",
     diagonal = "ANY",
     splice = "ANY",
     matrixAddition = "ANY",
     getNumRows = "ANY",
     getNumCols = "ANY",
     scalarAddition = "ANY",
     scalarMultiplication = "ANY",
     scalarExponentiation = "ANY",
     elementWiseSum = "ANY"
   )
)


setMethod("initialize", "MatrixLibAdapter2",

    function(.Object, Sparse) {
    .Object@Sparse = Sparse
	.Object@rowSum = function(x) {
            return(rowSum(x));
        }
        .Object@columnSum = function(x) {
            return(columnSum(x));
        }
        .Object@rightMatrixMultiplication = function(x, y) {
            z <- rightMatrixMultiplication(x, y)
            
            if(!Sparse & (toString(class(x)) == "ngCMatrix" | toString(class(y)) == "ngCMatrix")){ #SPARSE check
                z <- as.matrix(z)
            }
            dims <- dim(z)
            if(dims[2] == 1){
                z <- as.numeric(z)
            }
            return(z)
        }
        .Object@scalarAddition = function(x, y){
            return(scalarAddition(x,y));
  
        }
        .Object@scalarMultiplication = function(x, y){
            return(scalarMultiplication(x,y));
  
        }
        .Object@scalarExponentiation = function(x, y){
            return(scalarExponentiation(x, y))
        }
        .Object@leftMatrixMultiplication = function(x, y) {
            z <- leftMatrixMultiplication(x, y)
            
            if(!Sparse & (toString(class(x)) == "ngCMatrix" | toString(class(y)) == "ngCMatrix")){ #SPARSE check
                z <- as.matrix(z)
            }
            dims <- dim(z)
            if(dims[2] == 1){
                z <- as.numeric(z)
            }
            return(z)
        }
        .Object@columnWiseAppend = function(x, y) {
            return(columnWiseAppend(x, y));
        }
        .Object@transpose = function(x) {
            return(transpose(x));
        }
        .Object@crossProduct = function(x) {
            z <- crossProduct(x)
            if(!Sparse  & toString(class(x)) == "ngCMatrix"){
                z <- as.matrix(z)
            }
            return(z);
        }
        .Object@crossProductDuo = function(x, y) {
            z <- crossProductDuo(x, y)
            if(!Sparse & (toString(class(x)) == "ngCMatrix" | toString(class(y)) == "ngCMatrix")){
                z <- as.matrix(z)
            }
            return(z);
        }
        .Object@elementWiseSum = function(x) {
            return(elementWiseSum(x));
        }
	.Object@elementWiseSqrt = function(x) {
            return(elementWiseSqrt(x));
        }
        .Object@rowWiseAppend = function(x, y) {
            return(rowWiseAppend(x, y));
        }
        .Object@diagonal = function(x) {
            return(diagonal(x));
        }
        .Object@splice = function(x, rowBeg, rowEnd, colBeg, colEnd) {
            return(splice(x, rowBeg, rowEnd, colBeg, colEnd));
        }

        .Object@matrixAddition = function(x, y) {
            cast = FALSE;
            
            if((class(x) != "numeric")){
                d <- dim(x);
                x = as.numeric(x);
                cast = TRUE;
            }
            if((class(y) != "numeric")){
                d <- dim(y);
                y = as.numeric(y);
                cast = TRUE;
            }
            
            z <- matrixAddition(x, y);
            if(cast){
                dim(z) <- d;
            }
            return(z);
        }
        .Object@getNumCols = function(x) {
            return(getNumCols(x));

        }
        .Object@getNumRows = function(x) {
            z <- getNumRows(x)
            return(z);

        }
        return(.Object)
})



# Mapping the MatrixLib interface to concrete R operators =====================================

setGeneric("leftMatrixMultiplication", function(tensor, otherMatrix, foreignBackendOpt=FALSE) {    
    return(tensor %*% otherMatrix);
})

setGeneric("rightMatrixMultiplication", function(tensor, otherMatrix, foreignBackendOpt=FALSE) {
    return(otherMatrix %*% tensor);
})

setGeneric("scalarAddition", function(tensor, otherMatrix) {
    return(tensor + otherMatrix);
})

setGeneric("scalarExponentiation", function(tensor, number) {
        return(tensor ^ number);
})

setGeneric("scalarMultiplication", function(tensor, scalar) {
    return(tensor * scalar);
})

setGeneric("crossProduct", function(tensor) {
    return(tensor * normMatrix);
})

setGeneric("rowSum", function(tensor, foreignBackendOpt=FALSE) {
    return(rowSums(tensor));
})

setGeneric("columnSum", function(tensor, foreignBackendOpt=FALSE) {
    return(colSums(tensor));
})

setGeneric("elementWiseSum", function(tensor) {
    return(sum(tensor));
})

setGeneric("rowWiseAppend", function(tensor, otherMatrix, foreignBackendOpt=FALSE) {
    return(rbind(tensor, otherMatrix));
})

setGeneric("columnWiseAppend", function(tensor, otherMatrix, foreignBackendOpt=FALSE) {
    return(cbind(tensor, otherMatrix));
})

setGeneric("matrixAddition", function(tensor, otherMatrix) {
    return(tensor + otherMatrix);
})

setGeneric("getNumRows", function(tensor) {
    return(nrow(tensor));
})

setMethod("getNumRows", c("MatrixLibAdapter"), function(tensor) {
    result <- getNumRows(tensor@matrix)
    return(result);
})

setGeneric("getNumCols", function(tensor) {
    return(ncol(tensor));
})

setMethod("getNumCols", c("MatrixLibAdapter"), function(tensor) {
    return(getNumCols(tensor@matrix));
})

setGeneric("transpose", function(tensor, foreignBackendOpt=FALSE) {
    return(t(tensor));
})

setGeneric("diagonal", function(tensor, foreignBackendOpt=FALSE) {
    return(Diagonal(x=as.vector(tensor)));
})

setGeneric("crossProduct", function(tensor, foreignBackendOpt=FALSE) {
    return(crossprod(tensor));
})

setGeneric("elementWiseSqrt", function(tensor, foreignBackendOpt=FALSE) {
    return((tensor)^{1/2});
})


setGeneric("crossProductDuo", function(tensor, otherMatrix, foreignBackendOpt=FALSE) {
    result <- crossprod(tensor, otherMatrix)
    return(result);
})

setGeneric("splice", function(tensor, rowBeg, rowEnd, colBeg, colEnd) {

    rowBeg <- rowBeg + 1
    rowEnd <- rowEnd + 1
    colBeg <- colBeg + 1
    colEnd <- colEnd + 1

    return(tensor[rowBeg:rowEnd, colBeg:colEnd]);
}) 

# Enable concrete R operators to operate on the the MatrixLibAdapter datatype =================

setMethod("^", c("MatrixLibAdapter", "ANY"), function(e1, e2) {
    result <- e1@matrix ^ e2
    return(result)
})

setMethod("^", c("ANY", "MatrixLibAdapter"), function(e1, e2) {
    result <- e1 ^ e2@matrix
    return(result)
})

setMethod("%*%", c("MatrixLibAdapter", "ANY"), function(x, y) {
    result <- x@matrix %*% y
    return(result)
})

setMethod("%*%", c("ANY", "MatrixLibAdapter"), function(x, y) {
    result <- x %*% y@matrix
    return(result)
})

setMethod("*", c("MatrixLibAdapter", "ANY"), function(e1, e2) {
    result <- e1@matrix *  e2
    return(result)
})

setMethod("*", c("ANY", "MatrixLibAdapter"), function(e1, e2) {
    result <- e1 * e2@matrix
    return(result)
})

# Implement helper / minor MatrixLib operators that are mostly used in polyglot execution (R + Python) =

setGeneric("invert", function(e1){
    result <- MatrixLibAdapter(matrix=(1 / e1@matrix))
    return(result)
})

setGeneric("divisionArr", function(e1, e2){
    result <- e2 / e1
    result <- MatrixLibAdapter(matrix=result)
    return(result)
})

setMethod("divisionArr", c("MatrixLibAdapter", "ANY"), function(e1, e2){
    return(divisionArr(e1@matrix, e2))
})

setMethod("divisionArr", c("MatrixLibAdapter", "MatrixLibAdapter"), function(e1, e2){
    return(divisionArr(e1@matrix, e2@matrix))
})
