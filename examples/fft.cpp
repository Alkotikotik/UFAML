#include <cmath>
#include <complex>
#include <iostream>
#include <vector>

typedef std::complex<double> complex_t;

// my beloved SoA
struct cmplx {
    double *real;
    double *imag;
};

extern "C" void fft_kernel(const cmplx *src, const cmplx *dst, const cmplx *twiddles, int N,
                           int stride);

// Pre compute twiddles, since it is one time operation
void pre_compute_twiddles(int N, double *twid_real, double *twid_imag) {
    int idx = 0;
    for (int stride = 1; stride < N; stride *= 16) {
        int num_blocks = N / (stride * 16);
        for (int b = 0; b < num_blocks; ++b) {
            for (int i = 0; i < stride; ++i) {
                int j = b * stride + i;

                for (int k = 1; k <= 15; ++k) {
                    double theta = (2.0 * M_PI * j * k) / (stride * 16);
                    twid_real[idx] = std::cos(theta);
                    twid_imag[idx] = -std::sin(theta);
                    idx++;
                }
            }
        }
    }
}

void fft_source(int N, complex_t *x) {
    // Init
    std::vector<double> src_real(N), src_imag(N);
    std::vector<double> dst_real(N), dst_imag(N);

    // Unpack
    for (int i = 0; i < N; ++i) {
        src_real[i] = x[i].real();
        src_imag[i] = x[i].imag();
    }

    // Allocate and pre-compute twiddles
    int total_twiddles_alloc = 15 * N * 2;
    std::vector<double> twid_real(total_twiddles_alloc);
    std::vector<double> twid_imag(total_twiddles_alloc);

    pre_compute_twiddles(N, twid_r.data(), twid_i.data());

    // Setup working structural descriptors for the kernel execution
    cmplx src_desc = {src_real.data(), src_imag.data()};
    cmplx dst_desc = {dst_real.data(), dst_imag.data()};
    cmplx twid_desc = {twid_real.data(), twid_imag.data()};

    // Stockham loop
    int pass = 0;
    for (int stride = 1; stride < N; stride *= 16) {

        fft_kernel(&src_desc, &dst_desc, &twid_desc, N, stride);

        // Increase twiddle pointers
        int twiddles_used_this_pass = 15 * (N / 16);
        twid_desc.real += twiddles_used_this_pass;
        twid_desc.imag += twiddles_used_this_pass;

        // Ping-pong!!!
        std::swap(src_desc.real, dst_desc.real);
        std::swap(src_desc.imag, dst_desc.imag);
        pass++;
    }

    for (int i = 0; i < N; ++i) {
        x[i] = complex_t(src_desc.real[i], src_desc.imag[i]);
    }
}
