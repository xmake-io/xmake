using SDL;
using SDLGraphics;

public class SDLSample : Object {

    private const int SCREEN_WIDTH = 640;
    private const int SCREEN_HEIGHT = 480;
    private const int SCREEN_BPP = 32;
    private const int DELAY = 10;

    private unowned SDL.Screen screen;
    private GLib.Rand rand;
    private bool done;

    public SDLSample () {
        this.rand = new GLib.Rand ();
    }

    public void run () {
        init_video ();

        while (!done) {
            draw ();
            process_events ();
            SDL.Timer.delay (DELAY);
        }
    }

    private void init_video () {
        uint32 video_flags = SurfaceFlag.DOUBLEBUF
                           | SurfaceFlag.HWACCEL
                           | SurfaceFlag.HWSURFACE;

        this.screen = Screen.set_video_mode (SCREEN_WIDTH, SCREEN_HEIGHT,
                                             SCREEN_BPP, video_flags);
        if (this.screen == null) {
            stderr.printf ("Could not set video mode.\n");
        }

        SDL.WindowManager.set_caption ("Vala SDL Demo", "");
    }

    private void draw () {
        int16 x = (int16) rand.int_range (0, screen.w);
        int16 y = (int16) rand.int_range (0, screen.h);
        int16 radius = (int16) rand.int_range (0, 100);
        uint32 color = rand.next_int ();

        Circle.fill_color (this.screen, x, y, radius, color);
        Circle.outline_color_aa (this.screen, x, y, radius, color);

        this.screen.flip ();
    }

    private void process_events () {
        Event event;
        while (Event.poll (out event) == 1) {
            switch (event.type) {
            case EventType.QUIT:
                this.done = true;
                break;
            case EventType.KEYDOWN:
                this.on_keyboard_event (event.key);
                break;
            }
        }
    }

    private void on_keyboard_event (KeyboardEvent event) {
        if (is_alt_enter (event.keysym)) {
            WindowManager.toggle_fullscreen (screen);
        }
    }

    private static bool is_alt_enter (Key key) {
        return ((key.mod & KeyModifier.LALT)!=0)
            && (key.sym == KeySymbol.RETURN
                    || key.sym == KeySymbol.KP_ENTER);
    }

    public static int main (string[] args) {
        SDL.init (InitFlag.VIDEO);

        var sample = new SDLSample ();
        sample.run ();

        SDL.quit ();

        return 0;
    }
}
