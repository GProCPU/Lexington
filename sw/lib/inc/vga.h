#ifndef __VGA_H
#define __VGA_H

#include <stdint.h>
#include <stdbool.h>


#define VGA_WIDTH       320
#define VGA_HEIGHT      240

#define VGA_ROTATE_0    0
#define VGA_ROTATE_90   90
#define VGA_ROTATE_180  180
#define VGA_ROTATE_270  270

// Pixel format
#define VGA_RGB332
// #define VGA_RGB12

#if defined(VGA_RGB332)
    typedef uint8_t rgb_t;
    #define VGA_BLACK       0x00u
    #define VGA_WHITE       0xFFu
    #define VGA_GRAY        0x49u
    #define VGA_RED         0xE0u
    #define VGA_GREEN       0x1Cu
    #define VGA_BLUE        0x03u
    #define VGA_CYAN        0x1Fu
    #define VGA_MAGENTA     0xE3u
    #define VGA_YELLOW      0xFCu
    #define VGA_ORANGE      0xF0u
#elif defined(VGA_RGB12)
    typedef uint16_t rgb_t;
    #define VGA_BLACK       0x000u
    #define VGA_WHITE       0xFFFu
    #define VGA_GRAY        0x555u
    #define VGA_RED         0xF00u
    #define VGA_GREEN       0x0F0u
    #define VGA_BLUE        0x00Fu
    #define VGA_CYAN        0x0FFu
    #define VGA_MAGENTA     0xF0Fu
    #define VGA_YELLOW      0xFF0u
    #define VGA_ORANGE      0xF70u
#endif

#define VGA_FRAME_BUFF      ((volatile rgb_t*) 0xE0000000U)


#ifdef __cplusplus
extern "C" {
#endif

void vga_draw_pixel(int32_t x, int32_t y, rgb_t color);
void vga_draw_line(int32_t x0, int32_t y0, int32_t x1, int32_t y1, rgb_t color);
void vga_draw_rect(int32_t x, int32_t y, int32_t w, int32_t h, rgb_t color);
void vga_fill_rect(int32_t x, int32_t y, int32_t w, int32_t h, rgb_t color);
void vga_draw_h_line(int32_t x, int32_t y, int32_t w, rgb_t color);
void vga_draw_v_line(int32_t x, int32_t y, int32_t h, rgb_t color);
void vga_draw_bitmap(int32_t x, int32_t y, const rgb_t* bmp, int32_t w, int32_t h);
void vga_fill_screen(rgb_t color);

#ifdef __cplusplus
} // extern "C"
#endif


#ifdef __cplusplus
template<int32_t rotate, bool flip_horiz, bool flip_vert>
void vga_draw_bitmap(int32_t x, int32_t y, const rgb_t* bmp, int32_t w, int32_t h) {
    static_assert((rotate==0) | (rotate==360) | (rotate==90) | (rotate==-270)
        | (rotate==180) | (rotate==-180) | (rotate==270) | (rotate==-90),
        "Rotation must be 0, 90, 180, or 270");
    volatile rgb_t* curr = VGA_FRAME_BUFF + (y*VGA_WIDTH) + x;
    // Rotate performed with frame buffer pointer
    switch (rotate) {
        case 0:
        case 360:
            // do nothing
            break;
        case 90:
        case -270:
            curr += w - 1;
            break;
        case 180:
        case -180:
            curr += (h-1) * VGA_WIDTH;
            break;
        case 270:
        case -90:
            curr += ((h-1) * VGA_WIDTH) + w-1;
            break;
    }
    // Flip performed with bitmap pointer
    const rgb_t* bmp_curr = bmp;
    if (flip_horiz) {
        bmp += w - 1;
    }
    if (flip_vert) {
        bmp += (h-1) * w;
    }
    for (int32_t _y=0; _y<h; _y++) {
        for (int32_t _x=0; _x<w; _x++) {
            *curr = *bmp_curr;
            switch (rotate) {
                case 0:
                case 360:
                    curr++;
                    break;
                case 90:
                case -270:
                    curr += VGA_WIDTH;
                    break;
                case 180:
                case -180:
                    curr--;
                    break;
                case 270:
                case -90:
                    curr -= VGA_WIDTH;
                    break;
            }
            bmp_curr = (flip_horiz) ? bmp_curr-1 : bmp_curr+1;
        }
        // row = row + VGA_WIDTH;
        // curr = row;
        switch (rotate) {
            case 0:
            case 360:
                curr += VGA_WIDTH;
                break;
            case 90:
            case -270:
                curr--;
                break;
            case 180:
            case -180:
                curr -= VGA_WIDTH;
                break;
            case 270:
            case -90:
                curr++;
                break;
        }
        bmp_curr = (flip_vert) ? bmp_curr-w : bmp_curr+w;
    }
}
#endif // __cplusplus


#endif // __VGA_H
