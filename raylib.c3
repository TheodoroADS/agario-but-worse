module raylib;

/*
This is where the raylib bindings are configured
*/

alias Color = char[<4>];
alias Vector2 = float[<2>];

// Basic stuff
extern fn void init_window(int width, int height, char *title) @extern("InitWindow");
extern fn void close_window() @extern("CloseWindow");
extern fn bool window_should_close() @extern("WindowShouldClose");
extern fn void begin_drawing() @extern("BeginDrawing");
extern fn void end_drawing() @extern("EndDrawing");
extern fn void clear_background(Color color) @extern("ClearBackground");
extern fn void set_target_fps(int fps) @extern("SetTargetFPS");
extern fn float get_frame_time() @extern("GetFrameTime");

extern fn int get_screen_width() @extern("GetScreenWidth");
extern fn int get_screen_height() @extern("GetScreenHeight");

// camera
struct Camera2D {
    Vector2 offset;
    Vector2 target;
    float rotation;
    float zoom;
}

extern fn void begin_mode_2d(Camera2D camera) @extern("BeginMode2D");
extern fn void end_mode_2d() @extern("EndMode2D");

// shapes
extern fn void draw_circle_v(Vector2 center, float radius, Color color) @extern("DrawCircleV");
extern fn void draw_rectangle_v(Vector2 center, Vector2 size, Color color) @extern("DrawRectangleV");

// text
extern fn int measure_text(char* text, int fontsize) @extern("MeasureText");
extern fn void draw_text(char* text, int posX, int posY, int fontSize, Color color) @extern("DrawText");

// keys
extern fn bool is_key_down(int key) @extern("IsKeyDown");

// I define here only the keys I need. Maybe I should use an enum ?
const int KEY_A = 65;
const int KEY_S = 83;
const int KEY_D = 68;
const int KEY_W = 87;
const int KEY_RIGHT = 262;
const int KEY_LEFT = 263;
const int KEY_DOWN = 264;
const int KEY_UP = 265;

// utils
extern fn int get_random_value(int min, int max) @extern("GetRandomValue");
