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

# This file exports our the main driver for the Python experiments, and its helper
# utility functions.

from morpheus import morpheus
import numpy as np
import statistics
import argparse
import json
import argparse
import timeit
import statistics
from linReg import NormalizedLinearRegression
import polyglot
from time import time
import csv
import os
import gc

# Test runners ===========================================================

def do_scalar_addition(x):
    return x + 42

def do_scalar_multiplication(x):
    return x * 42

def do_left_matrix_multiplication(x, lmm_arg):
    return lmm_arg * x

def do_right_matrix_multiplication(x, rmm_arg):
    return x * rmm_arg

def do_row_wise_sum(x):
    return np.sum(x, axis=0)

def do_column_wise_sum(x):
    return np.sum(x, axis=1)

def do_element_wise_sum(x):
    return np.sum(x)

def do_linear_regression(x, max_iter, winit, gamma, target):
    m1 = NormalizedLinearRegression()
    return m1.fit(x, target, winit)


# Obtains a normalized matrix, its corresponding materialized matrix, and target vector from R
def gen_matrices_poly(num_rows_R, num_cols_S, tup_ratio, feat_ratio, mode):
    # Computing matrix dims
    num_rows_S = num_rows_R * tup_ratio
    num_cols_R = num_cols_S * feat_ratio
    num_rows_K = num_rows_S
    num_cols_K = num_rows_R

    #num of elements per matrix
    area_S = num_rows_S * num_cols_S
    area_R = num_rows_R * num_cols_R
    area_K = num_rows_K * num_cols_K

    func = polyglot.eval(language="R", string="source('benchUtils.r'); function(x,y,z,w){ genMatricesForPy(x,y,z,w); }")
    res = func(num_rows_R, num_cols_S, tup_ratio, feat_ratio)

    Sarg, Ksarg, Rsarg, matMatrixForeign, target, avatarArg = res
    nm = morpheus.NormalizedMatrix(S=Sarg, Ks=Ksarg, Rs=Rsarg, foreign_backend=True, avatar=avatarArg) 
    mat = morpheus.NormalizedMatrix(mat=matMatrixForeign, avatar=avatarArg)
    target = morpheus.NormalizedMatrix(mat=target, avatar=avatarArg)
    data = nm if mode == "trinity" else mat
    n_mat, d_mat = (num_rows_S, num_cols_R + num_cols_S)
    matrices = {
        "data": data,
        "matMatrix": mat,
        "target": target,
        "nMat": n_mat,
        "dMat": d_mat,
        "avatar" : avatarArg
    }
    return matrices

# Captures the runtime of some test
def benchmark_it(action, fname):
    print("Beginning benchmark loop")
    times = []
    with open(fname, 'a') as f:
        for i in range(25):
            gc.collect()
            timeStart = int(round(time() * 1000)) 
            action()
            timeEnd = int(round(time() * 1000))
            timeTotal = timeEnd - timeStart 
            times.append(timeTotal)
            f.write(str(timeTotal) + "\n")
            f.flush()
            os.fsync(f.fileno())
            print("iteration: ", i, "/25 | time total: ", timeTotal)
    return times

# Gets an anonymous function to run the chosen test. For the paper, we focused exclusively on LinearRegression
# but other algorithms are technically supported as well. The matrix representation is drawn from R, for stability
def get_tasks(params, n_mat, d_mat, T, target, tasks, is_monolang):

    lmm_num_rows = d_mat
    lmm_num_cols = 2
    rmm_num_rows = 2
    rmm_num_cols = n_mat
    lmm_arg = lmm_num_rows * lmm_num_cols
    rmm_arg = rmm_num_rows * rmm_num_cols
    
    log_reg_max_iter = 20
    log_reg_gamma = 0.000001

    n_S = n_mat
    center_num = 10
    end = d_mat
    
    if is_monolang:
        raise NotImplementedError

    else:
        func = polyglot.eval(language="R", string="source('benchUtils.r'); function(x,y){ genRanMatrixForPy(x,y); }")
        log_reg_winit = morpheus.NormalizedMatrix(mat=func(d_mat, 1), avatar=T.avatar)

    all_tasks = [
        ("linearRegression",
           lambda x: do_linear_regression(x,
               log_reg_max_iter, log_reg_winit, log_reg_gamma, target))
    ]

    chosen_tasks = []
    for name, func in all_tasks:
        if name in tasks:
             chosen_tasks.append((name, func))

    return chosen_tasks

# The main experiment driver, mostly parses its cli arguments and executes the tests using helper functions
def main():

    # parse params
    parser = argparse.ArgumentParser(description='Add some integers.')
    parser.add_argument('--fpath', metavar='fpath', type=str, help='benchparams')
    parser.add_argument('--task', metavar='task', type=str, help='task to run')
    parser.add_argument('--numWarmups', metavar='numWarmups', type=int, help='number of warmups')
    parser.add_argument('--outputDir', metavar='outputDir', type=str, help='what is the output directory')
    parser.add_argument('--mode', metavar='mode', type=str, help='mode of execution')
    parser.add_argument('--monolang', metavar='monolang', type=bool, help='monolang')
    parser.add_argument('--TR', metavar='TR', type=int, help='monolang')
    parser.add_argument('--FR', metavar='FR', type=int, help='monolang')
    args = parser.parse_args()

    action_param = args.task
    dataset_meta = None
    with open(args.fpath) as f:
        dataset_meta = json.load(f)

    algorithm_tasks = ["linearRegression"]
    microbench_tasks = [
        "scalarAddition", "scalarMultiplication",
        "leftMatrixMultiplication", "rightMatrixMultiplication",
        "rowWiseSum", "columnWiseSum", "elementWiseSum"
    ]
    mode = args.mode
    is_monolang = False

    if not(os.path.exists(args.outputDir)):
        os.makedirs(args.outputDir)
    
    # Task selection
    tasks = []
    if action_param == "all":
        tasks = microbench_tasks + algorithm_tasks
    elif action_param == "micro":
        tasks = microbench_tasks
    elif action_param == "algorithm":
        tasks = algorithm_tasks
    else:
        tasks = [action_param]
    print(tasks)
    
    # Benchmarking loop
    TRs = [1]
    FRs = [1]

    is_data_synthetic = dataset_meta["name"] == "synthesized"
    if is_data_synthetic:
        TRs = dataset_meta["TRs"]
        FRs = dataset_meta["FRs"]

    TRs = [args.TR]
    FRs = [args.FR]
    for TR in TRs:
        for FR in FRs:
            if(is_data_synthetic and is_monolang):
                raise NotImplementedError
            elif is_data_synthetic:
                matrices = gen_matrices_poly(dataset_meta["nR"], dataset_meta["dS"], TR, FR, mode)
            else:
               raise NotImplementedError

            task_pairs = get_tasks(args, matrices["nMat"], matrices["dMat"], matrices["matMatrix"], matrices["target"], tasks, is_monolang)
            start_time = time()
            print("__________")
            for name, action in task_pairs:
                fname = args.outputDir + "/"  + name + "_" + dataset_meta["outputMeta"] + "_" + "TR=" + str(TR) +  "_FR=" + str(FR) + "_"  + mode + ".txt"
                times = benchmark_it(lambda : action(matrices["data"]), fname)
main()

# Generate input matrices in NumPy, unused due to stability issues ====
def gen_matrices(mode, num_rows_R, num_cols_S, tup_ratio, feat_ratio):

    # Computing matrix dims
    num_rows_S = num_rows_R * tup_ratio
    num_cols_R = num_cols_S * feat_ratio
    num_rows_K = num_rows_S
    num_cols_K = num_rows_R

    #num of elements per matrix
    area_S = num_rows_S * num_cols_S
    area_R = num_rows_R * num_cols_R
    area_K = num_rows_K * num_cols_K

    #TODO: need sparse K!
    S = np.matrix(np.random.rand(num_rows_S, num_cols_S))
    K = np.matrix(np.random.rand(num_rows_K, num_cols_K))
    R = np.matrix(np.random.rand(num_rows_R, num_cols_R))


    # generate materialized matrix
    KR = np.matmul(K, R)
    materialized_matrix = np.hstack((S, KR))

    data = materialized_matrix
    if mode == "trinity":
        # generate normalized matrix
        data = morpheus.NormalizedMatrix(S, [K], [R])

    # get Y, package them, return
    n_mat, d_mat = materialized_matrix.shape
    Y = np.matrix(np.random.rand(n_mat, 1) > 0.5) 

    matrices = {
        "data": data,
        "matMatrix": materialized_matrix,
        "target": target,
        "nMat": n_mat,
        "dMat": d_mat
    }
     
    return matrices


