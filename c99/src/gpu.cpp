#include <SDL2/SDL.h>

#include "consts.h"
#include "gpu.h"

static const u8 LCDC_ENABLED = 1 << 7;
static const u8 LCDC_WINDOW_MAP = 1 << 6;
static const u8 LCDC_WINDOW_ENABLED = 1 << 5;
static const u8 LCDC_DATA_SRC = 1 << 4;
static const u8 LCDC_BG_MAP = 1 << 3;
static const u8 LCDC_OBJ_SIZE = 1 << 2;
static const u8 LCDC_OBJ_ENABLED = 1 << 1;
static const u8 LCDC_BG_WIN_ENABLED = 1 << 0;

static const u8 STAT_LYC_INTERRUPT = 1 << 6;
static const u8 STAT_OAM_INTERRUPT = 1 << 5;
static const u8 STAT_VBLANK_INTERRUPT = 1 << 4;
static const u8 STAT_HBLANK_INTERRUPT = 1 << 3;
static const u8 STAT_LYC_EQUAL = 1 << 2;
static const u8 STAT_MODE_BITS = 1 << 1 | 1 << 0;

static const u8 STAT_HBLANK = 0x00;
static const u8 STAT_VBLANK = 0x01;
static const u8 STAT_OAM = 0x02;
static const u8 STAT_DRAWING = 0x03;

u16 SCALE = 2;

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
u32 rmask = 0xff000000;
u32 gmask = 0x00ff0000;
u32 bmask = 0x0000ff00;
u32 amask = 0x000000ff;
#else
u32 rmask = 0x000000ff;
u32 gmask = 0x0000ff00;
u32 bmask = 0x00ff0000;
u32 amask = 0xff000000;
#endif

static inline SDL_Color gen_hue(u8 n) {
    u8 region = n / 43;
    u8 remainder = (n - (region * 43)) * 6;

    u8 q = 255 - remainder;
    u8 t = remainder;

    switch(region) {
        case 0: return {.r = 255, .g = t, .b = 0, .a = 0xFF};
        case 1: return {.r = q, .g = 255, .b = 0, .a = 0xFF};
        case 2: return {.r = 0, .g = 255, .b = t, .a = 0xFF};
        case 3: return {.r = 0, .g = q, .b = 255, .a = 0xFF};
        case 4: return {.r = t, .g = 0, .b = 255, .a = 0xFF};
        default: return {.r = 255, .g = 0, .b = q, .a = 0xFF};
    }
}

static inline bool sprite_is_live(struct Sprite *self){
    return self->x > 0 && self->x < 168 && self->y > 0 && self->y < 160;
}

static inline void gpu_paint_tile_line(GPU *self, i16 tile_id, SDL_Point *offset, SDL_Color *palette, bool flip_x, bool flip_y, i32 y) {
    u16 addr = (MEM_TILE_DATA + tile_id * 16 + y * 2);
    u8 low_byte = ram_get(self->cpu->ram, addr);
    u8 high_byte = ram_get(self->cpu->ram, addr + 1);
    for(int x = 0; x < 8; x++) {
        u8 low_bit = (low_byte >> (7 - x)) & 0x01;
        u8 high_bit = (high_byte >> (7 - x)) & 0x01;
        u8 px = (high_bit << 1) | low_bit;
        // pallette #0 = transparent, so don't draw anything
        if(px > 0) {
            SDL_Point xy = {
                    .x = offset->x + (flip_x ? 7 - x : x),
                    .y = offset->y + (flip_y ? 7 - y : y),
            };
            auto c = palette[px];
            SDL_SetRenderDrawColor(self->renderer, c.r, c.g, c.b, c.a);
            SDL_RenderDrawPoint(self->renderer, xy.x, xy.y);
        }
    }
}

static inline void gpu_paint_tile(GPU *self, i16 tile_id, SDL_Point *offset, SDL_Color *palette, bool flip_x, bool flip_y) {
    for(int y = 0; y < 8; y++) {
        gpu_paint_tile_line(self, tile_id, offset, palette, flip_x, flip_y, y);
    }

    if(self->debug) {
        SDL_Rect rect = {
                .x = offset->x,
                .y = offset->y,
                .w = 8,
                .h = 8,
        };
        auto c = gen_hue(tile_id);
        SDL_SetRenderDrawColor(self->renderer, c.r, c.g, c.b, c.a);
        SDL_RenderDrawRect(self->renderer, &rect);
    }
}

static inline void gpu_draw_line(GPU *self, i32 ly) {
    auto lcdc = ram_get(self->cpu->ram, MEM_LCDC);

    // Background tiles
    if(lcdc & LCDC_BG_WIN_ENABLED) {
        auto scroll_y = ram_get(self->cpu->ram, MEM_SCY);
        auto scroll_x = ram_get(self->cpu->ram, MEM_SCX);
        auto tile_offset = !(lcdc & LCDC_DATA_SRC);
        auto tile_map = (lcdc & LCDC_BG_MAP) ? MEM_MAP_1 : MEM_MAP_0;

        if(self->debug) {
            SDL_Point xy = {.x = 256 - scroll_x, .y = ly};
            SDL_SetRenderDrawColor(self->renderer, 255, 0, 0, 0xFF);
            SDL_RenderDrawPoint(self->renderer, xy.x, xy.y);
        }

        auto y_in_bgmap = (ly + scroll_y) % 256;
        auto tile_y = y_in_bgmap / 8;
        auto tile_sub_y = y_in_bgmap % 8;

        for(int lx = 0; lx <= 160; lx += 8) {
            auto x_in_bgmap = (lx + scroll_x) % 256;
            auto tile_x = x_in_bgmap / 8;
            auto tile_sub_x = x_in_bgmap % 8;

            i16 tile_id = ram_get(self->cpu->ram, tile_map + tile_y * 32 + tile_x);
            if(tile_offset && tile_id < 0x80) {
                tile_id += 0x100;
            }
            SDL_Point xy = {
                    .x = lx - tile_sub_x,
                    .y = ly - tile_sub_y,
            };
            gpu_paint_tile_line(self, tile_id, &xy, self->bgp, false, false, tile_sub_y);
        }
    }

    // Window tiles
    if(lcdc & LCDC_WINDOW_ENABLED) {
        auto wnd_y = ram_get(self->cpu->ram, MEM_WY);
        auto wnd_x = ram_get(self->cpu->ram, MEM_WX);
        auto tile_offset = !(lcdc & LCDC_DATA_SRC);
        auto tile_map = (lcdc & LCDC_WINDOW_MAP) ? MEM_MAP_1 : MEM_MAP_0;

        // blank out the background
        SDL_Rect rect = {
                .x = wnd_x - 7,
                .y = wnd_y,
                .w = 160,
                .h = 144,
        };
        auto c = self->bgp[0];
        SDL_SetRenderDrawColor(self->renderer, c.r, c.g, c.b, c.a);
        SDL_RenderFillRect(self->renderer, &rect);

        auto y_in_bgmap = ly - wnd_y;
        auto tile_y = y_in_bgmap / 8;
        auto tile_sub_y = y_in_bgmap % 8;

        for(int tile_x = 0; tile_x < 20; tile_x++) {
            auto tile_id = ram_get(self->cpu->ram, tile_map + tile_y * 32 + tile_x);
            if(tile_offset && tile_id < 0x80) {
                tile_id += 0x100;
            }
            SDL_Point xy = {
                    .x = tile_x * 8 + wnd_x - 7,
                    .y = tile_y * 8 + wnd_y,
            };
            gpu_paint_tile_line(self, tile_id, &xy, self->bgp, false, false, tile_sub_y);
        }
    }

    // Sprites
    if(lcdc & LCDC_OBJ_ENABLED) {
        auto dbl = lcdc & LCDC_OBJ_SIZE;

        // TODO: sorted by x
        // auto sprites: [Sprite; 40] = [];
        // memcpy(sprites, &ram.data[OAM_BASE], 40 * sizeof(Sprite));
        // for sprite in sprites.iter() {
        for(int n = 0; n < 40; n++) {
            Sprite sprite;
            sprite.y = ram_get(self->cpu->ram, MEM_OAM_BASE + 4 * n + 0);
            sprite.x = ram_get(self->cpu->ram, MEM_OAM_BASE + 4 * n + 1);
            sprite.tile_id = ram_get(self->cpu->ram, MEM_OAM_BASE + 4 * n + 2);
            sprite.flags = ram_get(self->cpu->ram, MEM_OAM_BASE + 4 * n + 3);

            if(sprite_is_live(&sprite)) {
                auto palette = sprite.palette ? self->obp1 : self->obp0;
                // printf("Drawing sprite %d (from %04X) at %d,%d\n", tile_id, OAM_BASE + (sprite_id * 4) + 0, x, y);
                SDL_Point xy = {
                        .x = sprite.x - 8,
                        .y = sprite.y - 16,
                };
                gpu_paint_tile(self, sprite.tile_id, &xy, palette, sprite.x_flip, sprite.y_flip);

                if(dbl) {
                    xy.y = sprite.y - 8;
                    gpu_paint_tile(self, sprite.tile_id + 1, &xy, palette, sprite.x_flip, sprite.y_flip);
                }
            }
        }
    }
}

static inline void gpu_draw_debug(GPU *self) {
    u8 lcdc = ram_get(self->cpu->ram, MEM_LCDC);

    // Tile data
    u8 tile_display_width = 32;
    for(int tile_id = 0; tile_id < 384; tile_id++) {
        SDL_Point xy = {
                .x = 160 + (tile_id % tile_display_width) * 8,
                .y = (tile_id / tile_display_width) * 8,
        };
        gpu_paint_tile(self, tile_id, &xy, self->bgp, false, false);
    }

    // Background scroll border
    if(lcdc & LCDC_BG_WIN_ENABLED) {
        SDL_Rect rect = {.x = 0, .y = 0, .w = 160, .h = 144};
        SDL_SetRenderDrawColor(self->renderer, 255, 0, 0, 0xFF);
        SDL_RenderDrawRect(self->renderer, &rect);
    }

    // Window tiles
    if(lcdc & LCDC_WINDOW_ENABLED) {
        u8 wnd_y = ram_get(self->cpu->ram, MEM_WY);
        u8 wnd_x = ram_get(self->cpu->ram, MEM_WX);
        SDL_Rect rect = {.x = wnd_x - 7, .y = wnd_y, .w = 160, .h = 144};
        SDL_SetRenderDrawColor(self->renderer, 0, 0, 255, 0xFF);
        SDL_RenderDrawRect(self->renderer, &rect);
    }
}

static inline void gpu_update_palettes(GPU *self) {
    u8 raw_bgp = ram_get(self->cpu->ram, MEM_BGP);
    self->bgp[0] = self->colors[(raw_bgp >> 0) & 0x3];
    self->bgp[1] = self->colors[(raw_bgp >> 2) & 0x3];
    self->bgp[2] = self->colors[(raw_bgp >> 4) & 0x3];
    self->bgp[3] = self->colors[(raw_bgp >> 6) & 0x3];

    u8 raw_obp0 = ram_get(self->cpu->ram, MEM_OBP0);
    self->obp0[0] = self->colors[(raw_obp0 >> 0) & 0x3];
    self->obp0[1] = self->colors[(raw_obp0 >> 2) & 0x3];
    self->obp0[2] = self->colors[(raw_obp0 >> 4) & 0x3];
    self->obp0[3] = self->colors[(raw_obp0 >> 6) & 0x3];

    u8 raw_obp1 = ram_get(self->cpu->ram, MEM_OBP1);
    self->obp1[0] = self->colors[(raw_obp1 >> 0) & 0x3];
    self->obp1[1] = self->colors[(raw_obp1 >> 2) & 0x3];
    self->obp1[2] = self->colors[(raw_obp1 >> 4) & 0x3];
    self->obp1[3] = self->colors[(raw_obp1 >> 6) & 0x3];
}

GPU::GPU(CPU *cpu, char *title, bool headless, bool debug) {
    this->cpu = cpu;
    this->debug = debug;

    // Window
    int w = 160, h = 144;
    if(this->debug) {
        w = 160 + 256;
        h = 144;
    }
    if(!headless) {
        SDL_InitSubSystem(SDL_INIT_VIDEO);
        char title_buf[64];
        snprintf(title_buf, 64, "RosettaBoy - %s", title);
        this->hw_window = SDL_CreateWindow(
            title_buf,                                      // window title
            SDL_WINDOWPOS_UNDEFINED,                        // initial x position
            SDL_WINDOWPOS_UNDEFINED,                        // initial y position
            w * SCALE,                                      // width, in pixels
            h * SCALE,                                      // height, in pixels
            SDL_WINDOW_ALLOW_HIGHDPI | SDL_WINDOW_RESIZABLE // flags - see below
        );
        this->hw_renderer = SDL_CreateRenderer(this->hw_window, -1, 0);
        SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "nearest"); // vs "linear"
        SDL_RenderSetLogicalSize(this->hw_renderer, w, h);
        this->hw_buffer =
            SDL_CreateTexture(this->hw_renderer, SDL_PIXELFORMAT_ABGR8888, SDL_TEXTUREACCESS_STREAMING, w, h);
    } else {
        this->hw_window = nullptr;
        this->hw_renderer = nullptr;
        this->hw_buffer = nullptr;
    }
    this->buffer = SDL_CreateRGBSurface(0, w, h, 32, rmask, gmask, bmask, amask);
    this->renderer = SDL_CreateSoftwareRenderer(this->buffer);

    // Colors
    this->colors[0] = {.r = 0x9B, .g = 0xBC, .b = 0x0F, .a = 0xFF};
    this->colors[1] = {.r = 0x8B, .g = 0xAC, .b = 0x0F, .a = 0xFF};
    this->colors[2] = {.r = 0x30, .g = 0x62, .b = 0x30, .a = 0xFF};
    this->colors[3] = {.r = 0x0F, .g = 0x38, .b = 0x0F, .a = 0xFF};
    // printf("SDL_Init failed: %s\n", SDL_GetError());
};

GPU::~GPU() {
    SDL_FreeSurface(this->buffer);
    if(this->hw_window) SDL_DestroyWindow(this->hw_window);
    SDL_Quit();
}

void gpu_tick(GPU *self) {
    self->cycle++;

    // CPU STOP stops all LCD activity until a button is pressed
    if(self->cpu->stop) {
        return;
    }

    // Check if LCD enabled at all
    u8 lcdc = ram_get(self->cpu->ram, MEM_LCDC);
    if(!(lcdc & LCDC_ENABLED)) {
        // When LCD is re-enabled, LY is 0
        // Does it become 0 as soon as disabled??
        ram_set(self->cpu->ram, MEM_LY, 0);
        if(!self->debug) {
            return;
        }
    }

    u8 lx = self->cycle % 114;
    u8 ly = (self->cycle / 114) % 154;
    ram_set(self->cpu->ram, MEM_LY, ly);

    u8 stat = ram_get(self->cpu->ram, MEM_STAT);
    stat &= ~STAT_MODE_BITS;
    stat &= ~STAT_LYC_EQUAL;

    // LYC compare & interrupt
    if(ly == ram_get(self->cpu->ram, MEM_LYC)) {
        stat |= STAT_LYC_EQUAL;
        if(stat & STAT_LYC_INTERRUPT) {
            self->cpu->interrupt(INTERRUPT_STAT);
        }
    }

    // Set mode
    if(lx == 0 && ly < 144) {
        stat |= STAT_OAM;
        if(stat & STAT_OAM_INTERRUPT) {
            self->cpu->interrupt(INTERRUPT_STAT);
        }
    } else if(lx == 20 && ly < 144) {
        stat |= STAT_DRAWING;
        if(ly == 0) {
            // TODO: how often should we update palettes?
            // Should every pixel reference them directly?
            gpu_update_palettes(self);
            auto c = self->bgp[0];
            SDL_SetRenderDrawColor(self->renderer, c.r, c.g, c.b, c.a);
            SDL_RenderClear(self->renderer);
        }
        gpu_draw_line(self, ly);
        if(ly == 143) {
            if(self->debug) {
                gpu_draw_debug(self);
            }
            if(self->hw_renderer) {
                SDL_UpdateTexture(self->hw_buffer, NULL, self->buffer->pixels, self->buffer->pitch);
                SDL_RenderCopy(self->hw_renderer, self->hw_buffer, NULL, NULL);
                SDL_RenderPresent(self->hw_renderer);
            }
        }
    } else if(lx == 63 && ly < 144) {
        stat |= STAT_HBLANK;
        if(stat & STAT_HBLANK_INTERRUPT) {
            self->cpu->interrupt(INTERRUPT_STAT);
        }
    } else if(lx == 0 && ly == 144) {
        stat |= STAT_VBLANK;
        if(stat & STAT_VBLANK_INTERRUPT) {
            self->cpu->interrupt(INTERRUPT_STAT);
        }
        self->cpu->interrupt(INTERRUPT_VBLANK);
    }
    ram_set(self->cpu->ram, MEM_STAT, stat);
}

