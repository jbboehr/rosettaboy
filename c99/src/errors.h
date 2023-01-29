#ifndef ROSETTABOY_ERRORS_H
#define ROSETTABOY_ERRORS_H

#include <stdarg.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "consts.h"

#ifdef __cplusplus

#include <exception>
#include <string>

#define ERR_BUF_LEN 1000

class EmuException : public std::exception {
protected:
    char buffer[ERR_BUF_LEN] = "EmuException";
    void set_msg(const char *format, ...) {
        va_list args;
        va_start(args, format);
        vsnprintf(this->buffer, ERR_BUF_LEN, format, args);
        va_end(args);
    }

public:
    virtual const char *what() const throw() { return this->buffer; }
};

// Controlled exit, ie we are deliberately stopping emulation
class ControlledExit : public EmuException {};
class Quit : public ControlledExit {
public:
    Quit() { this->set_msg("User exited the emulator"); }
};
class UnitTestPassed : public ControlledExit {
public:
    UnitTestPassed() { this->set_msg("Unit test passed"); }
};
class UnitTestFailed : public ControlledExit {
public:
    UnitTestFailed() { this->set_msg("Unit test failed"); }
};

// Game error, ie the game developer has a bug
class GameException : public EmuException {};
class UserException : public EmuException {};
#endif

NORETURN static void invalid_opcode_err(u8 opcode) {
    fprintf(stdout, "Invalid opcode: 0x%02X", opcode);
    fflush(stdout);
    exit(3);
}

NORETURN static void timeout_err(int frames, double duration) {
    fprintf(stdout, "Emulated %5d frames in %5.2fs (%.0ffps)", frames, duration, frames / duration);
    fflush(stdout);
    exit(0);
}

NORETURN static void quit_emulator() {
    fprintf(stdout, "User exited the emulator");
    fflush(stdout);
    exit(0);
}

NORETURN static void invalid_argument_err(const char *msg) {
    fprintf(stdout, "%s", msg);
    fflush(stdout);
    abort();
}

NORETURN static void invalid_ram_read_err(u8 ram_bank, int offset, u32 ram_size) {
    fprintf(stdout, "Read from RAM bank 0x%02X offset 0x%04X >= ram size 0x%04X", ram_bank, offset, ram_size);
    fflush(stdout);
    abort();
}

NORETURN static void invalid_ram_write_err(u8 ram_bank, int offset, u32 ram_size) {
    fprintf(stdout, "Write to RAM bank 0x%02X offset 0x%04X >= ram size 0x%04X", ram_bank, offset, ram_size);
    fflush(stdout);
    abort();
}



// User error, ie the user gave us an invalid or corrupt input file
NORETURN static void rom_missing_err(const char *filename, int err) {
    fprintf(stdout, "Error opening %s: %s\n", filename, strerror(err));
    fflush(stdout);
    abort();
}
NORETURN static void logo_checksum_failed_err(int logo_checksum) {
    fprintf(stdout, "Invalid logo checksum: %d", logo_checksum);
    fflush(stdout);
    abort();
}
NORETURN static void header_checksum_failed_err(int header_checksum) {
    fprintf(stdout, "Invalid header checksum: %d", header_checksum);
    fflush(stdout);
    abort();
}

#endif // ROSETTABOY_ERRORS_H
