#ifndef ROSETTABOY_GPU_H
#define ROSETTABOY_GPU_H

#include <SDL2/SDL.h>

#include "cpu.h"

struct Sprite {
    u8 y;
    u8 x;
    u8 tile_id;
    union {
        u8 flags;
        struct {
            unsigned char _empty : 4;
            unsigned char palette : 1;
            unsigned char x_flip : 1;
            unsigned char y_flip : 1;
            unsigned char behind : 1;
        };
    };

    bool is_live();
};

class GPU {
private:
    bool debug;
    SDL_Window *hw_window;
    SDL_Texture *hw_buffer;
    SDL_Renderer *hw_renderer;
    SDL_Surface *buffer;
    SDL_Renderer *renderer;
    SDL_Color colors[4];
    SDL_Color bgp[4], obp0[4], obp1[4];
    int cycle;
    CPU *cpu;

public:
    GPU(CPU *cpu, char *title, bool headless, bool debug);
    ~GPU();
    void tick();

private:
    void update_palettes();
    void draw_debug();
    void draw_line(i32 ly);
    void paint_tile(i16 tile_id, SDL_Point *offset, SDL_Color *palette, bool flip_x, bool flip_y);
    void paint_tile_line(i16 tile_id, SDL_Point *offset, SDL_Color *palette, bool flip_x, bool flip_y, i32 y);
};

SDL_Color gen_hue(u8 n);

#endif // ROSETTABOY_GPU_H
