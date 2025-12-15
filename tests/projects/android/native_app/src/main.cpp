#include <raylib.h>

int main() {
  InitWindow(0, 0, "Hello, xmake for raylib android!");

  SetTargetFPS(60);

  while (!WindowShouldClose()) {  // Main game loop
    BeginDrawing();

    ClearBackground(BLACK);

    DrawText("Hello, xmake for raylib android!", 250, 250, 25, BLUE);

    EndDrawing();
  }

  CloseWindow();

  return 0;
}