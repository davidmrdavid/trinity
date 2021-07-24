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

# This executes the R algorithm evaluations. To run just a subset of tests,
# simply modify the DATASETS and TASKS lists to contain fewer elements.
# Similarly, you can comment out the execution of the Trinity, MorpheusR,
# and Materialized blocks in the nested for-loop at the end of the file to
# further restrict the tests. The outputs can be found in the `results_algorithms`
# directory.

import sys
import subprocess

DATASETS = [
"movie_metadata.json",
"books_metadata.json",
"lastfm_metadata.json",
"walmart_metadata.json",
"expedia_metadata.json",
"movie_metadata.json",
"yelp_metadata.json",
"flights_metadata.json"
]

TASKS = [
"linearRegression",
"logisticRegression",
"kMeansClustering",
"GNMFClustering"
]

CMD = "mx --dynamicimports fastr,/compiler --cp-sfx ../../mxbuild/dists/jdk1.8/morpheusdsl.jar --J @'-Xmx220G' --jdk jvmci R --polyglot -f benchmarkRunner.r --args -fpath %s -task %s -outputDir results_R -mode %s -TR %s -FR %s"

for dataset in DATASETS:
    for task in TASKS:

        # Trinity evaluation
        COMMAND = CMD % ("./benchparams/"+dataset, task, "trinity", "1", "1")
        print(COMMAND)
        pipe = subprocess.Popen(COMMAND, shell=True)
        pipe.wait()
        
        # MorpheusR evaluation
        COMMAND = CMD % ("./benchparams/"+dataset, task, "morpheusR", "1", "1")
        print(COMMAND)
        pipe = subprocess.Popen(COMMAND, shell=True)
        pipe.wait()
        
        # Materialized evaluation
        COMMAND = CMD % ("./benchparams/"+dataset, task, "materialized", "1", "1")
        print(COMMAND)
        pipe = subprocess.Popen(COMMAND, shell=True)
        pipe.wait()
