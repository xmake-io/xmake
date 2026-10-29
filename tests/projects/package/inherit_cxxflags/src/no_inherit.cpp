#if defined(PACKAGE_PUBLIC) || defined(PACKAGE_PRIVATE) || defined(PACKAGE_INTERFACE)
#error Package flags must respect inherit=false
#endif
int main() { return 0; }
