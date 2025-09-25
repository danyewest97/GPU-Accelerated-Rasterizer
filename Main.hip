#include "Main.h"
#include <jni.h>

#include <hip/hip_runtime.h>

#include <iostream> // Input and output functions like printf
#include <cstdlib> // Standard library with many useful functions
#include <chrono> // Library used for timing, for measuring performance

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
    color color;
    double absorption, reflection, transmission, diffusion;
};

// A 3D plane with components a, b, c, d, expressed by equation ax + by + cz + d = 0
struct plane {
    vector normal;                      // vector to store the components of the plane's normal as (a, b, c)
    double d;
};

// A 3D triangle defined by the 3 vectors a, b, and c, with the given material and plane
struct tri {
    plane plane;                        // the 3D plane that the triangle sits on
    material surface_material;          // the material that the triangle is "made out of," defining how light rays should interact with the triangle
    vector a;
    vector b;
    vector c;
};

// A container to hold the height and width of an image (or anything else with height and width)
struct dimensions {
    double height, width;
};

// 3D camera, defines where the camera rays originate and in which direction they radiate, to control where the viewport is looking
struct camera {
    vector origin;                      // The 3D point where all camera rays originate from
    vector rotation;                    // The direction where camera rays radiate from the origin, with components (x_rotation, y_rotation, 
                                        // z_rotation)
    double vfov, hfov;                  // The field-of-view parameters, expressed in radians, that define how far left/right or up/down the camera 
                                        // can see
};





class Vector {
    public:
        double x;
        double y;
        double z;

        __global__ Vector(double _x, double _y, double _z) {
            x = _x;
            y = _y;
            z = _z;
        }
};


class Color {
    public:
        double r;
        double g;
        double b;

        __global__ Vector(double _r, double _g, double _b) {
            r = _r;
            g = _g;
            b = _b;
        }
};


class Ray {
    public:
        Vector* origin = (Vector*) malloc(izeof(Vector));
        Vector* direction = (Vector*) malloc(sizeof(Vector));

        __global__ Ray(double x0, double y0, double z0,
                       double dx, double dy, double dz) {
            *origin = Vector(x0, y0, z0);
            *direction = Vector(dx, dy, dz);
        }
};


class Plane {
    public:
        Vector* origin = (Vector*) malloc(izeof(Vector));
        double shift;

        __global__ Plane(double a, double b, double c, double d) {
            origin = Vector(a, b, c);
            shift = d;
        }
};

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

<<<<<<< HEAD
=======
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


__device__ int* bounding_box(double x1, double y1, double x2, double y2, double x3, double y3, double img_width, double img_height) {
    // Subtracting 1 from the img_width and img_height values to account for 0-based indexing (max value should be img_width - 1, not img_width)
    img_width -= 1;
    img_height -= 1;
    
    double min_x = x1;
    double max_x = x1;
    double min_y = y1;
    double max_y = y1;
    
    if (x2 < min_x) min_x = x2;
    if (x3 < min_x) min_x = x3;
    
    if (x2 > max_x) max_x = x2;
    if (x3 > max_x) max_x = x3;
    
    if (y2 < min_y) min_y = y2;
    if (y3 < min_y) min_y = y3;
    
    if (y2 > max_y) max_y = y2;
    if (y3 > max_y) max_y = y3;
    
    int result_x[] = {
        (int) (min_x),
        (int) (max_x + 1)
    };
    
    int result_y[] = {
        (int) (min_y),
        (int) (max_y + 1)
    };
    
    for (int i = 0; i < 2; i++) {
        int curr_x = result_x[i];
        int curr_y = result_y[i];
        
        
        if (curr_x > img_height) curr_x = img_height;
        if (curr_x < 0) curr_x = 0;
        
        if (curr_y > img_width) curr_y = img_width;
        if (curr_y < 0) curr_y = 0;
    }
    
    int final_result[] = {
        result_x[0], result_x[1],
        result_y[0], result_y[1]
    };

    return final_result;
}

>>>>>>> 11aaf2748d730c15c58a51b8050fbf075b4a7ecc

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

}


__global__ void ray_trace_kernel(double* vertices_in, double* img_out, double size, double triangles_per_thread, double img_width, double img_height) {
    int global_index = threadIdx.x + blockIdx.x * blockDim.x;
    
}


__global__ void test_kernel() {
    printf("test kernel started");
<<<<<<< HEAD
=======
    
>>>>>>> 11aaf2748d730c15c58a51b8050fbf075b4a7ecc
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