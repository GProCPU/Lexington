#ifndef __VGA_H
#define __VGA_H

#include <stdint.h>

#define VGA_WIDTH       320
#define VGA_HEIGHT      240

// Pixel format
#define VGA_RGB332
// #define VGA_RGB12

#if defined(VGA_RGB332)
    typedef uint8_t rgb_t;
    #define VGA_BLACK    0x00u
    #define VGA_WHITE    0xFFu
    #define VGA_RED      0xE0u
    #define VGA_GREEN    0x1Cu
    #define VGA_BLUE     0x03u
    #define VGA_CYAN     0x1Fu
    #define VGA_MAGENTA  0xE3u
    #define VGA_YELLOW   0xFCu
    #define VGA_ORANGE   0xF0u
#elif defined (VGA_RGB12)
    typedef uint16_t rgb_t;
    #define VGA_BLACK    0x000u
    #define VGA_WHITE    0xFFFu
    #define VGA_RED      0xF00u
    #define VGA_GREEN    0x0F0u
    #define VGA_BLUE     0x00Fu
    #define VGA_CYAN     0x0FFu
    #define VGA_MAGENTA  0xF0Fu
    #define VGA_YELLOW   0xFF0u
    #define VGA_ORANGE   0xF70u
#endif

#define VGA_FRAME_BUFF      ((volatile rgb_t*) 0xE0000000U)


void vga_draw_pixel(int32_t x, int32_t y, rgb_t color);
void vga_draw_line(int32_t x0, int32_t y0, int32_t x1, int32_t y1, rgb_t color);
void vga_draw_rect(int32_t x, int32_t y, int32_t w, int32_t h, rgb_t color);
void vga_fill_rect(int32_t x, int32_t y, int32_t w, int32_t h, rgb_t color);
void vga_draw_h_line(int32_t x, int32_t y, int32_t w, rgb_t color);
void vga_draw_v_line(int32_t x, int32_t y, int32_t h, rgb_t color);
void vga_draw_bitmap(int32_t x, int32_t y, rgb_t* bmp, int32_t w, int32_t h);


#endif // __VGA_H
