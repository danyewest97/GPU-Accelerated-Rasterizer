#include "Main.h"
#include <jni.h>

#include <hip/hip_runtime.h>

// TODO: Check if standard library functions can be used on GPU, and if not find out how to use sin and cos functions on GPU
#include <iostream> // Input and output functions like printf
#include <cstdlib> // Standard library with many useful functions
#include <chrono> // Library used for timing, for measuring performance
#include <cmath> // Standard math library for things like sine and cosine functions

// 3D vector with x-, y-, and z-values
struct vector {
    double x, y, z;
};

// RGB color with values between 0-1 (no alpha)
struct color {
    double r, g, b;
};

// A template for a material with different parameters that control how the material interacts with light (used in calculating BRDFs)
struct material {
    color material_color;
    double absorption, reflection, transmission, diffusion;
};

// A 3D plane with components a, b, c, d, expressed by equation ax + by + cz + d = 0
struct plane {
    vector normal;                      // vector to store the components of the plane's normal as (a, b, c)
    double d;
};

// A 3D Ray that starts from the 3D point origin and points in the direction given by the direction vector
struct ray {
    vector origin;
    vector direction;
};

// A 3D triangle defined by the 3 vectors a, b, and c, with the given material and plane
struct tri {
    plane surface_plane;                // the 3D plane that the triangle sits on
    material surface_material;          // the material that the triangle is "made out of," defining how light rays should interact with the triangle
    vector a;
    vector b;
    vector c;
};

// A container to hold the height and width of an image (or anything else with height and width)
struct dimensions {
    double width, height;
};

// 3D camera, defines where the camera rays originate and in which direction they radiate, to control where the viewport is looking
struct camera {
    vector origin;                      // The 3D point where all camera rays originate from
    vector rotation;                    // The direction where camera rays radiate from the origin, with components (x_rotation, y_rotation, 
                                        // z_rotation)
    double vfov, hfov;                  // The field-of-view parameters, expressed in radians, that define how far left/right or up/down the camera 
                                        // can see
};


// Precondition: Matrices must be compatible for multiplication
// TODO: Confirm that matrix multiplication algorithm, specifically matrix indices, are correct, and create a standard for how matrices should be 
// initialized (should first 3 digits of 3x3 be the x-components of the 3 basis vectors, or x-, y-, and z-components of the first basis vector?)
__global__ void matrix_multiplication(double* matrix, double* vector, double* output) {
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


__global__ void transform_vector(double* matrix, vector* v) {
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


// 3D vector rotation methods that rotate vector v around the vector center by the given radians, on the respective axis
__global__ void rotateX(vector* v, vector* center, double radians) {
    double sine = std::sin(radians);
    double cosine = std::cos(radians);
    
    double transformation_matrix[] = {
        1, 0, 0,
        0, cosine, -sine,
        0, sine, cosine
    };
    
    
}

__global__ void rotateY(vector* v, vector* center, double radians) {
    
}

__global__ void rotateZ(vector* v, vector* center, double radians) {
    
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



__global__ void trace_ray(int index, tri* tris, color* output) {

}


__global__ void generate_camera_rays(camera* curr_cam, dimensions* img_dims) {
    vector cam_origin = curr_cam->origin;
    vector cam_normal = curr_cam->rotation;
    double vfov = curr_cam->vfov;
    double hfov = curr_cam->hfov;
    
    double width = img_dims->width;
    double height = img_dims->height;
    
    //vector starting_direction = 
}


__global__ void ray_trace_kernel(double* vertices_in, double* img_out, double size, double triangles_per_thread, double img_width, double img_height) {
    int global_index = threadIdx.x + blockIdx.x * blockDim.x;
    
}


__global__ void test_kernel() {
    printf("test kernel started");
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
