#include <cstddef>
#include <iostream>
#include <new>
#include <vector>

// I did not write this code, since the main scope of this project is to write lib in assembly, and
// this is just for benchmark and examples

constexpr int PARTICLE_COUNT = 64000000;

// Fixed Aligned Allocator with necessary boilerplate type definitions
template <typename T, std::size_t Alignment = 64> struct AlignedAllocator {
    using value_type = T;
    using pointer = T *;
    using const_pointer = const T *;
    using reference = T &;
    using const_reference = const T &;
    using size_type = std::size_t;
    using difference_type = std::ptrdiff_t;

    // Boilerplate telling the standard library container how to swap allocations if needed
    template <typename U> struct rebind {
        using other = AlignedAllocator<U, Alignment>;
    };

    AlignedAllocator() noexcept = default;
    template <typename U> AlignedAllocator(const AlignedAllocator<U, Alignment> &) noexcept {}

    T *allocate(std::size_t n) {
        if (n == 0)
            return nullptr;
        // Request 64-byte aligned chunk from global new operator
        if (auto p =
                static_cast<T *>(::operator new[](n * sizeof(T), std::align_val_t{Alignment}))) {
            return p;
        }
        throw std::bad_alloc();
    }

    void deallocate(T *p, std::size_t n) noexcept {
        ::operator delete[](p, std::align_val_t{Alignment});
    }

    // Required operators for allocator comparison
    bool operator==(const AlignedAllocator &) const noexcept { return true; }
    bool operator!=(const AlignedAllocator &) const noexcept { return false; }
};

// Type alias for easier reading
using AlignedFloatVector = std::vector<float, AlignedAllocator<float, 64>>;

int main() {
    int count = PARTICLE_COUNT;
    float dt = 0.01666f;
    float mass = 10.0f;
    float invMass = 1.0f / mass;
    float halfDtSq = 0.5f * dt * dt;

    // --- 1. Automatic RAII Aligned Allocations ---
    AlignedFloatVector posX(count, 1.0f);
    AlignedFloatVector posY(count, 2.0f);
    AlignedFloatVector posZ(count, 3.0f);

    AlignedFloatVector velX(count, 0.0f);
    AlignedFloatVector velY(count, 0.0f);
    AlignedFloatVector velZ(count, 0.0f);

    AlignedFloatVector forceX(count, 10.0f);
    AlignedFloatVector forceY(count, 20.0f);
    AlignedFloatVector forceZ(count, 30.0f);

    AlignedFloatVector posOutX(count);
    AlignedFloatVector posOutY(count);
    AlignedFloatVector posOutZ(count);

    AlignedFloatVector velOutX(count);
    AlignedFloatVector velOutY(count);
    AlignedFloatVector velOutZ(count);

    AlignedFloatVector accelX(count);
    AlignedFloatVector accelY(count);
    AlignedFloatVector accelZ(count);

// --- 2. Pure C++ Verlet Loops ---
// X Axis
#pragma clang loop vectorize(enable) interleave(enable)
    for (int i = 0; i < count; ++i) {
        accelX[i] = forceX[i] * invMass;
        posOutX[i] = posX[i] + (velX[i] * dt) + (accelX[i] * halfDtSq);
        velOutX[i] = velX[i] + (accelX[i] * dt);
    }

// Y Axis
#pragma clang loop vectorize(enable) interleave(enable)
    for (int i = 0; i < count; ++i) {
        accelY[i] = forceY[i] * invMass;
        posOutY[i] = posY[i] + (velY[i] * dt) + (accelY[i] * halfDtSq);
        velOutY[i] = velY[i] + (accelY[i] * dt);
    }

// Z Axis
#pragma clang loop vectorize(enable) interleave(enable)
    for (int i = 0; i < count; ++i) {
        accelZ[i] = forceZ[i] * invMass;
        posOutZ[i] = posZ[i] + (velZ[i] * dt) + (accelZ[i] * halfDtSq);
        velOutZ[i] = velZ[i] + (accelZ[i] * dt);
    }

    // --- 3. Prevent compiler dead-code elimination ---
    float check = posOutX[0] + velOutX[0] + accelX[0];
    if (check == 99999.0f) {
        std::cout << "Check fail\n";
    }

    return 0;
}
