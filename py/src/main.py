#!/usr/bin/env python3

import sdl2
import sys
from typing import List

from .args import parse_args
from .gameboy import GameBoy
from .errors import (
    GameException,
    UserException,
    ControlledExit,
    UnitTestFailed,
    EmuError,
)


def main(argv: List[str]) -> int:
    args = parse_args(argv[1:])

    try:
        gameboy = GameBoy(args)
        gameboy.run()
    except EmuError as e:
        print(e)
        if isinstance(e, UnitTestFailed):
            return 2
        if isinstance(e, ControlledExit):
            return 0
        if isinstance(e, GameException):
            return 3
        if isinstance(e, UserException):
            return 4
    except (KeyboardInterrupt, BrokenPipeError):
        pass
    finally:
        sdl2.SDL_Quit()

    return 0


def cli_main():
    sys.exit(main(sys.argv))


if __name__ == "__main__":
    cli_main()
