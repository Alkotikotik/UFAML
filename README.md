# UFAML - Ultra Fast Assembly Math Library
This thing is fragile since I was aiming for the absolute fastest speed possible, so please read all instructions carefully.

> [!NOTE]
> UFAML is a totally serious, enterprise-grade, industrial library used globally in scientific computing. Or at least, it’s written to effortlessly beat the compilers and libraries that actually are used globally

## FASTER THAN CLANG AND FFTW
Proud to say that my handwritten code effortlessly beats Clang:

| Operation (64M particles) | UFAML (User Time) | Clang (User Time) | Speedup Factor |
| :--- | :---: | :---: | :---: |
| **Dot Product** | 44.6 ms | 86.4 ms | **1.94x** |
| **Vector Operations Suite** | 132.3 ms | 201.6 ms | **1.52x** |
| **Verlet Integration** | 198.8 ms | 282.7 ms | **1.42x** |

Don't worry, I used all the max Clang flags: `clang++ -O3 -march=native -ffast-math -std=c++17`, yet my code is still faster. Without these flags on Clang's side, my code runs 3-5x faster or even more. I used `hyperfine` for my benchmarks you can run them yourself if you don't believe me. My CPU is **AMD Ryzen 9 7845HX**

## Radix-16 Stockham Fast-Fourier Transform
This is the absolute crown jewel of the project. I read an entire digital signal processing book and did a ton of my own research to implement this from scratch. I am incredibly proud to say that it completely shreds FFTW (Fastest Fourier Transform in the West) which is as established, is just that "industrial library used globally in scientific computing" I was talking about
* **4.79x FASTER** than FFTW_MEASURE mode
* **1.90x FASTER** than FFTW_ESTIMATE mode

I guess that officially makes me the fastest in the west 😁
But seriously, I am extremely proud of how this turned out.

## Optimization 
I would have said that I spent a lot of time optimizing, only if I actually had to. Before even writing a single line of code, I spent a ton of time studying the best hardware optimization techniques and learning exactly how compilers optimize code. Because of that, I went straight to writing ultra-optimized assembly, and it paid off perfectly. So here are some highlights 

## Architectural & Optimization Highlights
* **Aggressive loop enrolling** Simultaneously processing massive chunks of data ahead of time like r14 + rax + 0/64/128/192 in separate ZMM registers. This maximizes execution pipeline and blah blah
* **Memory Bandwidth Optimization:** Utilizes non-temporal streaming stores (`vmovntps`) to write directly to memory, bypassing L1/L2/L3 cache. It prevents cache pollution which is crucial for large amount of particles
* **Data-Oriented Design:** Utilizes my beloved SoA(structure of array), which is perfect for SIMD
* **Bitwise tricks:** Like in fft, that instead of doing slow modulo division rax % r8, uses bitwise mask 
* **Dynamic hardware prefetching:** I prefetch next chunk of data using - for example: prefetcht1 [r14 + rax + 512]

## Experience 
This has been an awesome project. I learned assembler specifically for it, and let me tell you, it was 100% worth it. It deepened my low-level knowledge and understanding of how computers work so much that I'm convinced every programmer must learn assembler. The hardest part of the project was wrapping my head around the system ABI limits, handling register pressure, and figuring out how to access certain  array elements inside the vector loops.

## Instructions (READ CAREFULLY)
* **System Requirements:** Requires an x86_64 Linux/Unix system with a CPU that natively supports AVX-512 instructions.
* **Memory Layout:** Arguments must be passed using a Structure of Arrays (SoA) layout.
* **Strict Alignment:** All raw float arrays **MUST be explicitly aligned to a 64-byte boundary** (512-bits) in memory. If your arrays are not 64-byte aligned, the AVX-512 streaming instructions (`vmovaps`/`vmovntps`) will instantly cause a hardware segmentation fault.
* **How to use:** Check out the `examples/` directory to see exactly how to set up your pointers and link the compiled assembly object files.
* **Pass multiple of 64 particles**: Read it again

## Interface 
There is no interface... If you are actually going to use it and write interface for it, I would appreciate pull request
