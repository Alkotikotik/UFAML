#include <iostream>
#include <memory>
#include <new>

constexpr int PARTICLE_COUNT = 64000000;

// I did not write this code, since the main scope of this project is to write lib in assembly, and
// this is just for benchmark and examples

struct VerletInputs {
    const float *posX;
    const float *posY;
    const float *posZ;
    const float *velX;
    const float *velY;
    const float *velZ;
    const float *forceX;
    const float *forceY;
    const float *forceZ;
};

struct VerletOutputs {
    float *posOutX;
    float *posOutY;
    float *posOutZ;
    float *velOutX;
    float *velOutY;
    float *velOutZ;
    float *accelX;
    float *accelY;
    float *accelZ;
};

// Direct link to your custom assembly implementation
extern "C" void verlet_integration(const VerletInputs *config, int count, const float dt,
                                   const float mass, VerletOutputs *outputs);

// Quick helper function to allocate 64-byte aligned float arrays in C++
float *allocate_aligned_floats(size_t count) { return ::new (std::align_val_t{64}) float[count]; }

void free_aligned_floats(float *ptr) { ::operator delete[](ptr, std::align_val_t{64}); }

int main() {
    int count = PARTICLE_COUNT;
    float dt = 0.01666f;
    float mass = 10.0f;

    // --- 1. RAII Aligned Allocations ---
    float *posX = allocate_aligned_floats(count);
    float *posY = allocate_aligned_floats(count);
    float *posZ = allocate_aligned_floats(count);

    float *velX = allocate_aligned_floats(count);
    float *velY = allocate_aligned_floats(count);
    float *velZ = allocate_aligned_floats(count);

    float *forceX = allocate_aligned_floats(count);
    float *forceY = allocate_aligned_floats(count);
    float *forceZ = allocate_aligned_floats(count);

    float *posOutX = allocate_aligned_floats(count);
    float *posOutY = allocate_aligned_floats(count);
    float *posOutZ = allocate_aligned_floats(count);

    float *velOutX = allocate_aligned_floats(count);
    float *velOutY = allocate_aligned_floats(count);
    float *velOutZ = allocate_aligned_floats(count);

    float *accelX = allocate_aligned_floats(count);
    float *accelY = allocate_aligned_floats(count);
    float *accelZ = allocate_aligned_floats(count);

    // --- 2. Data Initialization ---
    for (int i = 0; i < count; ++i) {
        posX[i] = 1.0f;
        posY[i] = 2.0f;
        posZ[i] = 3.0f;
        velX[i] = 0.0f;
        velY[i] = 0.0f;
        velZ[i] = 0.0f;
        forceX[i] = 10.0f;
        forceY[i] = 20.0f;
        forceZ[i] = 30.0f;
    }

    // --- 3. Package Structs ---
    VerletInputs inputs{posX, posY, posZ, velX, velY, velZ, forceX, forceY, forceZ};
    VerletOutputs outputs{posOutX, posOutY, posOutZ, velOutX, velOutY,
                          velOutZ, accelX,  accelY,  accelZ};

    // --- 4. Call UFAML Engine ---
    verlet_integration(&inputs, count, dt, mass, &outputs);

    // Check value to prevent compiler optimizing the run away
    float check = outputs.posOutX[0] + outputs.velOutX[0] + outputs.accelX[0];
    if (check == 99999.0f) {
        std::cout << "Sanity check optimized out unexpected value.\n";
    }

    // --- 5. Clean up ---
    free_aligned_floats(posX);
    free_aligned_floats(posY);
    free_aligned_floats(posZ);
    free_aligned_floats(velX);
    free_aligned_floats(velY);
    free_aligned_floats(velZ);
    free_aligned_floats(forceX);
    free_aligned_floats(forceY);
    free_aligned_floats(forceZ);
    free_aligned_floats(posOutX);
    free_aligned_floats(posOutY);
    free_aligned_floats(posOutZ);
    free_aligned_floats(velOutX);
    free_aligned_floats(velOutY);
    free_aligned_floats(velOutZ);
    free_aligned_floats(accelX);
    free_aligned_floats(accelY);
    free_aligned_floats(accelZ);

    return 0;
}
