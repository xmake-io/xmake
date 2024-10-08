#if defined(FOO)
import foo;
using namespace foo;
#else
import bar;
using namespace bar;
#endif

int main() {
  hello();
  return 0;
}
