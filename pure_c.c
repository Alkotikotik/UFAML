#include <stdalign.h>
#include <stdio.h>

// Clang

int main() {
    alignas(64) float arrayA[1024];
    alignas(64) float arrayB[1024];
    alignas(64) float arrayOut[1024];

    for (int i = 0; i < 1024; i++) {
        arrayA[i] = (float)i;
        arrayB[i] = (float)(i / 2);
        arrayOut[i] = 0.0f;
    }

    for (int i = 0; i < 1024; i++) {
        arrayOut[i] = arrayA[i] + arrayB[i];
    }

    // Dummy loop
    float checksum = 0.0f;
    for (int i = 0; i < 1024; i++) {
        checksum += arrayOut[i];
    }
    printf("Clang: %.1f\n", checksum);

    return 0;
}
