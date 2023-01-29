#ifndef ROSETTABOY_CLOCK_H
#define ROSETTABOY_CLOCK_H

#include <SDL2/SDL.h>

#include "buttons.h"
#include "consts.h"

class Clock {
public:
    Buttons *buttons = nullptr;
    int cycle = 0;
    int frame = 0;
    int last_frame_start = SDL_GetTicks();
    int start = SDL_GetTicks();
    int frames = 0;
    int profile = 0;
    bool turbo = false;

    Clock(Buttons *buttons, int frames, int profile, bool turbo);
};

BEGIN_EXTERN_C()

void clock_tick(Clock *self);

END_EXTERN_C()

#endif // ROSETTABOY_CLOCK_H
