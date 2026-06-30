#include <cmath>
#include <fftw3.h>
#include <iostream>
#include <x86intrin.h>

int main() {
    // Flush to zero and denormals to zero (matching your setup)
    _mm_setcsr(_mm_getcsr() | 0x8040);

    const int N = 65536;
    const int BENCHMARK_ITERATIONS = 1000;

    // FFTW's aligned allocation ensures max SIMD throughput
    fftw_complex *input_data = (fftw_complex *)fftw_malloc(sizeof(fftw_complex) * N);
    fftw_complex *output_data = (fftw_complex *)fftw_malloc(sizeof(fftw_complex) * N);

    // Initialize with the exact same signal
    for (int i = 0; i < N; ++i) {
        input_data[i][0] =
            std::sin(2.0 * M_PI * i / 128.0) + 0.5 * std::cos(2.0 * M_PI * i / 32.0); // Real
        input_data[i][1] = 0.0;                                                       // Imag
    }

    // Create the plan. FFTW_ESTIMATE prevents planning overhead from skewing hyperfine.
    fftw_plan plan = fftw_plan_dft_1d(N, input_data, output_data, FFTW_FORWARD, FFTW_ESTIMATE);

    // Core execution loop
    for (int iter = 0; iter < BENCHMARK_ITERATIONS; ++iter) {
        fftw_execute(plan);

        // Prevent the compiler from optimizing away the loop calculations
        asm volatile("" : "+m"(output_data[0]));
    }

    // Cleanup
    fftw_destroy_plan(plan);
    fftw_free(input_data);
    fftw_free(output_data);

    return 0;
}
