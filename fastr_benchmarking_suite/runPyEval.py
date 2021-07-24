import subprocess
import sys

CMD = "mx --dynamicimports /compiler,graalpython,fastr --cp-sfx ../../mxbuild/dists/jdk1.8/morpheusdsl.jar:../../../../fastr/mxbuild/dists/jdk1.8/fastr.jar --J @-Xmx220G --jdk jvmci python --polyglot ../graalpython_benchmarking_suite/benchmarkRunner.py --fpath ./benchparams/synthesized_py.json --task %s --numWarmups 10000 --mode %s --monolang False --outputDir results_python --TR %s --FR %s"

MODES = [
"trinity",
"materialized"
]

TASK = "linearRegression"

FR = [
"1",
"2",
"3",
"4",
"5"
]

TR = "10" 

for mode in MODES:
  for fr in FR:
    print("RUNNING: ")
    COMMAND = CMD % (TASK, mode, TR, fr)
    print(COMMAND)
    pipe = subprocess.Popen(COMMAND, shell=True)
    pipe.wait()
