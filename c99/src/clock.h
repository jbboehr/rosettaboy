#ifndef ROSETTABOY_CLOCK_H
#define ROSETTABOY_CLOCK_H

#include <stdbool.h>

BEGIN_EXTERN_C()

struct Buttons;

struct Clock {
    struct Buttons *buttons;
    int cycle;
    int frame;
    int last_frame_start;
    int start;
    int frames;
    int profile;
    bool turbo;
};

struct Clock clock_ctor(struct Buttons *buttons, int frames, int profile, bool turbo);
void clock_tick(struct Clock *self);

END_EXTERN_C()

#endif // ROSETTABOY_CLOCK_H
