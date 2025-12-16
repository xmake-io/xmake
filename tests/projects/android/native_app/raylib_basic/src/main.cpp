#include <raylib.h>
#include <android/log.h>

#define LOG_TAG "raydemo_basic"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)

int main(int argc, char** argv) {
    InitWindow(0, 0, "Hello, xmake for raylib android!");
    SetTargetFPS(60);
    LOGI("raylib application is running!");

    while (!WindowShouldClose()) {
        BeginDrawing();
        ClearBackground(BLACK);

        // Draw FPS
        const char* fpsText = TextFormat("%2i FPS", GetFPS());
        int fpsWidth = MeasureText(fpsText, 40);
        DrawText(fpsText, GetScreenWidth() / 2 - fpsWidth / 2, 30, 40, GREEN);

        // Draw centered text
        int fontSize = 50;
        const char* text = "Hello, xmake for raylib android!";
        int textWidth = MeasureText(text, fontSize);
        DrawText(text, GetScreenWidth() / 2 - textWidth / 2, 100, fontSize, BLUE);

        EndDrawing();
    }

    CloseWindow();
    return 0;
}
