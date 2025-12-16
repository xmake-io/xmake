#ifndef _ANDROID_NATIVE_APP_GLUE_H
#define _ANDROID_NATIVE_APP_GLUE_H

#include <poll.h>
#include <pthread.h>
#include <sched.h>

#include <android/native_activity.h>
#include <android/looper.h>
#include <android/configuration.h>
#include <android/rect.h>
#include <android/native_window.h>
#include <android/input.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * The native activity interface provided by <android/native_activity.h>
 * is based on a set of application-provided callbacks that will be called
 * by the Activity's main thread when certain events occur.
 *
 * This means that each one of this callbacks _should_ _not_ block, or they
 * risk having the system force-close the application. This programming
 * model is direct, lightweight, but constraining.
 *
 * The 'threaded_native_app' static library is used to provide a different
 * execution model where the application can implement its own main event
 * loop in a different thread instead. Here's how it works:
 *
 * 1/ The application must provide a function named "android_main()" that
 *    will be called when the activity is created, in a new thread that is
 *    distinct from the activity's main thread.
 *
 * 2/ android_main() receives a pointer to a valid "android_app" structure
 *    that contains references to other important objects, e.g. the
 *    ANativeActivity obejct instance the application is running in.
 *
 * 3/ the "android_app" object holds an ALooper instance that already
 *    listens to two important things:
 *
 *      - activity lifecycle events (e.g. "pause", "resume"). See APP_CMD_XXX
 *        declarations below.
 *
 *      - input events coming from the AInputQueue attached to the activity.
 *
 *    Each of these correspond to an ALooper callback that returns a "data"
 *    value of LOOPER_ID_MAIN and LOOPER_ID_EVENT, respectively.
 *
 *    Your application can use the same ALooper to listen to additionnal
 *    file-descriptors.
 *
 * 4/ Whenever you receive a LOOPER_ID_MAIN event from the ALooper, your
 *    code should call the function android_app_read_cmd() to read the
 *    command value and act upon it. This is normally done by calling
 *    android_app_exec_cmd() directly.
 *
 *    XXX: MAKE THIS STUFF MORE CLEAR !!
 *
 * 5/ Whenever you receive a LOOPER_ID_EVENT event from the ALooper, you
 *    should read one event from the AInputQueue with AInputQueue_getEvent().
 *
 * See the sample named "native-activity" that comes with the NDK with a
 * full usage example.
 *
 */

/**
 * Data associated with an ALooper fd that will be returned as the "outData"
 * when that source has data ready.
 */
struct android_poll_source {
    // The identifier of this source.  May be LOOPER_ID_MAIN or
    // LOOPER_ID_EVENT.
    int32_t id;

    // The android_app structure associated with this source.
    struct android_app* app;

    // Function to call to process this source when data is available.
    void (*process)(struct android_app* app, struct android_poll_source* source);
};

struct android_app {
    // The application can place a pointer to its own state object
    // here if it likes.
    void* userData;

    // Fill this in with the function to process main app commands (APP_CMD_*)
    void (*onAppCmd)(struct android_app* app, int32_t cmd);

    // Fill this in with the function to process input events.  At this point
    // the event has already been pre-dispatched, and it will be finished upon
    // return.  Return 1 if you have handled the event, 0 for any default
    // dispatching.
    int32_t (*onInputEvent)(struct android_app* app, AInputEvent* event);

    // The ANativeActivity object instance that this app is running in.
    ANativeActivity* activity;

    // The current configuration the app is running in.
    AConfiguration* config;

    // The last saved state that was given at creation time.
    void* savedState;
    size_t savedStateSize;

    // The ALooper associated with the app's thread.
    ALooper* looper;

    // When non-NULL, this is the input queue from which the app will
    // receive user input events.
    AInputQueue* inputQueue;

    // When non-NULL, this is the window surface that the app can draw in.
    ANativeWindow* window;

    // Current content rectangle of the window; this is the area where the
    // window's content should be placed to be seen by the user.
    ARect contentRect;

    // Current state of the app's activity.  May be either APP_CMD_START,
    // APP_CMD_RESUME, APP_CMD_PAUSE, or APP_CMD_STOP; see below.
    int activityState;

    // This is non-zero when the application's NativeActivity is being
    // destroyed and waiting for the app thread to complete.
    int destroyRequested;

    // -------------------------------------------------
    // Below are "private" implementation of the glue code.

    pthread_mutex_t mutex;
    pthread_cond_t cond;

    int msgread;
    int msgwrite;

    pthread_t thread;

    struct android_poll_source cmdPollSource;
    struct android_poll_source inputPollSource;

    int running;
    int stateSaved;
    int destroyed;
    int redrawNeeded;
    AInputQueue* pendingInputQueue;
    ANativeWindow* pendingWindow;
    ARect pendingContentRect;
};

enum {
    /**
     * Looper data ID of commands coming from the app's main thread.
     * These can be retrieved and processed with android_app_read_cmd()
     * and android_app_exec_cmd().
     */
    LOOPER_ID_MAIN = 1,

    /**
     * Looper data ID of events coming from the AInputQueue of the
     * application's window.  These can be read via the inputQueue
     * object of android_app.
     */
    LOOPER_ID_EVENT = 2,

    /**
     * Looper data ID of events coming from the AInputQueue of the
     * application's window.  These can be read via the inputQueue
     * object of android_app.
     */
    LOOPER_ID_USER = 3,
};

enum {
    APP_CMD_INPUT_CHANGED,
    APP_CMD_INIT_WINDOW,
    APP_CMD_TERM_WINDOW,
    APP_CMD_WINDOW_RESIZED,
    APP_CMD_WINDOW_REDRAW_NEEDED,
    APP_CMD_CONTENT_RECT_CHANGED,
    APP_CMD_GAINED_FOCUS,
    APP_CMD_LOST_FOCUS,
    APP_CMD_CONFIG_CHANGED,
    APP_CMD_LOW_MEMORY,
    APP_CMD_START,
    APP_CMD_RESUME,
    APP_CMD_SAVE_STATE,
    APP_CMD_PAUSE,
    APP_CMD_STOP,
    APP_CMD_DESTROY,
};

/**
 * Call when ALooper_pollAll() returns LOOPER_ID_MAIN, reading the next
 * app command message.
 */
int8_t android_app_read_cmd(struct android_app* android_app);

/**
 * Call with the command returned by android_app_read_cmd() to do the
 * initial pre-processing of the given command.  You can use this for
 * your own normal default behavior for the command, and then inspect
 * it yourself to do your own processing.  This function may block for
 * certain commands (e.g. to wait for the app's graphics context to be
 * initialized) and will returns true if it blocked.
 */
void android_app_pre_exec_cmd(struct android_app* android_app, int8_t cmd);

/**
 * Call with the command returned by android_app_read_cmd() to do the
 * final post-processing of the given command.  You must have first called
 * android_app_pre_exec_cmd() before calling this function.
 */
void android_app_post_exec_cmd(struct android_app* android_app, int8_t cmd);

/**
 * Dummy function you can call to ensure glue code isn't stripped.
 */
void app_dummy();

/**
 * This is the function that application code must implement, representing
 * the main entry to the app.
 */
extern void android_main(struct android_app* app);

#ifdef __cplusplus
}
#endif

#endif /* _ANDROID_NATIVE_APP_GLUE_H */
