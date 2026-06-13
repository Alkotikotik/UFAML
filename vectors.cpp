#include <iostream>

constexpr int COUNT = 64000000;

struct vec3 {
    float *x;
    float *y;
    float *z;
};

extern "C" void dot_product(const vec3 *vecA, const vec3 *vecB, const int count, float *result);

float *allocate_aligned_floats(size_t count) { return ::new (std::align_val_t{64}) float[count]; }

void free_aligned_floats(float *ptr) { ::operator delete[](ptr, std::align_val_t{64}); }

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

    dot_product(&vecA, &vecB, COUNT, result);

    std::cout << "Result[0]: " << result[0] << " (Expected: 10.0)" << std::endl;
    std::cout << "Result[COUNT-1]: " << result[COUNT - 1] << " (Expected: 10.0)" << std::endl;

    free_aligned_floats(x);
    free_aligned_floats(y);
    free_aligned_floats(z);
    free_aligned_floats(result);
}
