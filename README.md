# UFAML - Ultra Fast Assembly Math Library
This thing is fragile since I was aiming for the absolute fastest speed possible, so refer to instructions.

Code is in the `UFAML/` directory.

## FASTER THAN CLANG AND FFTW
Proud to say that my handwritten code effortlessly beats Clang:

| Operation (64M particles) | UFAML (User Time) | Clang (User Time) | Speedup Factor |
| :--- | :---: | :---: | :---: |
| **Dot Product** | 44.6 ms | 86.4 ms | **1.94x** |
| **Vector Operations Suite** | 132.3 ms | 201.6 ms | **1.52x** |
| **Verlet Integration** | 198.8 ms | 282.7 ms | **1.42x** |

Don't worry, I used all the max Clang flags: `clang++ -O3 -march=native -ffast-math -std=c++17`, yet my code is still faster. Without these flags on Clang's side, my code runs 3-5x faster or even more. I used `hyperfine` for my benchmarks, so you can run them yourself if you don't believe me. My CPU is an **AMD Ryzen 9 7845HX**.

## Radix-16 Stockham Fast Fourier Transform
This is the absolute crown jewel of the project. I read an entire digital signal processing book and did a ton of my own research to implement this from scratch. I am incredibly proud to say that it goes toe to toe with FFTW (it literally stands for Fastest Fourier Transform in the West), which is that established "industrial library used globally in scientific computing" I was talking about.

| FFTW planner mode | FFTW (per FFT) | UFAML (per FFT) | UFAML vs FFTW | FFTW planning time |
| :--- | :---: | :---: | :---: | :---: |
| **FFTW_ESTIMATE** | 406.7 µs | 219.0 µs | **1.86x faster** | ~0 |
| **FFTW_MEASURE** | 212.6 µs | 219.0 µs | 1.03x slower | ~1 s |
| **FFTW_PATIENT** | 189.3 µs | 219.0 µs | 1.16x slower | ~16-21 s |

>[!Note]
> FFTW_MEASURE needs about 1 s of planning and FFTW_PATIENT about 16-21 s before the first transform, while UFAML's setup (building the twiddle table) takes about 3 ms. I'm not saying anything, but you can make your own evaluations.

So I guess that officially makes me the fastest in the west 😁 because in a duel you don't have 20 s to take out your gun.
But seriously, I am extremely proud of how this turned out.

### How was FFTs measured
* **Data:** 65,536-point forward complex FFT in double precision (1 MB of input). The signal is `sin(2πi/128) + 0.5·cos(2πi/32)` (imaginary part 0).
* **Layouts:** UFAML uses split real/imaginary arrays (SoA), 64-byte aligned, out-of-place. FFTW uses its interleaved `fftw_complex` arrays from `fftw_malloc`, out-of-place.
* **Timing:** `hyperfine` with 3 warmup runs and 15 timed runs of 10,000 transforms each. Setup is excluded by also timing a run with 0 transforms and subtracting it.
* **FFTW planning:** MEASURE and PATIENT plans are loaded from saved wisdom, so the table shows pure transform time. Planning time is listed separately.
* **Correctness:** UFAML's output matches FFTW to a max error of ~4e-12 on the test signal and ~2e-13 on random complex input.

## Optimization 
I would have said that I spent a lot of time optimizing, if only I had actually had to. Before even writing a single line of code, I spent a ton of time studying the best hardware optimization techniques and learning exactly how compilers optimize code. Because of that, I went straight to writing ultra-optimized assembly, and it paid off perfectly. So here are some highlights:

## Architectural & Optimization Highlights
* **Aggressive loop unrolling:** Simultaneously processing massive chunks of data ahead of time like (`r14 + rax + 0/64/128/192`) in separate (`ZMM`) registers. This maximizes execution pipeline usage and blah blah
* **Memory Bandwidth Optimization:** Utilizes non-temporal streaming stores (`vmovntps`) to write directly to memory, bypassing the (`L1/L2/L3`) caches. It prevents cache pollution, which is crucial for large numbers of particles
* **Data-Oriented Design:** Utilizes my beloved SoA (structure of arrays), which is perfect for SIMD
* **Bitwise tricks:** Like in the FFT, where instead of doing slow modulo division (`rax % r8`), it uses a bitwise mask
* **Dynamic hardware prefetching:** I prefetch the next chunk of data, for example: (`prefetcht1 [r14 + rax + 512]`)

## Experience 
This has been an awesome project. I learned assembler specifically for it, and let me tell you, it was 100% worth it. It deepened my low-level knowledge and understanding of how computers work so much that I'm convinced every programmer must learn assembler. It was also super fun. The hardest part of the project, aside from the FFT, was wrapping my head around the system ABI limits, handling register pressure, and figuring out how to access certain array elements inside the vector loops.

## Instructions (READ CAREFULLY)
* **System Requirements:** Requires an x86_64 Linux/Unix system with a CPU that natively supports AVX-512 instructions.
* **Memory Layout:** Arguments must be passed using a Structure of Arrays (SoA) layout.
* **Strict Alignment:** All raw float arrays **MUST be explicitly aligned to a 64-byte boundary** (512-bits) in memory. If your arrays are not 64-byte aligned, the AVX-512 streaming instructions (`vmovaps`/`vmovntps`) will instantly cause a hardware segmentation fault.
* **How to use:** Check out the `examples/` directory to see exactly how to set up your pointers and link the compiled assembly object files.
* **Pass a multiple of 64 particles:** Read it again

## Interface 
There is no interface... If you are actually going to use it and write an interface for it, I would appreciate a pull request
