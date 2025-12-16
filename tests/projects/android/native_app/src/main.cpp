#include <raylib.h>

int main(int argc, char** argv) {
    InitWindow(0, 0, "Hello, xmake for raylib android!");
    SetTargetFPS(60);

    while (!WindowShouldClose()) {
        BeginDrawing();
        ClearBackground(BLACK);
        DrawText("Hello, xmake for raylib android!", 250, 250, 25, BLUE);
        EndDrawing();
    }

    CloseWindow();
    return 0;
}
