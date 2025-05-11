import hello;

int main() {
  hello::say s(sizeof(hello::say));
  s.hello();
  return 0;
}
