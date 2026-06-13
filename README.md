# UFAML - Ultra Fast Assembly Math Library
This thing is so fragile since I was aiming at the fastest speed possible so please read all instructions carefully.

## FASTER THAN CLANG
Proud to say that my code is faster than clang itself:
| Operation(n particles) | UFAML (User Time) | Clang (User Time) | Speedup Factor |
| :--- | :---: | :---: | :---: |
| **Dot Product (64M)** | 52.6 ms | 89.2 ms | **1.72x** |
| **Verlet Integration(64M)** | 207.4 | 290.3 | **1.41x** |

## Optimization 
I would have said that I spend a lot of time optimizing, only if I would have, because even before starting coding I studied best optimization techniques, and studied how compilers optimize code, so I went straight to writing hyper optimized code, and it worked out.
