#ifndef PACKAGE_OVERRIDE
#error Missing overridden package flags
#endif
#ifdef PACKAGE_PUBLIC
#error Package configuration override was ignored
#endif
int main() { return 0; }
