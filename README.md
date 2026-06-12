# UFAML - Ultra Fast Assembly Math Library
This thing is so fragile since I was aiming at the fastest speed possible so please read all instructions carefully.

# FASTER THAN CLANG
hyperfine --warmup 3 ./pure_cpp ./bench_ufaml
Benchmark 1: ./pure_cpp
  Time (mean ± σ):      67.4 ms ±   2.4 ms    [User: 31.6 ms, System: 35.4 ms]
  Range (min … max):    63.1 ms …  72.8 ms    40 runs

Benchmark 2: ./bench_ufaml
  Time (mean ± σ):      56.2 ms ±   1.9 ms    [User: 21.1 ms, System: 34.7 ms]
  Range (min … max):    51.3 ms …  59.7 ms    50 runs

Summary
  ./bench_ufaml ran
    1.20 ± 0.06 times faster than ./pure_cpp 
