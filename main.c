#include <stdalign.h>
#include <stdio.h>

// My lib

extern void asm_add_vectors_512(const float *a, const float *b, float *out, int count);
extern void verlet_integration(const float *pos, const float *vel, const float *accel,
                               const float dt, float *posOut, float *velOut, int count,
                               const float *force, const float mass);

typedef struct {
    alignas(64) float x[16];
    alignas(64) float y[16];
    alignas(64) float z[16];
} Chungus;

int main() {
    int count = 1024;
    int smallerCount = count / 16;
    float dt = 0.1f;
    float mass = 10.0f;
    Chungus pos[smallerCount];
    Chungus vel[smallerCount];
    Chungus accel[smallerCount];
    Chungus force[smallerCount];
    Chungus posOut[smallerCount];
    Chungus velOut[smallerCount];

    for (int i = 0; i < count; i++) {
        arrayA[i] = (float)i;
        arrayB[i] = (float)(i / 2);
        arrayOut[i] = 0.0f;
    }

    verlet_integration(pos, vel, accel, dt, posOut, velOut, count, force, mass);

    float checksum = 0.0f;
    for (int i = 0; i < count; i++) {
        checksum += arrayOut[i];
    }
    printf("My lib: %.1f\n", checksum);

    return 0;
}
