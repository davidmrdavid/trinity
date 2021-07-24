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

# This executes the R operator evaluations. To run just a subset of tests,
# simply modify the DATASETS and TASKS lists to contain fewer elements.
# Similarly, you can comment out the execution of the Trinity, MorpheusR,
# and Materialized blocks in the nested for-loop at the end of the file to
# further restrict the tests. The outputs can be found in the `results_operators`
# directory.

import sys
import subprocess

CMD = "mx --dynamicimports /compiler,fastr,/tools --cp-sfx ../../mxbuild/dists/jdk1.8/morpheusdsl.jar --jdk jvmci R  --J @'-Xmx220G -da -dsa -agentlib:hprof=cpu=samples' --R.PrintErrorStacktracesToFile=true  --polyglot -f benchmarkRunner.r --args -fpath %s -task %s -outputDir results_R -mode %s -TR %d -FR %d"

DATASETS = ["synthesized.json"]
TASKS = [
"scalarMultiplication",
"leftMatrixMultiplication",
"rightMatrixMultiplication",
"rowWiseSum",
"columnWiseSum",
"elementWiseSum",
"crossProduct"
]

for d in DATASETS:

  d = "./benchparams/" + d
  for m in TASKS:
    for TR in range(1,16):
      for FR in range(1,6):

        print("RUNNING: ", "TR=",TR, "FR=",FR)
        COMMAND = CMD % (d, m, "trinity", TR, FR)
        pipe = subprocess.Popen(COMMAND, shell=True)
        pipe.wait()

        print("RUNNING: ", "TR=",TR, "FR=",FR)
        COMMAND = CMD % (d, m, "morpheusR", TR, FR)
        pipe = subprocess.Popen(COMMAND, shell=True)
        pipe.wait()

        print("RUNNING: ", "TR=",TR, "FR=",FR)
        COMMAND = CMD % (d, m, "materialized", TR, FR)
        pipe = subprocess.Popen(COMMAND, shell=True)
        pipe.wait()
