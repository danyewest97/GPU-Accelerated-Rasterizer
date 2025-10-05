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
#include "structs.cpp" // Includes all of the required structs and their constructors, plus some methods for them


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


// Takes the given camera and image dimensions and generates the corresponding primary/camera rays for them
__device__ ray** generate_camera_rays(camera* curr_cam, dimensions* img_dims) {
    vector* cam_origin = curr_cam->origin;
    vector* cam_normal = curr_cam->rotation;
    double fov_scale = curr_cam->fov_scale;
    
    int width = img_dims->width;
    int height = img_dims->height;
    int num_rays = width * height;
    

    // TODO: Confirm that rays need to be offset? Or should they just come directly from the camera origin with no offset? I think having an offset is 
    // correct
    // Note: may need optimizations for greater performance -- and either offload to CPU or do this in parallel (make new kernel for this?)
    double initial_horizontal_offset = -width / 2 + 0.5;                    // Adding 0.5 to each offset to move the rays to be in the middle of each 
                                                                            // pixel
    double initial_vertical_offset = -height / 2 + 0.5;
    double passthrough_plane_distance = fov_scale;                          // Corresponds to the FOV scale of the camera (vertical and horizontal FOV 
                                                                            // values depend on the width and height of the camera), this is my own 
                                                                            // method for generating camera rays: imagine a plane that is fov_scale 
                                                                            // units from the camera pinhole/aperture, and we are drawing a ray to the 
                                                                            // centers of each of the cells on this plane -- the further away this 
                                                                            // plane gets, the more clustered the rays are, so the smaller the FOV, 
                                                                            // and vice versa for when the plane gets closer to the camera.
                                                                            // I chose to do it this way because it is very intuitive to me and incredibly easy to implement, since no rotation is involved

    vector* start_position = new_vector(initial_horizontal_offset, 
                                        initial_vertical_offset, 
                                        passthrough_plane_distance);        // The position on the plane (described above) that we start on, drawing
                                                                            // a ray from the camera to this position will generate our camera rays
    vector* true_origin = new_vector(0, 0, 0);                              // We will initially draw rays originating from (0, 0, 0), then translate 
                                                                            // and rotate them according to the camera's position
    ray** primary_rays = new ray*[num_rays];                                // Also called camera rays, primary rays are the resulting, final rays 
                                                                            // that we will use for ray casting
    
    // Iterating through every cell in the image and creating a camera/primary ray for it
    for (int i = 0; i < width; i++) {
        for (int j = 0; j < height; j++) {
            vector* curr_position = clone_vector(start_position);
            ray* curr_ray = new_ray(true_origin, curr_position);            // Creating the initial ray, not yet conformed to the camera's orientation

            add_vectors(curr_ray->origin, cam_origin);                      // Orienting the ray to be lined up properly with the camera (translating 
            // to the camera's origin)
            // TODO: Make this into one operation, by precalculating the single matrix needed for all three rotations and only using that matrix
            rotate_x(curr_ray->direction, true_origin, cam_normal->x);      // Rotating the ray to face the same direction as the camera -- using 
                                                                            // true_origin instead of cam_origin because the direction of the ray 
                                                                            // determines where it points from its origin, so it is not 
                                                                            // location-dependent and should therefore be rotated about (0, 0, 0)
            rotate_y(curr_ray->direction, true_origin, cam_normal->y);
            rotate_z(curr_ray->direction, true_origin, cam_normal->z);

            primary_rays[i * height + j] = curr_ray;
            start_position->y++;
        }
        start_position->x++;
    }

    return primary_rays;
}


__global__ void ray_trace_kernel(double* vertices_in, double* img_out, double size, double triangles_per_thread, double img_width, double img_height) {
    int global_index = threadIdx.x + blockIdx.x * blockDim.x;
    
}


// Note: For some reason (probably a compilation bug or something), HIP seems to break when I put two identical print statements in here
// -- so don't do that!
__global__ void test_kernel() {
    printf("test kernel started\n");

    vector* cam_origin = new_vector(0, 0, 0);
    vector* cam_direction = new_vector(0, 0, 0);
    double fov_scale = 1;
    camera* main_cam = new_camera(cam_origin, cam_direction, fov_scale);

    int width = 10;
    int height = 10;
    dimensions* img_dimensions = new_dimensions(10, 10);

    ray** main_cam_rays = generate_camera_rays(main_cam, img_dimensions);

    vector* test_vector = main_cam_rays[1]->direction;
    print_vector(test_vector);
    printf("\n");

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
