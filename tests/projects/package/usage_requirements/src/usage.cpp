#if !defined(__AVX2__) && !defined(_M_AVX2) && !defined(__AVX2)
#    error AVX2 is required by the package
#endif

int usage() {
    return 0;
}
