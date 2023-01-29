#include "clock.h"
#include "errors.h"

Clock::Clock(Buttons *buttons, int frames, int profile, bool turbo) {
    this->buttons = buttons;
    this->frames = frames;
    this->profile = profile;
    this->turbo = turbo;
}

void clock_tick(Clock *self) {
    self->cycle++;

    // Do a whole frame's worth of sleeping at the start of each frame
    if(self->cycle % 17556 == 20) {
        // Sleep if we have time left over
        u32 time_spent = (SDL_GetTicks() - self->last_frame_start);
        i32 sleep_for = (1000 / 60) - time_spent;
        if(sleep_for > 0 && !self->turbo && !self->buttons->turbo) {
            SDL_Delay(sleep_for);
        }
        self->last_frame_start = SDL_GetTicks();

        // Exit if we've hit the frame or time limit
        auto duration = (double)(self->last_frame_start - self->start) / 1000.0;
        if((self->frames != 0 && self->frame >= self->frames) || (self->profile != 0 && duration >= self->profile)) {
            timeout_err(self->frame, duration);
        }

        self->frame++;
    }
}