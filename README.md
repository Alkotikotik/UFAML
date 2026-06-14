# UFAML - Ultra Fast Assembly Math Library
This thing is so fragile since I was aiming at the fastest speed possible so please read all instructions carefully.

## FASTER THAN CLANG
Proud to say that my code is faster than clang itself:
| Operation(n particles) | UFAML (User Time) | Clang (User Time) | Speedup Factor |
| :--- | :---: | :---: | :---: |
| **Dot Product (64M)** | 52.6 ms | 89.2 ms | **1.85x** |
| **Verlet Integration(64M)** | 207.4ms | 290.3ms | **1.43x** |
| **Vector Operation(64M)** | 107.3ms | 131.2ms | **1.22x** |

Don't worry I have used all of the clang flags: clang++ -O3 -march=native -ffast-math -std=c++17, yet im still faster
Without them my code is like 3-5 times faster or even faster

## Optimization 
I would have said that I spend a lot of time optimizing, only if I would have, because even before starting coding I studied best optimization techniques, and studied how compilers optimize code, so I went straight to writing hyper optimized code, and it worked out.
