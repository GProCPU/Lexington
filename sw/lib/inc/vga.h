#ifndef __VGA_H
#define __VGA_H

#include <stdint.h>

#define VGA_WIDTH       320
#define VGA_HEIGHT      240

typedef uint8_t rgb_t;
#define VGA_FRAME_BUFF  ((rgb_t*) 0xFFD00000)


void vga_draw_pixel(int32_t x, int32_t y, rgb_t color);
void vga_draw_line(int32_t x0, int32_t y0, int32_t x1, int32_t y1, rgb_t color);
void vga_draw_rect(int32_t x, int32_t y, int32_t w, int32_t h, rgb_t color);
void vga_fill_rect(int32_t x, int32_t y, int32_t w, int32_t h, rgb_t color);
void vga_draw_h_line(int32_t x, int32_t y, int32_t w, rgb_t color);
void vga_draw_v_line(int32_t x, int32_t y, int32_t h, rgb_t color);
void vga_draw_bitmap(int32_t x, int32_t y, rgb_t* bmp, int32_t w, int32_t h);



#endif // __VGA_H
