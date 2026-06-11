#include <stdalign.h>
#include <stdio.h>

typedef struct {
    // Each pointer is 8 bytes
    const float *posX;
    const float *posY;
    const float *posZ;
    // So 3*8 = 24 bytes offset
    const float *velX;
    const float *velY;
    const float *velZ;
    // Hence 48 bytes
    const float *forceX;
    const float *forceY;
    const float *forceZ;
} VerletInputs;

typedef struct {
    float *posOutX;
    float *posOutY;
    float *posOutZ;

    float *velOutX;
    float *velOutY;
    float *velOutZ;

    float *accelX;
    float *accelY;
    float *accelZ;
} VerletOutputs;

extern void verlet_integration_soa(const VerletInputs *config, int count, const float dt,
                                   const float mass, VerletOutputs *outputs);

int main() {
    int count = 1024;
    float dt = 0.01666f;
    float mass = 10.0f;

    VerletInputs inputs = {.posX = posX,
                           .posY = posY,
                           .posZ = posZ,
                           .velX = velX,
                           .velY = velY,
                           .velZ = velZ,
                           .forceX = forceX,
                           .forceY = forceY,
                           .forceZ = forceZ,
                           .accelX = accelX,
                           .accelY = accelY,
                           .accelZ = accelZ,
                           .posOutX = posOutX,
                           .posOutY = posOutY,
                           .posOutZ = posOutZ,
                           .velOutX = velOutX,
                           .velOutY = velOutY,
                           .velOutZ = velOutZ};

    verlet_integration_soa(&config, count, dt, mass);

    return 0;
}
