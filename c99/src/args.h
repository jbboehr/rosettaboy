#ifndef ROSETTABOY_ARGS_H
#define ROSETTABOY_ARGS_H

#include <stdbool.h>
#include "common.h"

BEGIN_EXTERN_C()

struct Args {
    int exit_code;
    bool headless;
    bool silent;
    bool debug_cpu;
    bool debug_gpu;
    bool debug_apu;
    bool debug_ram;
    int frames;
    int profile;
    bool turbo;
    const char *rom;
};

struct Args parse_args(int argc, char *argv[]);

END_EXTERN_C()

#endif // ROSETTABOY_ARGS_H
