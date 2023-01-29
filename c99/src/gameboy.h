#ifndef ROSETTABOY_GAMEBOY_H
#define ROSETTABOY_GAMEBOY_H

#include "apu.h"
#include "args.h"
#include "buttons.h"
#include "cart.h"
#include "clock.h"
#include "cpu.h"
#include "gpu.h"

class GameBoy {
private:
    struct Cart cart;
    struct RAM ram;
    CPU *cpu = nullptr;
    GPU *gpu = nullptr;
    struct Buttons buttons;
    struct Clock clock;

public:
    GameBoy(struct Args *args);
    void run();
    void tick();
};

#endif // ROSETTABOY_GAMEBOY_H
