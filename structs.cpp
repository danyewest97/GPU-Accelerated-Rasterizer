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
// vector methods
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

// Returns the magnitude (or length) of the given vector
__device__ double magnitude(vector* v) {
    double sum = (v->x * v->x) + (v->y * v->y) + (v->z * v->z);
    return sqrt(sum);
}

// Shortens the given vector to a length of 1
__device__ void normalize(vector* v) {
    double mag = magnitude(v);
    v->x /= mag;
    v->y /= mag;
    v->z /= mag;
}

// Returns the dot product of the two given vectors
__device__ double dot(vector* v, vector* w) {
    return (v->x * w->x) + (v->y * w->y) + (v->z * w->z);
}


// color methods


// material methods


// plane methods


// ray methods
// Returns the t-value (or distance) where the given ray intersects the given plane
// If an intersection point exists, has_intersection will be set to true, otherwise (i.e. if plane is behind ray or if plane and ray are parallel),
// has_intersection will be set to false (if there is no intersection, the function will also return 0)
// To find the intersection point, we need to plug in the ray components (parameterized using the parameter t) into the plane equation and solve.
// For the ray components to be "paramaterized," it means that the origin and direction x-, y-, and z-values are expressed in terms of a constant "t."
// Changing this "t" constant gives x-, y-, and z-values corresponding to the point along the ray that is equal to origin + t * direction.
// To express x-, y-, and z-values in terms of t: x = x0 + xt, y = y0 + yt, and z = z0 + zt, where (x0, y0, z0) is the origin and (xt, yt, zt) is the
// direction of the ray. Substituting these into the plane's equation ax + by + cz + d = 0 and solving gives us the intersection point.
__device__ double ray_plane_intersection_t(ray* r, plane* p, bool* has_intersection) {
    if (dot(r->direction, p->normal) == 0) {
        *has_intersection = false;
        return 0;
    } else {
        *has_intersection = true;
    }
    double a = p->normal->x;
    double b = p->normal->y;
    double c = p->normal->z;
    double d = p->d;

    double x0 = r->origin->x;
    double y0 = r->origin->y;
    double z0 = r->origin->z;
    
    double xt = r->direction->x;
    double yt = r->direction->y;
    double zt = r->direction->z;

    
    double left = -((a * xt) + (b * yt) + (c * zt));                    // The total t-values added up in the ray-plane equation being solved -- this 
                                                                        // is negative because we are subtracting the values from the left side of the 
                                                                        // equation to the right side of the equation
    double right = (a * x0) + (b * y0) + (c * z0) + d;                  // The total constants added up in the ray-plane equation being solved


    return right / left;
}

// triangle methods


// dimensions methods


// camera methods