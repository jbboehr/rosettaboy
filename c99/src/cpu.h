#ifndef ROSETTABOY_CPU_H
#define ROSETTABOY_CPU_H

#include <cstdint>

#include "cart.h"
#include "ram.h"

union oparg {
    u8 as_u8;   // B
    i8 as_i8;   // b
    u16 as_u16; // H
};

class CPU {
public:
    struct RAM *ram;
    bool stop = false;
    bool stepping = false;

private:
    bool interrupts = true;
    bool halt = false;
    bool debug = true;
    int cycle = 0;
    int owed_cycles = 0;

public:
    union {
        u16 AF;
        struct {
            u8 F;
            u8 A;
        };
        struct {
            unsigned int _1 : 4;
            unsigned int FLAG_C : 1;
            unsigned int FLAG_H : 1;
            unsigned int FLAG_N : 1;
            unsigned int FLAG_Z : 1;
            unsigned int _2 : 8;
        };
    };
    union {
        u16 BC;
        struct {
            u8 C;
            u8 B;
        };
    };
    union {
        u16 DE;
        struct {
            u8 E;
            u8 D;
        };
    };
    union {
        u16 HL;
        struct {
            u8 L;
            u8 H;
        };
    };
    u16 SP;
    u16 PC;

public:
    CPU(struct RAM *ram, bool debug);
    void tick();
    void interrupt(Interrupt i);
    void dump_regs();

private:
    void tick_dma();
    void tick_clock();
    bool check_interrupt(u8 queue, u8 i, u16 handler);
    void tick_interrupts();
    void tick_instructions();
    void tick_main(u8 op, oparg arg);
    void tick_cb(u8 op);

    void _xor(u8 val);
    void _or(u8 val);
    void _and(u8 val);
    void _cp(u8 val);
    void _add(u8 val);
    void _adc(u8 val);
    void _sub(u8 val);
    void _sbc(u8 val);
};

BEGIN_EXTERN_C()

void cpu_interrupt(CPU *cpu, enum Interrupt i);
void cpu_stop(CPU *cpu, bool stop);
bool cpu_is_stopped(CPU *cpu);

END_EXTERN_C()

#endif // ROSETTABOY_CPU_H
