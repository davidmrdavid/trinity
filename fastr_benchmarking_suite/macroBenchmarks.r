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

# This file exports algorithm tests, i.e our macrobenchmarks,
# for use in our test runner.

library(matrixStats)
source("morpheusR.r")

doLogisticRegression <- function(Data, max_iter, winit, gamma0, Target) {
    w = winit;
    
    for( k in 1:max_iter)
    {
        
        w =  gamma0 * (t(Data) %*%  (Target/(1+(2.78 ^ (Data%*%w))))); 
        
    }
    return(list(w))
}

doLinearRegression <- function(Data, Max_Iter, winit, gamma0, Target) {
    w = winit;
    
    for( k in 1:Max_Iter )
    {              
        d = t(Data);        
        d2 =Data %*% w; 
        d2 = d2 - Target;
        d = d %*% d2;
        d = gamma0 * d
        w = w - d
       
    }
    return(list(w));
}

doKMeansClustering <- function(Data, Max_Iter, Center_Number, k_center, nS) {

    All1 = matrix(1, nS, 1);
    All1_k = matrix(1,1,Center_Number);
    All1_C = t(matrix(1,1,nrow(k_center)));	
    T2 = rowSums(Data^{2}) %*% All1_k;
    
    T22 = Data * 2;
    
    for( k in 1: Max_Iter )
    {
        
        tmp = T22 %*% k_center;
        
        Dist = T2 - as.matrix(tmp);
        
        Dist = Dist +  All1 %*% colSums(k_center ^2);
     
        YA = (Matrix(Dist == (rowMins((Dist)) %*% All1_k),sparse=TRUE))+0;
        
        arg1 <- t(Data) %*% YA;
        
        arg2 <- All1_C %*% colSums(YA);
        
        k_center = as.matrix(  ( t(Data) %*% YA ) / ( (All1_C) %*% colSums(YA) )  );
        
    }
    return(list(k_center ,YA));
}

doGNMFClustering <- function(X, Max_Iter, winit, hinit){
  
  w <- winit;
  h <- hinit;
  
  
  for(k in 1:Max_Iter) { 
    
    numerator <- (t(w) %*% X);
    
    denominator <- crossprod(w) %*% h;
    
    arg <- numerator / denominator;
    
    h <- (h * arg);

    tmp1 = X %*% t(as.matrix(h));

    tmp2 = h %*% t(h);

    tmp2 = w %*% tmp2;

    w <- w * tmp1;

    w <- w / tmp2;  

  }
  return(list(h, w))
}


