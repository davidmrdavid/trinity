# Trinity

_A polyglot framework for Factorized ML._

This repo contains code artifacts for [Towards A Polyglot Framework for Factorized ML](https://adalabucsd.github.io/papers/TR_2021_Trinity.pdf). For more information about the Morpheus line of projects, please see the project page [here](https://adalabucsd.github.io/morpheus.html).

## Test it out, the easy way

The easy way to try it Trinity is to use our [Cloudlab](https://www.cloudlab.us/) image. In there, you'll find a copy of all the source code and the project fully built and ready to use.

To use our Cloudlab image, instantiate [this](https://www.cloudlab.us/p/Orion/TrinityVLDB21) profile and then head straight to the "Running the benchmarks" section.

### Running the benchmarks
`cd` into `/mydata/trinity/graal/`.

You should see the following directory structure:

```
root@node:~$ cd /mydata/trinity/
root@node:/mydata/trinity$ ls
deps  fastr  graal  graaljs  graalpython  mx  mygraal  set_enviroment_vars.sh  trinity-benchmarking
root@node:/mydata/trinity$
```

Prepare the enviroment by performing a `source set_enviroment_vars.sh`

Next, `cd` into `/mydata/trinity/graal/trinity/trinity-benchmarking/`.

You should now see the following directory structure:

```
root@node:/mydata/trinity/graal/trinity/trinity-benchmarking$ ls
fastr_benchmarking_suite  graalJS_benchmarking_suite  graalpython_benchmarking_suite
```

These directories contain the benchmarking code for running the `FastR` (for R), `graalJS` (JS) and `graalpython` (Python) experiments in the Trinity paper.

#### Running the JS experiments

`cd` into `/mydata/trinity/graal/trinity/trinity-benchmarking/graalJS_benchmarking_suite`

To run the JS experiments, run `python runEval.py`.

If everything goes well, you should see a trace like the following:

```
root@node:/mydata/trinity/graal/trinity/trinity-benchmarking/graalJS_benchmarking_suite# python runEval.py
RUNNING:  TR= 1 FR= 1
mx --dy /compiler,js/graal-nodejs --cp-sfx ../../mxbuild/dists/jdk1.8/morpheusdsl.jar  --jdk jvmci node --polyglot morpheus.js ./benchparams/synthesized_logRegJS.json logisticRegression 5000 results_javascript trinity T 1 1
Downloading ICU4J from ['https://repo1.maven.org/maven2/com/ibm/icu/icu4j/67.1/icu4j-67.1.jar', 'https://search.maven.org/remotecontent?filepath=com/ibm/icu/icu4j/67.1/icu4j-67.1.jar']
 13106771 bytes (100%)
Beginning benchmarking loop
Create Context for MorpheusDSL
logisticRegression TR= 1 FR= 1
iteration:  0 / 25 | current timeDiff 113.773967771
iteration:  1 / 25 | current timeDiff 74.433360308
iteration:  2 / 25 | current timeDiff 62.463385001
iteration:  3 / 25 | current timeDiff 52.48378036
iteration:  4 / 25 | current timeDiff 50.722579041
iteration:  5 / 25 | current timeDiff 62.261986307
iteration:  6 / 25 | current timeDiff 59.890999968
```

This is running Logistic Regression on a synthetic dataset for 25 iteration, first for a Trinity Normalized Matrix, and then for "the materialized approach".
After running the experiments, you can find the duration of each training loop, in order and in *seconds*, in the `results_javascript` directory.

#### Running the Python (+ with FastR backend) experiments

`cd` into `/mydata/trinity/graal/trinity/trinity-benchmarking/fastr_benchmarking`

To run the Python experiments, run `python runPyEval.py`

If everything goes well, you should see a trace like the following:

```
root@node:/mydata/trinity/graal/trinity/trinity-benchmarking/fastr_benchmarking_suite# vim runPyAlgorithms.py
root@node:/mydata/trinity/graal/trinity/trinity-benchmarking/fastr_benchmarking_suite# python runPyAlgorithms.py
RUNNING:
mx --dynamicimports /compiler,graalpython,fastr --cp-sfx ../../mxbuild/dists/jdk1.8/morpheusdsl.jar:../../../../fastr/mxbuild/dists/jdk1.8/fastr.jar --J @-Xmx220G --jdk jvmci python --polyglot ../graalpython_benchmarking_suite/benchmarkRunner.py --fpath ./benchparams/synthesized_py.json --task linearRegression --numWarmups 10000 --mode trinity --monolang False --outputDir results_python --TR 10 --FR 1
['linearRegression']
in method for ‘getNumRows’ with signature ‘"MatrixLibAdapter"’: no definition for class “MatrixLibAdapter”
in method for ‘getNumCols’ with signature ‘"MatrixLibAdapter"’: no definition for class “MatrixLibAdapter”
Creating a new generic function for ‘transpose’ in the global environment
in method for ‘^’ with signature ‘"MatrixLibAdapter","ANY"’: no definition for class “MatrixLibAdapter”
in method for ‘^’ with signature ‘"ANY","MatrixLibAdapter"’: no definition for class “MatrixLibAdapter”
in method for ‘%*%’ with signature ‘"MatrixLibAdapter","ANY"’: no definition for class “MatrixLibAdapter”
in method for ‘%*%’ with signature ‘"ANY","MatrixLibAdapter"’: no definition for class “MatrixLibAdapter”
in method for ‘*’ with signature ‘"MatrixLibAdapter","ANY"’: no definition for class “MatrixLibAdapter”
in method for ‘*’ with signature ‘"ANY","MatrixLibAdapter"’: no definition for class “MatrixLibAdapter”
in method for ‘divisionArr’ with signature ‘"MatrixLibAdapter","ANY"’: no definition for class “MatrixLibAdapter”
in method for ‘divisionArr’ with signature ‘"MatrixLibAdapter","MatrixLibAdapter"’: no definition for class “MatrixLibAdapter”
Create Context for MorpheusDSL
in method for ‘getNumRows’ with signature ‘"MatrixLibAdapter"’: no definition for class “MatrixLibAdapter”
in method for ‘getNumCols’ with signature ‘"MatrixLibAdapter"’: no definition for class “MatrixLibAdapter”
in method for ‘^’ with signature ‘"MatrixLibAdapter","ANY"’: no definition for class “MatrixLibAdapter”
in method for ‘^’ with signature ‘"ANY","MatrixLibAdapter"’: no definition for class “MatrixLibAdapter”
in method for ‘%*%’ with signature ‘"MatrixLibAdapter","ANY"’: no definition for class “MatrixLibAdapter”
in method for ‘%*%’ with signature ‘"ANY","MatrixLibAdapter"’: no definition for class “MatrixLibAdapter”
in method for ‘*’ with signature ‘"MatrixLibAdapter","ANY"’: no definition for class “MatrixLibAdapter”
in method for ‘*’ with signature ‘"ANY","MatrixLibAdapter"’: no definition for class “MatrixLibAdapter”
in method for ‘divisionArr’ with signature ‘"MatrixLibAdapter","ANY"’: no definition for class “MatrixLibAdapter”
in method for ‘divisionArr’ with signature ‘"MatrixLibAdapter","MatrixLibAdapter"’: no definition for class “MatrixLibAdapter”
Warning message:
In numRowsK * numColsK : NAs produced by integer overflow
__________
Beginning benchmark loop
iteration:  0 /25 | time total:  73550
iteration:  1 /25 | time total:  57386
iteration:  2 /25 | time total:  53405
iteration:  3 /25 | time total:  52116
iteration:  4 /25 | time total:  53315

```

_You can ignore those warnings, they're the result of loading only a portion of the R codebase._

After running the experiments, you can find the duration of each training loop, in order and in *milliseconds*, in the `./graalpython_benchmarking/results_python` directory.

#### Running the R experiments

`cd` into `/mydata/trinity/graal/trinity/trinity-benchmarking/fastr_benchmarking`

To run the R experiments, run `python runREval.py`

If everything goes well, you should see a trace like the following:

```
root@node:/mydata/trinity/graal/trinity/trinity-benchmarking/fastr_benchmarking_suite# python runAlgos.py
mx --dynamicimports fastr,/compiler --cp-sfx ../../mxbuild/dists/jdk1.8/morpheusdsl.jar --J @'-Xmx220G' --jdk jvmci R --polyglot -f benchmarkRunner.r --args -fpath ./benchparams/movie_metadata.json -task linearRegression -outputDir results_R -mode trinity -TR 1 -FR 1
R version 3.6.1 (FastR)
Copyright (c) 2013-19, Oracle and/or its affiliates
Copyright (c) 1995-2018, The R Core Team
Copyright (c) 2018 The R Foundation for Statistical Computing
Copyright (c) 2012-4 Purdue University
Copyright (c) 1997-2002, Makoto Matsumoto and Takuji Nishimura
All rights reserved.

FastR is free software and comes with ABSOLUTELY NO WARRANTY.
You are welcome to redistribute it under certain conditions.
Type 'license()' or 'licence()' for distribution details.


... a large R source-code trace ...

Create Context for MorpheusDSL
[1] "Execution mode: trinity Experiment: linearRegression TR-FR: ( 1 , 1 )"
[1] "Testing performance"
[1] "WARMING: 1/5"
[1] "WARMING: 2/5"
[1] "WARMING: 3/5"

```

After running the experiments, you can find the duration of each training loop, in order and in *milliseconds* in the `results_R` directory.

## Manual Installation (the hard way)

If you wish to build Trinity from scratch, you'll need the following dependencies:
* Ubuntu 16.04.1 LTS (GNU/Linux 4.4.0-176-generic x86_64) for the OS. This isn't strictly required, but this is the OS used to develop the paper.
* OpenJDK with JVMCI release version 20.2-b01: [openjdk1.8.0_252-jvmci-20.2-b01](https://github.com/graalvm/graal-jvmci-8/releases/tag/jvmci-20.2-b01)
* A clone of [mx](https://github.com/graalvm/mx/tree/13a4df76efdd150b8fdb7b492f5e4dadc5c5383f) at commit `13a4df76efdd150b8fdb7b492f5e4dadc5c5383f`.
* An installation of GNU-R, as it helps ease the dependency burden when building [FastR](https://github.com/oracle/fastr/blob/63f568b1b59d453a4dc836224845df6bc5d26991/documentation/dev/building.md).
* For building FastR: A Fortran compiler and libraries. Typically gfortran 4.8 or later
* For building FastR: The pcre package, version 8.38 or later
* For building FastR: The zlib package, version 1.2.8 or later
* For building FastR: The ed, sed, and make utilities (usually available on modern *nix systems)

### Building Instructions

#### Cloning all the repos
1. Create a target directory where the source code will live. From now on, we'll refer to it as the _reproducer_ directory.
3. Clone our `fork` of [GraalVM](https://github.com/davidmrdavid/graal/tree/trinity) in the _reproducer_ directory.
4. Clone this repo inside the `./graal/trinity/` directory.
5. Clone the [mx](https://github.com/graalvm/mx/tree/13a4df76efdd150b8fdb7b492f5e4dadc5c5383f) repo at commit `13a4df76efdd150b8fdb7b492f5e4dadc5c5383f` in the _trinity_ directory.
6. Clone the [fastR](https://github.com/oracle/fastr/tree/369741e3972688cd782a7e57ddb5b23257f07315) directory at commit `369741e3972688cd782a7e57ddb5b23257f07315` in the _reproducer_ directory.
7. Clone the [graalJS](https://github.com/oracle/graaljs/tree/4ff10d928938583a9562189058762165643cc2fb) directory at commit `4ff10d928938583a9562189058762165643cc2fb` in the _reproducer_ directory.
8. Clone the [graalpython](https://github.com/oracle/graalpython/tree/ff3d6a887f54eaff3927049f45963d588ba932b6) directory at commit `ff3d6a887f54eaff3927049f45963d588ba932b6` in the _reproducer_ directory.

#### Preparing the build the repos
8. In the _reproducer_ directory, run `mkdir -p deps/uncompressed/`
9.  Run `cd deps/uncompressed` to get to the directory you just created. There, unpack your OpenJDK installation. You should now have a directory named `openjdk1.8.0_252-jvmci-20.2-b01` inside `deps/uncompressed/`.
10. Head back to the _reproducer_ directory.
11. Copy the `set_enviroment_vars.sh` from this repo, `trinity`, by running `cp set_enviroment_vars.sh .`
12. Run `source set_enviroment_vars.sh`. This will load the JDK and mx into your `PATH`. It will also set your `JAVA_HOME` environment variable.
13. Head to the `graal` directory via `cd graal`.

#### Building the repos
14. In the `graal` directory, you'll need to build several components using `mx`. So head to `graal/compiler`, `graal/sdk`, `graal/sulong/`, `graal/tools`, `graal/truffle` and `graal/vm`, and inside each of them run `mx build`.
15. Head back to the _reproducer_ directory. Then `cd` to `fastr` and run `mx build` in there as well. If this step fails, you might be missing some system dependency.Review [these docs](https://github.com/oracle/fastr/blob/63f568b1b59d453a4dc836224845df6bc5d26991/documentation/dev/building.md) for help.
16. Head back to the _reproducer_ directory. Then `cd` into `graaljs`. There, run `mx build` inside `graal-nodejs` and `graal-js`.

#### Installing libraries

17.  Install `numpy` via `mx --dy graalpython python -m ginstall install numpy`
18.  To install `math.js`, `cd` into `/mydata/trinity/graal/trinity/trinity-benchmarking/graalJS_benchmarking_suite` and run `npm install mathjs`
19.  To install `data.table` and `Matrix` for `R`, `cd` into `/mydata/trinity/graal/trinity/trinity-benchmarking/fastr_benchmarking_suite` and run `mx --dy fastR R`. Then, in the shell, run `install.fastr.packages(c("Matrix", "data.table"))` 