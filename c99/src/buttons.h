#ifndef ROSETTABOY_BUTTONS_H
#define ROSETTABOY_BUTTONS_H

#include <SDL2/SDL.h>

#include "consts.h"
#include "cpu.h"

class Buttons {
public:
    u32 cycle = 0;
    CPU *cpu = nullptr;
    bool up = false;
    bool down = false;
    bool left = false;
    bool right = false;
    bool a = false;
    bool b = false;
    bool start = false;
    bool select = false;
    bool turbo = false;

    Buttons(CPU *cpu, bool headless);
    void tick();
};

#endif // ROSETTABOY_BUTTONS_H
