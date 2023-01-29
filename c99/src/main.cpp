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
    gameboy->run();

    printf("\n");
    return 0;
}
