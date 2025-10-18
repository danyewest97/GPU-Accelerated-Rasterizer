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
#include "main_structs.cpp" // Includes all of the required main structs and their constructors, plus some methods for them
#include "specific_structs.cpp" // Includes all of the required more-specific structs and their constructors, plus some methods for them

// #include "arrays.cpp" // Includes all of the required structs and their constructors, plus some methods for them
// NOTE: Convention will be to use custom-made array types (in arrays.cpp) for ALL arrays, and only using pointers when the pointer is pointing to a 
// SINGLE value and not multiple. This allows for bounds-checking and is much safer. --EDIT: Leaving as a suggestion for now, may implement later if it
// is necessary but I realized while thinking it over that it may end up being easier to just provide a length argument whenever we pass pointers of 
// unknown length, and implement bounds-checking using that length manually instead of making custom methods to do it


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


// __global__ 


// Oh yeah, baby... this is where the magic happens
__global__ void trace_ray(ray* primary_ray, triangle* triangles, color* output_color) {
    
}

// Deprecated
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

    vector* start_position = new vector(initial_horizontal_offset, 
                                        initial_vertical_offset, 
                                        passthrough_plane_distance);        // The position on the plane (described above) that we start on, drawing
                                                                            // a ray from the camera to this position will generate our camera rays
    vector* true_origin = new vector(0, 0, 0);                              // We will initially draw rays originating from (0, 0, 0), then translate 
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
            rotate_x(curr_ray->direction, true_origin, *cam_normal->x);      // Rotating the ray to face the same direction as the camera -- using 
                                                                            // true_origin instead of cam_origin because the direction of the ray 
                                                                            // determines where it points from its origin, so it is not 
                                                                            // location-dependent and should therefore be rotated about (0, 0, 0)
            rotate_y(curr_ray->direction, true_origin, *cam_normal->y);
            rotate_z(curr_ray->direction, true_origin, *cam_normal->z);
            normalize(curr_ray->direction);                                 // Normalizing the ray's direction so that distances returned from intersection methods will be 
                                                                            // absolute and not scaled by the ray direction's length (the t-value, or distance, returned from the 
                                                                            // ray-plane and ray-triangle intersection methods is dependent upon the ray direction's length, so if 
                                                                            // that length is 1, the t-value returned will be the same as the Euclidean distance from the ray's 
                                                                            // origin to the intersection point)

            primary_rays[i * height + j] = curr_ray;
            *start_position->y++;
        }
        *start_position->x++;
    }

    return primary_rays;
}


// Same as above but only calculates a single ray, for parallel processing
__device__ ray* generate_camera_ray(camera* curr_cam, dimensions* img_dim, int pixel_x, int pixel_y) {
    vector* cam_origin = curr_cam->origin;
    vector* cam_normal = curr_cam->rotation;
    int* width = &img_dim->width;
    int* height = &img_dim->height;

    // TODO: Confirm that rays need to be offset? Or should they just come directly from the camera origin with no offset? I think having an offset is 
    // correct
    // Note: may need optimizations for greater performance -- and either offload to CPU or do this in parallel (make new kernel for this?)
    double* passthrough_plane_distance = &curr_cam->fov_scale;              // Corresponds to the FOV scale of the camera (vertical and horizontal FOV 
                                                                            // values depend on the width and height of the camera), this is my own 
                                                                            // method for generating camera rays: imagine a plane that is fov_scale 
                                                                            // units from the camera pinhole/aperture, and we are drawing a ray to the 
                                                                            // centers of each of the cells on this plane -- the further away this 
                                                                            // plane gets, the more clustered the rays are, so the smaller the FOV, 
                                                                            // and vice versa for when the plane gets closer to the camera.
                                                                            // I chose to do it this way because it is very intuitive to me and 
                                                                            // incredibly easy to implement, since no rotation is involved

    vector* true_origin = new vector(0, 0, 0);                              // We will initially draw rays originating from (0, 0, 0), then translate 
                                                                            // and rotate them according to the camera's position
    vector* ray_direction = new vector((-*width / 2) + pixel_x + 0.5,        // Adding a 0.5 unit offset to position rays into the middle of each
                                       (-*height / 2) + pixel_y + 0.5,       // pixel, instead of the top-right corner without the offset
                                       *passthrough_plane_distance);
    

    ray* curr_ray = new_ray(true_origin, ray_direction);                    // Creating the initial ray, not yet conformed to the camera's orientation

    add_vectors(curr_ray->origin, cam_origin);                              // Orienting the ray to be lined up properly with the camera (translating 
                                                                            // to the camera's origin)

    // TODO: Make this into one operation, by precalculating the single matrix needed for all three rotations and only using that matrix
    rotate_x(curr_ray->direction, true_origin, *cam_normal->x);              // Rotating the ray to face the same direction as the camera -- using 
                                                                            // true_origin instead of cam_origin because the direction of the ray 
                                                                            // determines where it points from its origin, so it is not 
                                                                            // location-dependent and should therefore be rotated about (0, 0, 0)
    rotate_y(curr_ray->direction, true_origin, *cam_normal->y);
    rotate_z(curr_ray->direction, true_origin, *cam_normal->z);
    normalize(curr_ray->direction);                                         // Normalizing the ray's direction so that distances returned from intersection methods will be 
                                                                            // absolute and not scaled by the ray direction's length (the t-value, or distance, returned from the 
                                                                            // ray-plane and ray-triangle intersection methods is dependent upon the ray direction's length, so if 
                                                                            // that length is 1, the t-value returned will be the same as the Euclidean distance from the ray's 
                                                                            // origin to the intersection point)

    return curr_ray;
}


__global__ void ray_trace_kernel(double* vertices_in, double* img_out, double size, double triangles_per_thread, double img_width, double img_height) {
    int global_index = threadIdx.x + blockIdx.x * blockDim.x;
    
}


// Note: For some reason (probably a compilation bug or something), HIP seems to break when I put two identical print statements in here
// -- so don't do that!
__global__ void test_kernel() {
    printf("test kernel started\n");

    vector* cam_origin = new vector(0, 0, 0);
    vector* cam_direction = new vector(0, 0, 0);
    double fov_scale = 1;
    camera* main_cam = new_camera(cam_origin, cam_direction, fov_scale);

    int width = 10;
    int height = 10;
    int num_rays = width * height;
    dimensions* img_dimensions = new_dimensions(width, height);

    ray* main_cam_ray = generate_camera_ray(main_cam, img_dimensions, 3, 3);


    print_vector(main_cam_ray->direction);
    print_vector(new vector(1, 1, 2));
    printf("\n");

    plane* test_plane = new_plane(new vector(0, 0, 1), -1);
    bool* has_intersection = (bool*) malloc(1);
    double t = ray_plane_intersection_t(main_cam_ray, test_plane, has_intersection);
    printf("%f\n", t);

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
