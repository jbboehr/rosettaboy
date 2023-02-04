#include "gameboy.h"

void gameboy_ctor(struct GameBoy *self, struct Args *args) {
    self->cart = cart_ctor(args->rom, false);
    self->ram = ram_ctor(&self->cart, args->debug_ram);
    self->cpu = cpu_ctor(&self->ram, args->debug_cpu);
    self->gpu = gpu_ctor(&self->cpu, &self->ram, self->cart.name, args->headless, args->debug_gpu);
    self->buttons = buttons_ctor(&self->cpu, &self->ram, args->headless);
    if (!args->silent) {
        apu_ctor(&self->apu, &self->cpu, &self->ram, args->debug_apu);
    }
    self->clock = clock_ctor(&self->buttons, args->frames, args->profile, args->turbo);
}

void gameboy_dtor(struct GameBoy *self) {
    gpu_dtor(&self->gpu);
    apu_dtor(&self->apu);
}

static inline void gameboy_tick(struct GameBoy *self) {
    cpu_tick(&self->cpu);
    gpu_tick(&self->gpu);
    buttons_tick(&self->buttons);
    clock_tick(&self->clock);
}

/**
 * GB CPU runs at 4MHz, but each action takes a multiple of 4 hardware
 * cycles. So to avoid overhead, we run the main loop at 1MHz, and each
 * "cycle" that each subsystem counts represents 4 hardware cycles.
 */
void gameboy_run(struct GameBoy *self) {
    while (true) {
        gameboy_tick(self);
    }
}
