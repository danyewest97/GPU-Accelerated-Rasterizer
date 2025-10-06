// This file contains array methods for various array types in use
// I am declaring arrays as their own structs instead of just making arrays/pointers to implement bounds-checking, among other things. Normally, C++
// doesn't check bounds when accessing a pointer, because C++ doesn't actually know how long a given pointer is -- it just knows the starting memory 
// address that the pointer, well, points to
// Not currently in use
struct double_array {
    double* items;                      // The actual data of the array itself
    int length;                         // The length of the array -- pretty self-explanatory
    int capacity;                       // The maximum number of items that the array can hold
};