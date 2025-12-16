#include <raylib.h>
#include <android/log.h>

#define LOG_TAG "raydemo"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)

int main(int argc, char** argv) {
    InitWindow(0, 0, "Hello, xmake for raylib android!");
    SetTargetFPS(60);
    LOGI("raylib application is running!");

    while (!WindowShouldClose()) {
        BeginDrawing();
        ClearBackground(BLACK);
        DrawText("Hello, xmake for raylib android!", 250, 250, 25, BLUE);
        EndDrawing();
    }

    CloseWindow();
    return 0;
}
