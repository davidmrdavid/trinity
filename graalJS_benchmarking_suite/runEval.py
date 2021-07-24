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

# This executes the JS evaluations. To run just a subset of the tests,
# modify the MODES and FR parameter arrays. We recommend running only
# a subset of experiments at a time, for speed and memory usage.

import subprocess
import sys

TR = 1 # 10
FR = [
1,
2,
3,
4,
5
]

MODES = [
"trinity",
"materialized"
]


CMD = "mx --dy /compiler,js/graal-nodejs --cp-sfx ../../mxbuild/dists/jdk1.8/morpheusdsl.jar  --jdk jvmci node --polyglot morpheus.js ./benchparams/synthesized_logRegJS.json logisticRegression 5000 results_javascript %s T %s %s" 

for fr in FR:
    for m in MODES:
        print("RUNNING: ", "TR=",TR, "FR=",fr)
        COMMAND = CMD % (m, TR, fr)
        print(COMMAND)
        pipe = subprocess.Popen(COMMAND, shell=True)
        pipe.wait()
