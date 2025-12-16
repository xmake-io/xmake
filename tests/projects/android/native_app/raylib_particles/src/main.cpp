#include <raylib.h>
#include <android/log.h>
#include <vector>
#include <cmath>

#define LOG_TAG "raydemo_particles"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)

struct Particle {
    Vector2 position;
    Vector2 velocity;
    Color color;
    float size;
    float life;
};

int main(int argc, char** argv) {
    InitWindow(0, 0, "Raylib Particles");
    SetTargetFPS(60);
    LOGD("raylib particles starting!");

    std::vector<Particle> particles;

    while (!WindowShouldClose()) {
        // Update
        bool inputActive = IsMouseButtonDown(MOUSE_BUTTON_LEFT) || GetTouchPointCount() > 0;
        Vector2 pos;

        if (inputActive) {
            pos = GetMousePosition();
            if (GetTouchPointCount() > 0) pos = GetTouchPosition(0);
        } else {
            // Auto emit when idle
            double time = GetTime();
            pos.x = GetScreenWidth() / 2.0f + cos(time * 3.0f) * (GetScreenWidth() / 4.0f);
            pos.y = GetScreenHeight() / 2.0f + sin(time * 2.0f) * (GetScreenHeight() / 4.0f);
        }

        if (inputActive || GetRandomValue(0, 100) < 50) {
            int count = inputActive ? 5 : 2;
            for (int i = 0; i < count; i++) {
                Particle p;
                p.position = pos;
                p.velocity = {(float)GetRandomValue(-200, 200) / 100.0f, (float)GetRandomValue(-200, 200) / 100.0f};
                p.color = (Color){(unsigned char)GetRandomValue(0, 255), (unsigned char)GetRandomValue(0, 255), (unsigned char)GetRandomValue(0, 255), 255};
                p.size = (float)GetRandomValue(5, 20);
                p.life = 1.0f;
                particles.push_back(p);
            }
        }

        for (auto it = particles.begin(); it != particles.end();) {
            it->position.x += it->velocity.x * 5.0f;
            it->position.y += it->velocity.y * 5.0f;
            it->life -= 0.02f;
            it->size *= 0.99f;

            if (it->life <= 0) {
                it = particles.erase(it);
            } else {
                ++it;
            }
        }

        // Draw
        BeginDrawing();
        ClearBackground(BLACK);
        
        for (const auto& p : particles) {
            DrawCircleV(p.position, p.size, Fade(p.color, p.life));
        }
        
        DrawText("Touch to create particles!", 10, 40, 20, WHITE);
        DrawFPS(10, 10);

        EndDrawing();
    }

    CloseWindow();
    return 0;
}
