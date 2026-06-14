#include <chrono>
#include <cstdlib>
#include <iostream>

constexpr int COUNT = 64000000;

struct vec3 {
    float *__restrict__ x;
    float *__restrict__ y;
    float *__restrict__ z;
};

// Pure C++ implementation of your dot product engine
// '__restrict__' tells Clang that the pointers do not overlap,
// which is crucial for maximizing vectorization.
void c_dot_product(const vec3 &vecA, const vec3 &vecB, const int count,
                   float *__restrict__ result) {
// Force Clang to unroll this 4 times, exactly like your assembly code
#pragma clang loop vectorize(enable) interleave_count(4)
    for (int i = 0; i < count; ++i) {
        result[i] = (vecA.x[i] * vecB.x[i]) + (vecA.y[i] * vecB.y[i]) + (vecA.z[i] * vecB.z[i]);
    }
}

float *allocate_aligned_floats(size_t count) {
    void *ptr = nullptr;
    if (posix_memalign(&ptr, 64, count * sizeof(float)) != 0) {
        return nullptr;
    }
    return static_cast<float *>(ptr);
}

int main() {
    float *result = allocate_aligned_floats(COUNT);
    float *x = allocate_aligned_floats(COUNT);
    float *y = allocate_aligned_floats(COUNT);
    float *z = allocate_aligned_floats(COUNT);

    for (size_t i = 0; i < COUNT; ++i) {
        x[i] = 1.0f;
        y[i] = 2.0f;
        z[i] = 3.0f;
    }

    vec3 vecA{x, y, z};
    vec3 vecB{z, y, x};

    // Warmup
    c_dot_product(vecA, vecB, COUNT, result);

    // Timing the execution inside the driver just for quick output verification
    auto start = std::chrono::high_resolution_clock::now();

    c_dot_product(vecA, vecB, COUNT, result);

    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double, std::milli> duration = end - start;

    std::cout << "Result[0]: " << result[0] << "\n";
    std::cout << "Internal Code Execution Time: " << duration.count() << " ms\n";

    std::free(x);
    std::free(y);
    std::free(z);
    std::free(result);
    return 0;
}
