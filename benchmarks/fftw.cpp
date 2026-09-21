#include <cmath>
#include <cstdlib>
#include <cstring>
#include <fftw3.h>
#include <iostream>
#include <x86intrin.h>

// Usage: fftw [estimate|measure|patient] [iterations] [wisdom_file]
// With wisdom_file, a saved plan is reused (and saved after planning), which
// removes planning time and run-to-run plan variance from the measurement.
// Run with iterations=0 to measure setup cost alone (allocation, init, planning),
// so hyperfine results can be turned into per-transform time.
int main(int argc, char **argv) {
    // Flush to zero and denormals to zero (matching your setup)
    _mm_setcsr(_mm_getcsr() | 0x8040);

    const int N = 65536;
    const char *mode = argc > 1 ? argv[1] : "estimate";
    const int BENCHMARK_ITERATIONS = argc > 2 ? std::atoi(argv[2]) : 1000;
    const char *wisdom_file = argc > 3 ? argv[3] : nullptr;

    unsigned flags = FFTW_ESTIMATE;
    if (!std::strcmp(mode, "measure"))
        flags = FFTW_MEASURE;
    else if (!std::strcmp(mode, "patient"))
        flags = FFTW_PATIENT;

    // FFTW's aligned allocation ensures max SIMD throughput
    fftw_complex *input_data = (fftw_complex *)fftw_malloc(sizeof(fftw_complex) * N);
    fftw_complex *output_data = (fftw_complex *)fftw_malloc(sizeof(fftw_complex) * N);

    // Plan before filling input: MEASURE/PATIENT overwrite the arrays while planning
    if (wisdom_file)
        fftw_import_wisdom_from_filename(wisdom_file);
    fftw_plan plan = fftw_plan_dft_1d(N, input_data, output_data, FFTW_FORWARD, flags);
    if (wisdom_file)
        fftw_export_wisdom_to_filename(wisdom_file);

    // Initialize with the exact same signal
    for (int i = 0; i < N; ++i) {
        input_data[i][0] =
            std::sin(2.0 * M_PI * i / 128.0) + 0.5 * std::cos(2.0 * M_PI * i / 32.0); // Real
        input_data[i][1] = 0.0;                                                       // Imag
    }

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
