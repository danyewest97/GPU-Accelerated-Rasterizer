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
struct triangle {
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


// // Constructors for above-defined structs
// vector constructor
__device__ vector* new_vector(double x, double y, double z) {
    vector* v = (vector*) malloc(sizeof(vector));
    v->x = x;
    v->y = y;
    v->z = z;
    return v;
}

// color constructor
__device__ color* new_color(double r, double g, double b) {
    color* c = (color*) malloc(sizeof(color));
    c->r = r;
    c->g = g;
    c->b = b;
    return c;
}

// material constructor
__device__ material* new_material(color* material_color, double absorption, double reflection, double transmission, double diffusion) {
    material* m = (material*) malloc(sizeof(material));
    m->material_color = *material_color;
    m->absorption = absorption;
    m->reflection = reflection;
    m->transmission = transmission;
    m->diffusion = diffusion;
    return m;
}

// plane constructor
__device__ plane* new_plane(vector* normal, double d) {
    plane* p = (plane*) malloc(sizeof(plane));
    p->normal = *normal;
    p->d = d;
    return p;
}

// ray constructor
__device__ ray* new_ray(vector* origin, vector* direction) {
    ray* r = (ray*) malloc(sizeof(ray));
    r->origin = *origin;
    r->direction = *direction;
    return r;
}

// triangle constructor
__device__ triangle* new_triangle(plane* surface_plane, material* surface_material, vector* a, vector* b, vector* c) {
    triangle* t = (triangle*) malloc(sizeof(triangle));
    t->surface_plane = *surface_plane;
    t->surface_material = *surface_material;
    t->a = *a;
    t->b = *b;
    t->c = *c;
    return t;
}

// dimensions constructor
__device__ dimensions* new_dimensions(double width, double height) {
    dimensions* d = (dimensions*) malloc(sizeof(dimensions));
    d->width = width;
    d->height = height;
    return d;
}

// camera constructor
__device__ camera* new_camera(vector* origin, vector* rotation, double vfov, double hfov) {
    camera* c = (camera*) malloc(sizeof(camera));
    c->origin = *origin;
    c->rotation = *rotation;
    c->vfov = vfov;
    c->hfov = hfov;
    return c;
}


// Cloning methods
__device__ vector* clone_vector(vector* v) {
    return new_vector(v->x, v->y, v->z);
}
