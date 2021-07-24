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

# This file exports scalar-operator tests, i.e our microbenchmarks,
# for use in our test runner.

doScalarAddition <- function(testMatrix) {
    result <- testMatrix + 42
    return(result)
}

doScalarMultiplication <- function(testMatrix) {
    result <- testMatrix * 42
    return(result)
}

doElementWiseSum <- function(testMatrix) {
    result <- sum(testMatrix)
    return(result)
}

doRowWiseSum <- function(testMatrix) {
    result <- rowSums(testMatrix)
    return(result)
}

doColumnWiseSum <- function(testMatrix) {
    result <- colSums(testMatrix)
    return(result)
}

doLeftMatrixMultiplication <- function(testMatrix, otherMatrix) {
    result <- testMatrix %*% otherMatrix
    return(result)
}

doTransLeftMatrixMultiplication <- function(testMatrix, otherMatrix) {
    result <- t(testMatrix) %*% otherMatrix
    return(result)
}

doRightMatrixMultiplication <- function(testMatrix, otherMatrix) {
  result <- otherMatrix %*% testMatrix
  return(result)
}

doCrossProduct <- function(testMatrix) {
  result <- crossprod(testMatrix);
  return(result);
}
