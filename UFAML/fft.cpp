#include <cmath>
#include <complex>
#include <iostream>
#include <vector>
#include <x86intrin.h>

typedef std::complex<double> complex_t;

struct cmplx {
    double *real;
    double *imag;
};

extern "C" void fft_kernel(const cmplx *src, const cmplx *dst, const cmplx *twiddles, int N,
                           int stride);

double *allocate_aligned_doubles(size_t count) {
    return ::new (std::align_val_t{64}) double[count];
}

void free_aligned_doubles(double *ptr) { ::operator delete[](ptr, std::align_val_t{64}); }

// Pre-compute twiddles
void pre_compute_twiddles(int N, double *twid_real, double *twid_imag) {
    int idx = 0;
    for (int stride = 1; stride < N; stride *= 16) {
        int num_blocks = N / (stride * 16);

        for (int b = 0; b < num_blocks; ++b) {
            for (int i = 0; i < stride; i += 8) {
                for (int k = 1; k <= 15; ++k) {
                    for (int v = 0; v < 8; ++v) {
                        int j = b * stride + (i + v);
                        double theta = (2.0 * M_PI * j * k) / (stride * 16);

                        twid_real[idx] = std::cos(theta);
                        twid_imag[idx] = -std::sin(theta);
                        idx++;
                    }
                }
            }
        }
    }
}

void fft_source(int N, const cmplx *src, const cmplx *dst, const cmplx *twid_desc) {
    cmplx src_desc = *src;
    cmplx dst_desc = *dst;
    cmplx current_twid = *twid_desc;

    for (int stride = 1; stride < N; stride *= 16) {
        fft_kernel(&src_desc, &dst_desc, &current_twid, N, stride);

        int twiddles_used_this_pass = 15 * (N / 16);
        current_twid.real += twiddles_used_this_pass;
        current_twid.imag += twiddles_used_this_pass;

        // Ping-pong!!!
        std::swap(src_desc.real, dst_desc.real);
        std::swap(src_desc.imag, dst_desc.imag);
    }
}

int main() {
    _mm_setcsr(_mm_getcsr() | 0x8040);

    const int N = 65536;
    const int BENCHMARK_ITERATIONS = 1000;

    cmplx input_data;
    input_data.real = allocate_aligned_doubles(N);
    input_data.imag = allocate_aligned_doubles(N);

    cmplx output_data;
    output_data.real = allocate_aligned_doubles(N);
    output_data.imag = allocate_aligned_doubles(N);

    for (int i = 0; i < N; ++i) {
        input_data.real[i] =
            std::sin(2.0 * M_PI * i / 128.0) + 0.5 * std::cos(2.0 * M_PI * i / 32.0);
        input_data.imag[i] = 0.0;
    }

    int total_twiddles_alloc = 15 * N * 2;
    double *twid_real_raw = allocate_aligned_doubles(total_twiddles_alloc);
    double *twid_imag_raw = allocate_aligned_doubles(total_twiddles_alloc);
    pre_compute_twiddles(N, twid_real_raw, twid_imag_raw);
    cmplx twid_desc = {twid_real_raw, twid_imag_raw};

    for (int iter = 0; iter < BENCHMARK_ITERATIONS; ++iter) {
        fft_source(N, &input_data, &output_data, &twid_desc);
        asm volatile("" : "+m"(output_data.real), "+m"(output_data.imag));
    }

    free_aligned_doubles(twid_real_raw);
    free_aligned_doubles(twid_imag_raw);
    free_aligned_doubles(input_data.real);
    free_aligned_doubles(input_data.imag);
    free_aligned_doubles(output_data.real);
    free_aligned_doubles(output_data.imag);

    return 0;
}
