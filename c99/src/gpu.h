#ifndef ROSETTABOY_GPU_H
#define ROSETTABOY_GPU_H

#include <SDL2/SDL.h>

#include "common.h"
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
};

class GPU {
public:
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
};

BEGIN_EXTERN_C()

void gpu_tick(GPU *self);

END_EXTERN_C()

#endif // ROSETTABOY_GPU_H
