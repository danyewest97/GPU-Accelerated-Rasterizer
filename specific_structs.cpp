// A library file with all of the required more-specific structs and their constructors, plus some methods to use on them -- Mostly structs that are 
// only needed to couple certain specific datatypes together, without any methods to act on them

// A collision class to hold all the necessary information about 
struct collision {
    triangle* collision_triangle;
    color* collision_color;
    vector* collision_point;
    double* collision_distance;
};
