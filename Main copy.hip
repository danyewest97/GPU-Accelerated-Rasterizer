#include "Main.h"
#include <jni.h>
#include <iostream>

#include <hip/hip_runtime.h>

//#include <iostream>
#include <cstdlib>
#include <chrono> // For timing

// Precondition: Matrices must be compatible for multiplication
__device__ void matrix_multiplication(float* matrix, float* vector, float* output) {
    float x = vector[0];
    float y = vector[1];
    float z = vector[2];
    float result[] = {(matrix[0] + matrix[1] + matrix[2]) * x, 
                      (matrix[3] + matrix[4] + matrix[5]) * y,
                      (matrix[6] + matrix[7] + matrix[8]) * z};
    output[0] = result[0];
    output[1] = result[1];
    output[2] = result[2];
}

__global__ void matrix_kernel(float* initial_vectors, float* initial_matrices, float* output_vectors, int size, int vectors_per_thread) {
    int global_index = threadIdx.x + blockIdx.x * blockDim.x;
    int numbers_per_thread = vectors_per_thread * 3;
    int start = global_index * numbers_per_thread;
    int matrix_start = start * 3;
    int end = start + numbers_per_thread;
    float* vector = new float[3];
    float* matrix = new float[9];
    float* output = new float[3];
    while (start < end) {
        if (start >= size) break;

        for (int i = 0; i < 3; i++) {
            vector[i] = initial_vectors[start + i];
        }

        for (int i = 0; i < 9; i++) {
            matrix[i] = initial_matrices[matrix_start + i];
        }
        
        matrix_multiplication(matrix, vector, output);
        
        for (int i = 0; i < 3; i++) {
            output_vectors[start + i] = output[i];
        }

        start += 3;
        matrix_start += 9;
    }
}





__host__ void host_matrix_mult(float* matrix, float* vector, float* output) {
    float x = vector[0];
    float y = vector[1];
    float z = vector[2];
    float result[] = {(matrix[0] + matrix[1] + matrix[2]) * x, 
                      (matrix[3] + matrix[4] + matrix[5]) * y,
                      (matrix[6] + matrix[7] + matrix[8]) * z};
    output[0] = result[0];
    output[1] = result[1];
    output[2] = result[2];
}



// Important note: not sure how much overhead variable creation and logic happening inside the kernel is adding, because I am not just sending
// a shader to the GPU for it to handle and send back, but actually making new variables and doing more than *just* matrix matrix multiplication
// on the kernel

int run()
{
    using std::chrono::high_resolution_clock; // For timing, solution from https://stackoverflow.com/questions/22387586/measuring-execution-time-of-a-function-in-c
    using std::chrono::time_point;
    using std::chrono::duration_cast;
    using std::chrono::duration;
    using std::chrono::milliseconds;

    //TODO: Not sure why but crashing when vector count is high

    // Declaring constant variables
    const int num_vectors = 300000; // 120 million vectors => ~21ms with 48 blocks and 50 threads per block
    const int num_blocks = 10;
    const int num_threads_per_block = 10;
    const int total_num_threads = num_blocks * num_threads_per_block;
    const int num_vectors_per_thread = ceil((float) num_vectors / total_num_threads);
    

    



    // Initializing the randomly-generated input vectors and transformations
    static float* initial_vectors = new float[num_vectors * 3];
    for (int i = 0; i < num_vectors * 3; i++) {
        initial_vectors[i] = (float)  rand() / (1 + rand()); // Adding 1 to the denominator so that inf is not possible (divide by 0 => inf)
    }


    static float* initial_matrices = new float[num_vectors * 9];
    for (int i = 0; i < num_vectors * 9; i++) {
        initial_matrices[i] = (float) rand() / (1 + rand());
    }




    const int size = num_vectors * 3;
    const int vector_size = sizeof(float) * num_vectors * 3;
    const int matrix_size = sizeof(float) * num_vectors * 9;



    float* input_vectors;
    hipMalloc(&input_vectors, vector_size);
    hipMemcpy(input_vectors, initial_vectors, vector_size, hipMemcpyHostToDevice);

    float* input_matrices;
    hipMalloc(&input_matrices, matrix_size);
    hipMemcpy(input_matrices, initial_matrices, matrix_size, hipMemcpyHostToDevice);


    float* output;
    hipMalloc(&output, vector_size);

    
    // Start time
    auto start = high_resolution_clock::now();



    matrix_kernel<<<dim3(num_blocks),
                 dim3(num_threads_per_block),
                 0,
                 hipStreamDefault
                 >>>(input_vectors, input_matrices, output, size, num_vectors_per_thread);


    // Wait on all active streams on the current device.
    hipDeviceSynchronize();

    // End time
    auto end = high_resolution_clock::now();

    // Copy the final result out
    static float* finalResult = new float[size];
    hipMemcpy(finalResult, output, vector_size, hipMemcpyDeviceToHost);
    




    printf("Validating...\n");
    // Checking if the vector math was correct
    float* check_output = new float[size];
    for (int i = 0; i < num_vectors; i++) {
        float* vector = new float[3];
        float* matrix = new float[9];
        float* output = new float[3];
        for (int j = 0; j < 3; j++) {
            vector[j] = initial_vectors[(i * 3) + j];
        }

        for (int j = 0; j < 9; j++) {
            matrix[j] = initial_matrices[(i * 9) + j];
        }

        host_matrix_mult(matrix, vector, output);

        for (int j = 0; j < 3; j++) {
            check_output[(i * 3) + j] = output[j];
        }
    }

    bool correct = true;
    for (int i = 0; i < size; i++) {
        //printf("%f == %f\n", check_output[i], finalResult[i]);
        correct &= (abs(check_output[i] - finalResult[i]) <= 0.1);
        if (!correct) {
            printf("%f != %f\n", check_output[i], finalResult[i]);
            break;
        }
    }
    std::cout << correct << "\n";


    // Duration
    if (correct) printf("Validation completed! Matrix math is correct!\n");
    else printf("Validation failed! Matrix math is incorrect...\n");
    auto elapsedTime = end - start;
    auto elapsedMillis = duration_cast<milliseconds>(elapsedTime);
    //int millisInt = elapsedMillis.count();
    printf("Time taken: %ims\n", millisInt);

    

    printf("\nDone!");
}




JNIEXPORT void JNICALL Java_Main_helloWorld(JNIEnv* env, jobject thisObject) {
    run();
}