#include <lvgl/lvgl.h>
#include <android/native_window.h>
#include <android/log.h>
#include <android_native_app_glue.h>
#include <time.h>
#include <stdlib.h>
#include <unistd.h>

#define LOG_TAG "lvgl_basic"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)

static lv_display_t * display = NULL;
static ANativeWindow * native_window = NULL;
static int32_t window_width = 0;
static int32_t window_height = 0;

static bool touch_down = false;
static int32_t touch_x = 0;
static int32_t touch_y = 0;

static void my_flush_cb(lv_display_t * disp, const lv_area_t * area, uint8_t * px_map) {
    if (!native_window) {
        lv_display_flush_ready(disp);
        return;
    }

    ANativeWindow_Buffer buffer;
    if (ANativeWindow_lock(native_window, &buffer, NULL) < 0) {
        lv_display_flush_ready(disp);
        return;
    }

    int32_t width = lv_area_get_width(area);
    int32_t height = lv_area_get_height(area);

    // Assume 32-bit RGBA
    uint32_t * dst_base = (uint32_t *)buffer.bits;
    uint32_t * src = (uint32_t *)px_map;
    int stride = buffer.stride;

    for (int y = 0; y < height; y++) {
        uint32_t * dst_line = dst_base + (area->y1 + y) * stride + area->x1;
        memcpy(dst_line, src + y * width, width * sizeof(uint32_t));
    }

    ANativeWindow_unlockAndPost(native_window);
    lv_display_flush_ready(disp);
}

static void my_input_read(lv_indev_t * indev, lv_indev_data_t * data) {
    data->point.x = touch_x;
    data->point.y = touch_y;
    data->state = touch_down ? LV_INDEV_STATE_PRESSED : LV_INDEV_STATE_RELEASED;
}

static void create_ui(void) {
    lv_obj_t * label = lv_label_create(lv_screen_active());
    lv_label_set_text(label, "Hello Xmake + LVGL!");
    lv_obj_set_style_text_font(label, &lv_font_montserrat_14, 0);
    lv_obj_align(label, LV_ALIGN_TOP_MID, 0, 50);

    // FPS label
    lv_obj_t * label_fps = lv_label_create(lv_screen_active());
    lv_label_set_text(label_fps, "FPS: 0");
    lv_obj_set_style_text_font(label_fps, &lv_font_montserrat_14, 0);
    lv_obj_align(label_fps, LV_ALIGN_TOP_MID, 0, 100);
}

static void handle_cmd(struct android_app* app, int32_t cmd) {
    switch (cmd) {
        case APP_CMD_INIT_WINDOW:
            LOGI("Init Window");
            native_window = app->window;
            window_width = ANativeWindow_getWidth(native_window);
            window_height = ANativeWindow_getHeight(native_window);
            ANativeWindow_setBuffersGeometry(native_window, window_width, window_height, WINDOW_FORMAT_RGBA_8888);

            if (!display) {
                display = lv_display_create(window_width, window_height);
                lv_display_set_color_format(display, LV_COLOR_FORMAT_ARGB8888);
                lv_display_set_flush_cb(display, my_flush_cb);

                size_t buf_size = window_width * window_height * 4;
                void * buf = malloc(buf_size);
                lv_display_set_buffers(display, buf, NULL, buf_size, LV_DISPLAY_RENDER_MODE_FULL);

                lv_indev_t * indev = lv_indev_create();
                lv_indev_set_type(indev, LV_INDEV_TYPE_POINTER);
                lv_indev_set_read_cb(indev, my_input_read);

                create_ui();
            } else {
                 lv_display_set_resolution(display, window_width, window_height);
                 lv_obj_invalidate(lv_scr_act());
            }
            break;
        case APP_CMD_TERM_WINDOW:
            native_window = NULL;
            break;
    }
}

static int32_t handle_input(struct android_app* app, AInputEvent* event) {
    if (AInputEvent_getType(event) == AINPUT_EVENT_TYPE_MOTION) {
        int action = AMotionEvent_getAction(event) & AMOTION_EVENT_ACTION_MASK;
        touch_x = AMotionEvent_getX(event, 0);
        touch_y = AMotionEvent_getY(event, 0);
        if (action == AMOTION_EVENT_ACTION_DOWN || action == AMOTION_EVENT_ACTION_MOVE) {
            touch_down = true;
        } else {
            touch_down = false;
        }
        return 1;
    }
    return 0;
}

void android_main(struct android_app* app) {
    lv_init();

    app->onAppCmd = handle_cmd;
    app->onInputEvent = handle_input;

    int frame_count = 0;
    time_t last_time = time(NULL);

    while (1) {
        int ident;
        int events;
        struct android_poll_source* source;

        uint32_t timeout = lv_timer_handler();
        if (timeout > 50) timeout = 50;

        while ((ident = ALooper_pollAll(timeout, NULL, &events, (void**)&source)) >= 0) {
            if (source != NULL) source->process(app, source);
            if (app->destroyRequested != 0) return;
        }

        lv_tick_inc(timeout);

        frame_count++;
        time_t current_time = time(NULL);
        if (current_time - last_time >= 1) {
             lv_obj_t * label_fps = lv_obj_get_child(lv_screen_active(), 1); // 0: label, 1: fps
             if (label_fps) {
                 lv_label_set_text_fmt(label_fps, "FPS: %d", frame_count);
             }
             frame_count = 0;
             last_time = current_time;
        }
    }
}
