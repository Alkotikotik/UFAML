#include <iostream>
#include <new>

constexpr int COUNT = 64000000;

struct vec3 {
    float *x;
    float *y;
    float *z;
};

extern "C" void vec3_add(const vec3 *vecA, const vec3 *vecB, const int count, const vec3 *result);
extern "C" void vec3_subtract(const vec3 *vecA, const vec3 *vecB, const int count,
                              const vec3 *result);
extern "C" void vec3_len_accurate(const vec3 *vecA, const int count, float *result);
extern "C" void vec3_len_fast(const vec3 *vecA, const int count, float *result);

float *allocate_aligned_floats(size_t count) { return ::new (std::align_val_t{64}) float[count]; }

void free_aligned_floats(float *ptr) { ::operator delete[](ptr, std::align_val_t{64}); }

int main() {

    float *rx = allocate_aligned_floats(COUNT);
    float *ry = allocate_aligned_floats(COUNT);
    float *rz = allocate_aligned_floats(COUNT);
    vec3 result{rx, ry, rz};

    float *x = allocate_aligned_floats(COUNT);
    float *y = allocate_aligned_floats(COUNT);
    float *z = allocate_aligned_floats(COUNT);

    float *result_len = allocate_aligned_floats(COUNT);

    for (size_t i = 0; i < COUNT; ++i) {
        x[i] = 1.0f;
        y[i] = 2.0f;
        z[i] = 3.0f;
    }

    vec3 vecA{x, y, z};
    vec3 vecB{z, y, x};

    vec3_add(&vecA, &vecB, COUNT, &result);
    vec3_subtract(&vecA, &vecB, COUNT, &result);
    vec3_len_fast(&vecA, COUNT, result_len);

    free_aligned_floats(x);
    free_aligned_floats(y);
    free_aligned_floats(z);
    free_aligned_floats(rx);
    free_aligned_floats(ry);
    free_aligned_floats(rz);
}
