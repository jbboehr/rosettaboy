
#include "args.h"

#include <getopt.h>
#include <stdio.h>
#include <stdlib.h>

NORETURN static void print_usage(void) {
    fprintf(stdout, "Usage: rosettaboy-c [OPTION]... [ROM]\n"
                    "Example: rosettaboy-c --turbo opus5.gb\n"
                    "\n"
                    "Options:\n"
                    "  -h, --help              Display this help menu\n"
                    "  -H, --headless          Disable GUI\n"
                    "  -S, --silent            Disable Sound\n"
                    "  -c, --debug-cpu         Debug CPU\n"
                    "  -g, --debug-gpu         Debug GPU\n"
                    "  -a, --debug-apu         Debug APU\n"
                    "  -r, --debug-ram         Debug RAM\n"
                    "  -f, --frames=FRAMES     Exit after N frames\n"
                    "  -p, --profile=PROFILE   Exit after N seconds\n"
                    "  -t, --turbo             No sleep between frames\n");
    exit(0);
}

static struct option long_options[] = {{"help", no_argument, 0, 'h'},
                                       {"headless", no_argument, 0, 'H'},
                                       {"silent", no_argument, 0, 'S'},
                                       {"debug-cpu", no_argument, 0, 'c'},
                                       {"debug-gpu", no_argument, 0, 'g'},
                                       {"debug-apu", no_argument, 0, 'a'},
                                       {"debug-ram", no_argument, 0, 'r'},
                                       {"frames", required_argument, 0, 'f'},
                                       {"profile", required_argument, 0, 'p'},
                                       {"turbo", no_argument, 0, 't'},
                                       {0, 0, 0, 0}};

struct Args parse_args(int argc, char *argv[]) {
    struct Args rv = {0};

    while (1) {
        int option_index = 0;
        int c = getopt_long(argc, argv, "hHScgarf:p:t", long_options,
                            &option_index);
        if (c == -1) {
            break;
        }

        switch (c) {
        case 'h':
            print_usage();

        case 'H':
            rv.headless = true;
            break;

        case 'S':
            rv.silent = true;
            break;

        case 'c':
            rv.debug_cpu = true;
            break;

        case 'g':
            rv.debug_gpu = true;
            break;

        case 'a':
            rv.debug_apu = true;
            break;

        case 'r':
            rv.debug_ram = true;

        case 'f':
            sscanf(optarg, "%d", &rv.frames);
            break;

        case 'p':
            sscanf(optarg, "%d", &rv.profile);
            break;

        case 't':
            rv.turbo = true;
            break;
        }
    }

    if (optind < argc) {
        rv.rom = argv[optind++];
    } else {
        print_usage();
    }

    return rv;
}
