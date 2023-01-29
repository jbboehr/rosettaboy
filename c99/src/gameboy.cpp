#include "gameboy.h"

GameBoy::GameBoy(struct Args *args) {
    this->cart = cart_ctor(args->rom, false);
    this->ram = ram_ctor(&this->cart, args->debug_ram);
    this->cpu = new CPU(&this->ram, args->debug_cpu);
    this->gpu = gpu_ctor(this->cpu, &this->ram, this->cart.name, args->headless, args->debug_gpu);
    this->buttons = buttons_ctor(this->cpu, &this->ram, args->headless);
    if(!args->silent) {
        this->apu = new APU(this->cpu, args->debug_apu);
    }
    this->clock = clock_ctor(&this->buttons, args->frames, args->profile, args->turbo);
}

GameBoy::~GameBoy() {
    gpu_dtor(&this->gpu);
    if (this->apu) {
        apu_dtor(this->apu);
    }
}

/**
 * GB CPU runs at 4MHz, but each action takes a multiple of 4 hardware
 * cycles. So to avoid overhead, we run the main loop at 1MHz, and each
 * "cycle" that each subsystem counts represents 4 hardware cycles.
 */
void GameBoy::run() {
    while(true) {
        this->tick();
    }
}

void GameBoy::tick() {
    this->cpu->tick();
    gpu_tick(&this->gpu);
    buttons_tick(&this->buttons);
    clock_tick(&this->clock);
}
