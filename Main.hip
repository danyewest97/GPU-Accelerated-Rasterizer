#include "Main.h"
#include <jni.h>

#include <hip/hip_runtime.h>

// TODO: Check if standard library functions can be used on GPU, and if not find out how to use sin and cos functions on GPU
#include <iostream> // Input and output functions like printf
#include <cstdlib> // Standard library with many useful functions
#include <chrono> // Library used for timing, for measuring performance
#include <cmath> // Standard math library for things like sine and cosine functions
using namespace std; // Makes it so I don't have to put std:: before everything!

// Custom/local library files
#include "structs.cpp"; // Includes all of the required structs and their constructors, plus some methods for them


// Precondition: Matrices must be compatible for multiplication
// TODO: Confirm that matrix multiplication algorithm, specifically matrix indices, are correct, and create a standard for how matrices should be 
// initialized (should first 3 digits of 3x3 be the x-components of the 3 basis vectors, or x-, y-, and z-components of the first basis vector?)
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


__device__ void transform_vector(double* matrix, vector* v) {
    double x = v->x;
    double y = v->y;
    double z = v->z;
    double result[] = {(matrix[0] + matrix[1] + matrix[2]) * x, 
                      (matrix[3] + matrix[4] + matrix[5]) * y,
                      (matrix[6] + matrix[7] + matrix[8]) * z};
    v->x = result[0];
    v->y = result[1];
    v->z = result[2];
}


// Subtracts the second vector from the first vector
__device__ void sub_vectors(vector* v, vector* w) {
    v->x -= w->x;
    v->y -= w->y;
    v->z -= w->z;
}

// Adds the second vector to the first vector
__device__ void add_vectors(vector* v, vector* w) {
    v->x += w->x;
    v->y += w->y;
    v->z += w->z;
}


// 3D vector rotation methods that rotate vector v around the vector center by the given radians, on the respective axis
__device__ void rotate_x(vector* v, vector* center, double radians) {
    double sine = sin(radians);
    double cosine = cos(radians);
    
    double transformation_matrix[] = {
        1, 0, 0,
        0, cosine, -sine,
        0, sine, cosine
    };
    
    sub_vectors(v, center);
    transform_vector(transformation_matrix, v);
    add_vectors(v, center);
}

__device__ void rotate_y(vector* v, vector* center, double radians) {
    double sine = sin(radians);
    double cosine = cos(radians);
    
    double transformation_matrix[] = {
        cosine, 0, sine,
        0, 1, 0,
        -sine, 0, cosine
    };
    
    sub_vectors(v, center);
    transform_vector(transformation_matrix, v);
    add_vectors(v, center);
}

__device__ void rotate_z(vector* v, vector* center, double radians) {
    double sine = sin(radians);
    double cosine = cos(radians);

    double transformation_matrix[] = {
        cosine, -sine, 0,
        sine, cosine, 0,
        0, 0, 1
    };
    
    sub_vectors(v, center);
    transform_vector(transformation_matrix, v);
    add_vectors(v, center);
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



__global__ void trace_ray(int index, triangle* tris, color* output) {

}


__global__ void generate_camera_rays(camera* curr_cam, dimensions* img_dims) {
    vector cam_origin = curr_cam->origin;
    vector cam_normal = curr_cam->rotation;
    double vfov = curr_cam->vfov;
    double hfov = curr_cam->hfov;
    
    double width = img_dims->width;
    double height = img_dims->height;
    
    double initial_horizontal_rotation = -hfov / 2;
    double initial_vertical_rotation = -vfov / 2;
    double initial_horizontal_offset = -width / 2;
    double initial_vertical_offset = -height / 2;


    vector* starting_direction = clone_vector(&cam_normal);
    rotate_x(starting direction, &cam_origin, initial_horizontal_rotation);
    rotate_y(starting direction, &cam_origin, initial_vertical_rotation);
}


__global__ void ray_trace_kernel(double* vertices_in, double* img_out, double size, double triangles_per_thread, double img_width, double img_height) {
    int global_index = threadIdx.x + blockIdx.x * blockDim.x;
    
}


// Note: For some reason (probably a compilation bug or something), HIP seems to break when I put two identical print statements in here
// -- so don't do that!
__global__ void test_kernel() {
    printf("test kernel started\n");
    vector* v = new_vector(1, 2, 3);
    printf("%f\n", v->x);
    printf("test kernel finished\n");
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
