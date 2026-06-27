#include <cmath>
#include <complex>
#include <iostream>
#include <vector>

typedef std::complex<double> complex_t;

struct cmplx {
    double *real;
    double *imag;
};

extern "C" void fft_kernel(cmplx *src, cmplx *dst, cmplx *twiddles, int N, int stride);

// Computing it here since it is a 1 time operation
cmplx pre_compute_twiddles(int N) {
    cmplx twiddles;
    for (int i = 0; i < N; ++i) {
        double theta = (2.0 * M_PI * k) / N;
        twiddles.real = std::cos(theta);
        twiddles.imag = -std::sin(theta);
    }
    return twiddles;
}

void fft_source(int N, complex_t *x) {

    std::vector<cmplx> buffer(N);

    cmplx *src = x;
    cmplx *dest = buffer.data();

    int total_passes = 0;
    for (int stride = 1; stride < N; stride *= 16) {

        fft_kernel(&src, &dest, &pre_compute_twiddles(N), N, stride);

        std::swap(src, dest);
        total_passes++;
    }

    if (src != x) {
        std::copy(buffer.begin(), buffer.end(), x);
    }
}
