#include "buttons.h"
#include "errors.h"

static const u8 JOYPAD_MODE_BUTTONS = 1 << 5;
static const u8 JOYPAD_MODE_DPAD = 1 << 4;
static const u8 JOYPAD_DOWN = 1 << 3;
static const u8 JOYPAD_START = 1 << 3;
static const u8 JOYPAD_UP = 1 << 2;
static const u8 JOYPAD_SELECT = 1 << 2;
static const u8 JOYPAD_LEFT = 1 << 1;
static const u8 JOYPAD_B = 1 << 1;
static const u8 JOYPAD_RIGHT = 1 << 0;
static const u8 JOYPAD_A = 1 << 0;

Buttons::Buttons(CPU *cpu, bool headless) {
    if(!headless) SDL_InitSubSystem(SDL_INIT_GAMECONTROLLER);
    this->cpu = cpu;
    this->cycle = 0;
}

void Buttons::tick() {
    this->cycle++;
    this->update_buttons();
    if(this->cycle % 17556 == 20) {
        if(this->handle_inputs()) {
            this->cpu->stop = false;
            this->cpu->interrupt(Interrupt::JOYPAD);
        }
    }
}

void Buttons::update_buttons() {
    u8 JOYP = ~ram_get(this->cpu->ram, MEM_JOYP);
    JOYP &= 0x30;
    if(JOYP & JOYPAD_MODE_DPAD) {
        if(this->up) JOYP |= JOYPAD_UP;
        if(this->down) JOYP |= JOYPAD_DOWN;
        if(this->left) JOYP |= JOYPAD_LEFT;
        if(this->right) JOYP |= JOYPAD_RIGHT;
    }
    if(JOYP & JOYPAD_MODE_BUTTONS) {
        if(this->b) JOYP |= JOYPAD_B;
        if(this->a) JOYP |= JOYPAD_A;
        if(this->start) JOYP |= JOYPAD_START;
        if(this->select) JOYP |= JOYPAD_SELECT;
    }
    ram_set(this->cpu->ram, MEM_JOYP, ~JOYP & 0x3F);
}

bool Buttons::handle_inputs() {
    bool need_interrupt = false;

    SDL_Event event;

    while(SDL_PollEvent(&event)) {
        if(event.type == SDL_QUIT) {
            throw new Quit();
        }
        if(event.type == SDL_KEYDOWN) {
            need_interrupt = true;
            switch(event.key.keysym.sym) {
                case SDLK_ESCAPE: throw new Quit();
                case SDLK_LSHIFT:
                    this->turbo = true;
                    need_interrupt = false;
                    break;
                case SDLK_UP: this->up = true; break;
                case SDLK_DOWN: this->down = true; break;
                case SDLK_LEFT: this->left = true; break;
                case SDLK_RIGHT: this->right = true; break;
                case SDLK_z: this->b = true; break;
                case SDLK_x: this->a = true; break;
                case SDLK_RETURN: this->start = true; break;
                case SDLK_SPACE: this->select = true; break;
                default: need_interrupt = false; break;
            }
        }
        if(event.type == SDL_KEYUP) {
            switch(event.key.keysym.sym) {
                case SDLK_LSHIFT: this->turbo = false; break;
                case SDLK_UP: this->up = false; break;
                case SDLK_DOWN: this->down = false; break;
                case SDLK_LEFT: this->left = false; break;
                case SDLK_RIGHT: this->right = false; break;
                case SDLK_z: this->b = false; break;
                case SDLK_x: this->a = false; break;
                case SDLK_RETURN: this->start = false; break;
                case SDLK_SPACE: this->select = false; break;
            }
        }
    }

    return need_interrupt;
}
