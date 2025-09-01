#include "Main.h"
#include <jni.h>
#include <iostream>

#include <hip/hip_runtime.h>

//#include <iostream>
#include <cstdlib>
#include <chrono> // For timing
#include <float.h>

// Precondition: Matrices must be compatible for multiplication
__device__ void matrix_multiplication(double* matrix, double* vector, double* output) {
    double x = vector[0];
    double y = vector[1];
    double z = vector[2];
    double result[] = {(matrix[0] + matrix[1] + matrix[2]) * x, 
                      (matrix[3] + matrix[4] + matrix[5]) * y,
                      (matrix[6] + matrix[7] + matrix[8]) * z};
    output[0] = result[0];
    output[1] = result[1];
    output[2] = result[2];
}

__global__ void matrix_kernel(double* vectors_in, double* matrix_in, double* vectors_out, int size, int vectors_per_thread) {
    int global_index = threadIdx.x + blockIdx.x * blockDim.x;
    int start_index = (global_index * vectors_per_thread) * 3;


    for (int i = 0; i < vectors_per_thread; i++) {
        if (start_index >= size) continue; // *Should* account for null vectors that don't need to be processed
        double vector[3];
        for (int j = 0; j < 3; j++) {
            vector[j] = vectors_in[start_index + j];
        }
        
        double output[3];
        matrix_multiplication(matrix_in, vector, output);
        for (int j = 0; j < 3; j++) {
            vectors_out[start_index + j] = output[j];
        }

        
        start_index += 3;
    }
}



__device__ int* bounding_box(double x1, double y1, double x2, double y2, double x3, double y3) {
    double minx = DBL_MAX;
    double maxx = -DBL_MAX;
    
    return new int[1];
}


// Checks if the point (i, j) is contained in the triangle defined by the points (x1, y1), (x2, y2), and (x3, y3)
__device__ bool contains(double i, double j, double x1, double y1, double x2, double y2, double x3, double y3) {
    double dotAB = -(i - y1) * (x2 - x1) + (j - x1) * (y2 - y1);
    double dotBC = -(i - y2) * (x3 - x2) + (j - x2) * (y3 - y2);
    double dotCA = -(i - y3) * (x1 - x3) + (j - x3) * (y1 - y3);

    bool allPos = dotAB >= 0 && dotBC >= 0 && dotCA >= 0;
    bool allNeg = dotAB <= 0 && dotBC <= 0 && dotCA <= 0;

    return allPos || allNeg;
}


__global__ void rasterize_kernel(double* vertices_in, double* img_out, double size, double triangles_per_thread, double img_width, double img_height) {
    int global_index = threadIdx.x + blockIdx.x * blockDim.x;
    int start_index = (global_index * triangles_per_thread) * 9;

    // NOTE: Not sure if there is a better way to not have the + 3 and + 6 and + 9 operations, or if they even add significant overhead (or any overhead at all)
    for (int i = 0; i < triangles_per_thread; i++) {
        if (start_index + 9 >= size) continue;

        float a[3];
        float b[3];
        float c[3];
        for (int j = 0; j < 3; j++) {
            a[j] = vertices_in[start_index + j];
            b[j] = vertices_in[start_index + j + 3];
            c[j] = vertices_in[start_index + j + 6];
        }


        

        start_index += 9;
    }
}


__global__ void test_kernel() {
    printf("test kernel started");
    //bounding_box(1, 1, 1, 1, 1, 1);
    printf("test kernel finished");
}




// Important note: not sure how much overhead variable creation and logic happening inside the kernel is adding, because I am not just sending
// a shader to the GPU for it to handle and send back, but actually making new variables and doing more than *just* matrix matrix multiplication
// on the kernel

void run()
{
    test_kernel<<<
        dim3(1),
        dim3(1),
        0,
        hipStreamDefault
    >>>();

    // Wait on all active streams on the current device. VERY NECESSARY
    hipDeviceSynchronize();

}




JNIEXPORT void JNICALL Java_Main_test(JNIEnv* env, jobject thisObject) {
    run();
}