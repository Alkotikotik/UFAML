#include <iostream>

constexpr int COUNT = 6400000;

extern "C" void dot_product(const vec3 *vecA, const vec3 *vecB, const int count, float result);

struct vec3 {
    float *x;
    float *y;
    float *z;
};

int main() {
    float result;
    float *x = allocate_aligned_floats(count);
    float *y = allocate_aligned_floats(count);
    float *z = allocate_aligned_floats(count);

    for (size_t i = 0; i < COUNT; ++i) {
        x[i] = 1.0f;
        y[i] = 2.0f;
        z[i] = 3.0f;
    }
    vecA = (vec3)(xyz);
    vecB = (vec3)(zyx);

    dot_product(vecA, vecB, COUNT, result);

    free_aligned_floats(x);
    free_aligned_floats(y);
    free_aligned_floats(z);
}
