// A library file with all of the required structs and their constructors, plus some methods to use on them

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
    color* material_color;
    double absorption, reflection, transmission, diffusion;
};

// A 3D plane with components a, b, c, d, expressed by equation ax + by + cz + d = 0
struct plane {
    vector* normal;                      // vector to store the components of the plane's normal as (a, b, c)
    double d;
};

// A 3D Ray that starts from the 3D point origin and points in the direction given by the direction vector
struct ray {
    vector* origin;
    vector* direction;
};

// A 3D triangle defined by the 3 vectors a, b, and c, with the given material and plane
struct triangle {
    plane* surface_plane;                // the 3D plane that the triangle sits on
    material* surface_material;          // the material that the triangle is "made out of," defining how light rays should interact with the triangle
    vector* a;
    vector* b;
    vector* c;
};

// A container to hold the height and width of an image (or anything else with height and width)
struct dimensions {
    int width, height;
};

// 3D camera, defines where the camera rays originate and in which direction they radiate, to control where the viewport is looking
struct camera {
    vector* origin;                      // The 3D point where all camera rays originate from
    vector* rotation;                    // The direction where camera rays radiate from the origin, with components (x_rotation, y_rotation, 
                                        // z_rotation)
    double fov_scale;                  // The field-of-view parameters, expressed in radians, that define how far left/right or up/down the camera 
                                        // can see
};


// // Constructors for above-defined structs
// vector constructor
__device__ vector* new_vector(double x, double y, double z) {
    vector* v = new vector[1];
    v[0] = {x, y, z};
    return v;
}

// color constructor
__device__ color* new_color(double r, double g, double b) {
    color* c = new color[1];
    c[0] = {r, g, b};
    return c;
}

// material constructor
__device__ material* new_material(color* material_color, double absorption, double reflection, double transmission, double diffusion) {
    material* m = new material[1];
    m[0] = {material_color, absorption, reflection, transmission, diffusion};
    return m;
}

// plane constructor
__device__ plane* new_plane(vector* normal, double d) {
    plane* p = new plane[1];
    p[0] = {normal, d};
    return p;
}

// ray constructor
__device__ ray* new_ray(vector* origin, vector* direction) {
    ray* r = new ray[1];
    r[0] = {origin, direction};
    return r;
}

// triangle constructor
__device__ triangle* new_triangle(plane* surface_plane, material* surface_material, vector* a, vector* b, vector* c) {
    triangle* t = new triangle[1];
    t[0] = {surface_plane, surface_material, a, b, c};
    return t;
}

// dimensions constructor
__device__ dimensions* new_dimensions(int width, int height) {
    dimensions* d = new dimensions[1];
    d[0] = {width, height};
    return d;
}

// camera constructor
__device__ camera* new_camera(vector* origin, vector* rotation, double fov_scale) {
    camera* c = new camera[1];
    c[0] = {origin, rotation, fov_scale};
    return c;
}


// Cloning methods
__device__ vector* clone_vector(vector* v) {
    return new_vector(v->x, v->y, v->z);
}



// Print methods for debugging
__device__ void print_vector(vector* v) {
    printf("(%f, %f, %f)", v->x, v->y, v->z);
}









// // Custom methods for structs
// Vector methods
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