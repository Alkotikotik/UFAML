#include <cmath>
#include <cstdlib>
#include <iostream>

constexpr int COUNT = 64000000;

struct vec3 {
    float *__restrict__ x;
    float *__restrict__ y;
    float *__restrict__ z;
};

// Pure C++ vector addition matching your SoA layout
void c_vec3_add(const vec3 &vecA, const vec3 &vecB, const int count, vec3 &result) {
// Explicitly target 512-bit vectors (16 floats * 4 bytes = 64 byte width)
// and match your exact unroll factor of 4
#pragma clang loop vectorize(enable) vectorize_width(16) interleave_count(4)
    for (int i = 0; i < count; ++i) {
        result.x[i] = vecA.x[i] + vecB.x[i];
        result.y[i] = vecA.y[i] + vecB.y[i];
        result.z[i] = vecA.z[i] + vecB.z[i];
    }
}

// Pure C++ vector subtraction matching your SoA layout
void c_vec3_subtract(const vec3 &vecA, const vec3 &vecB, const int count, vec3 &result) {
#pragma clang loop vectorize(enable) vectorize_width(16) interleave_count(4)
    for (int i = 0; i < count; ++i) {
        result.x[i] = vecA.x[i] - vecB.x[i];
        result.y[i] = vecA.y[i] - vecB.y[i];
        result.z[i] = vecA.z[i] - vecB.z[i];
    }
}

// Pure C++ vector length calculation matching your unrolled layout
void c_vec3_len(const vec3 &vecA, const int count, float *__restrict__ result) {
#pragma clang loop vectorize(enable) vectorize_width(16) interleave_count(4)
    for (int i = 0; i < count; ++i) {
        float x = vecA.x[i];
        float y = vecA.y[i];
        float z = vecA.z[i];
        result[i] = std::sqrt((x * x) + (y * y) + (z * z));
    }
}

// Pure C++ vector scaling matching your unrolled layout
void c_vec3_scale(const vec3 &vecA, const float factor, const int count, vec3 &result) {
#pragma clang loop vectorize(enable) vectorize_width(16) interleave_count(4)
    for (int i = 0; i < count; ++i) {
        result.x[i] = vecA.x[i] * factor;
        result.y[i] = vecA.y[i] * factor;
        result.z[i] = vecA.z[i] * factor;
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
    // Allocation for Add/Subtract results
    float *rx = allocate_aligned_floats(COUNT);
    float *ry = allocate_aligned_floats(COUNT);
    float *rz = allocate_aligned_floats(COUNT);
    vec3 result{rx, ry, rz};

    // Allocation for Scale results (keeps it from clobbering 'result')
    float *rsx = allocate_aligned_floats(COUNT);
    float *rsy = allocate_aligned_floats(COUNT);
    float *rsz = allocate_aligned_floats(COUNT);
    vec3 result_scale{rsx, rsy, rsz};

    float *len_result = allocate_aligned_floats(COUNT);

    // Input vectors allocation
    float *x = allocate_aligned_floats(COUNT);
    float *y = allocate_aligned_floats(COUNT);
    float *z = allocate_aligned_floats(COUNT);

    // Initialize arrays
    for (size_t i = 0; i < COUNT; ++i) {
        x[i] = 1.0f;
        y[i] = 2.0f;
        z[i] = 3.0f;
    }

    vec3 vecA{x, y, z};
    vec3 vecB{z, y, x};
    float scale_factor = 4.0f;

    // Execute the logic sequentially for hyperfine to snapshot
    c_vec3_add(vecA, vecB, COUNT, result);
    c_vec3_subtract(vecA, vecB, COUNT, result);
    c_vec3_len(vecA, COUNT, len_result);
    c_vec3_scale(vecA, scale_factor, COUNT, result_scale);

    // Minimal stdout print so compiler doesn't optimize everything away
    std::cout << "Final Validation Value X[0]: " << result.x[0] << "\n";
    std::cout << "Final Length Validation Value[0]: " << len_result[0] << "\n";
    std::cout << "Final Scale Validation Value X[0]: " << result_scale.x[0] << "\n";

    // Clean up everything
    std::free(x);
    std::free(y);
    std::free(z);
    std::free(rx);
    std::free(ry);
    std::free(rz);
    std::free(rsx);
    std::free(rsy);
    std::free(rsz);
    std::free(len_result);

    return 0;
}
