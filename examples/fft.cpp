#include <cmath>
#include <complex>
#include <iostream>
#include <vector>

typedef std::complex<double> complex_t;

extern "C" void fft_kernel(complex_t *src, complex_t *dst, complex_t *twiddles, int s, int m);

// Computing it here since it is a 1 time operation
std::vector<complex_t> pre_compute_twiddles(int N) {
    std::vector<complex_t> twiddles(N);
    for (int k = 0; k < N; ++k) {
        double theta = (2.0 * M_PI * k) / N;
        twiddles[k] = complex_t(std::cos(theta), -std::sin(theta));
    }
    return twiddles;
}

void fft_source(int N, complex_t *x) {

    // Temp storage
    std::vector<complex_t> y(N);

    complex_t *src = x;
    complex_t *dst = y.data();

    for (int stride = 1, span = N / 16; span > 0; stride *= 16, span /= 16) {

        fft_kernel(&src, &dst, &pre_compute_twiddles(N), stride, span);

        std::swap(src, dst);
    }

    if (src != x) {
        std::copy(y.begin(), y.end(), x);
    }
}
