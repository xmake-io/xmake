#if !defined(PACKAGE_PUBLIC) || !defined(PACKAGE_PRIVATE)
#error Missing direct package flags
#endif
#ifdef PACKAGE_INTERFACE
#error Interface-only package flags must not affect the producer
#endif
int answer() { return 42; }
