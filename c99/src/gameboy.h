#ifndef ROSETTABOY_GAMEBOY_H
#define ROSETTABOY_GAMEBOY_H

#include "common.h"
#include "apu.h"
#include "args.h"
#include "buttons.h"
#include "cart.h"
#include "clock.h"
#include "cpu.h"
#include "gpu.h"
#include "ram.h"

struct GameBoy {
    struct Cart cart;
    struct RAM ram;
    struct CPU cpu;
    struct APU apu;
    struct GPU gpu;
    struct Buttons buttons;
    struct Clock clock;
};

BEGIN_EXTERN_C()

void gameboy_ctor(struct GameBoy *self, struct Args *args);
void gameboy_run(struct GameBoy *self);
void gameboy_dtor(struct GameBoy *self);

END_EXTERN_C()

#endif // ROSETTABOY_GAMEBOY_H
