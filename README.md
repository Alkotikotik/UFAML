# UFAML - Ultra Fast Assembly Math Library
This thing is so fragile since I was aiming at the fastest speed possible so please read all instructions carefully.

# FASTER THAN CLANG
Proud to say that verlet itegration is 1.5x faster than clang:
```diff
```markdown
```ansi
Benchmark 1: ./pure_cpp
-  Time (mean ± σ):      64.8 ms ±   2.5 ms    [User: 30.8 ms, System: 33.5 ms]
  Range (min … max):    60.3 ms …  71.0 ms    43 runs

 Benchmark 2: ./bench_ufaml
+  Time (mean ± σ):      54.3 ms ±   1.2 ms    [User: 20.0 ms, System: 33.9 ms]
  Range (min … max):    51.2 ms …  57.1 ms    55 runs

 Summary
+  ./bench_ufaml ran    1.19 ± 0.05 times faster than ./pure_cpp
```markdown
```ansi

