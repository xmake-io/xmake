#if !defined(PACKAGE_PUBLIC) || !defined(PACKAGE_INTERFACE)
#error Missing transitive public/interface package flags
#endif
#ifdef PACKAGE_PRIVATE
#error Private package flags leaked to the consumer
#endif
int answer();
int main() { return answer() == 42 ? 0 : 1; }
