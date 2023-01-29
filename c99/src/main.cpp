#include "args.h"
#include "errors.h"
#include "gameboy.h"
#include <iostream>

int main(int argc, char *argv[]) {
    struct Args args = parse_args(argc, argv);

    if (args.exit_code > 0) {
        return args.exit_code;
    }

    GameBoy *gameboy = new GameBoy(&args);
    gameboy_run(gameboy);
    gameboy_dtor(gameboy);

    printf("\n");
    return 0;
}
