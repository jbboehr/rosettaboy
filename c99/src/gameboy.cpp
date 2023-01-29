#include "gameboy.h"

GameBoy::GameBoy(struct Args *args) {
    this->cart = cart_ctor(args->rom, false);
    this->ram = ram_ctor(&this->cart, args->debug_ram);
    this->cpu = cpu_ctor(&this->ram, args->debug_cpu);
    this->gpu = gpu_ctor(&this->cpu, &this->ram, this->cart.name, args->headless, args->debug_gpu);
    this->buttons = buttons_ctor(&this->cpu, &this->ram, args->headless);
    if(!args->silent) {
        apu_ctor(&this->apu, &this->cpu, &this->ram, args->debug_apu);
    }
    this->clock = clock_ctor(&this->buttons, args->frames, args->profile, args->turbo);
}

void gameboy_dtor(GameBoy *self) {
    gpu_dtor(&self->gpu);
    apu_dtor(&self->apu);
}

static inline void gameboy_tick(GameBoy *self) {
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
void gameboy_run(GameBoy *self) {
    while(true) {
        gameboy_tick(self);
    }
}
