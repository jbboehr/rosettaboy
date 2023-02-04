#ifndef ROSETTABOY_BUTTONS_H
#define ROSETTABOY_BUTTONS_H

#include <SDL2/SDL.h>
#include "consts.h"

struct CPU;
struct RAM;

struct Buttons {
    u32 cycle;
    struct CPU *cpu;
    struct RAM *ram;
    bool up;
    bool down;
    bool left;
    bool right;
    bool a;
    bool b;
    bool start;
    bool select;
    bool turbo;
};

struct Buttons buttons_ctor(struct CPU *cpu, struct RAM *ram, bool headless);
void buttons_tick(struct Buttons *self);

#endif // ROSETTABOY_BUTTONS_H
