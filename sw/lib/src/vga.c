#include "vga.h"


static inline int32_t abs(int32_t val) {
    return (val >= 0) ? val : (-1*val);
}


void vga_draw_pixel(int32_t x, int32_t y, rgb_t color) {
    VGA[(y*VGA_WIDTH)+x] = color;
}

void vga_draw_line(int32_t x0, int32_t y0, int32_t x1, int32_t y1, rgb_t color) {
    int32_t tmp;
    int32_t steep = abs(y1 - y0) > abs(x1 - x0);
    if (steep) {
        // swap x0, y0
        tmp = x0;
        x0 = y0;
        y0 = tmp;
        // swap x1, y1
        tmp = x1;
        x1 = y1;
        y1 = tmp;
    }

    if (x0 > x1) {
        // swap x0, x1
        tmp = x0;
        x0 = x1;
        x1 = tmp;
        // swap y0, y1
        tmp = y0;
        y0 = y1;
        y1 = tmp;
    }

    int32_t dx, dy;
    dx = x1 - x0;
    dy = abs(y1 - y0);

    int32_t err = dx / 2;
    int32_t ystep;
    if (y0 < y1) {
        ystep = 1;
    } else {
        ystep = -1;
    }

    for (; x0 <= x1; x0++) {
        if (steep) {
            vga_draw_pixel(y0, x0, color);
        } else {
            vga_draw_pixel(x0, y0, color);
        }
        err -= dy;
        if (err < 0) {
            y0 += ystep;
            err += dx;
        }
    }
}

void vga_draw_rect(int32_t x, int32_t y, int32_t w, int32_t h, rgb_t color) {
    uint16_t* top_left_ptr16 = &(VGA[(y*VGA_WIDTH)+x]);
    uint16_t* ptr16 = top_left_ptr16;
    // top
    for (int32_t i=0; i<w; i++) {
        ptr16[0] = color;
        ptr16++;
    }
    // right
    ptr16--;
    for (int32_t i=0; i<h; i++) {
        ptr16[0] = color;
        ptr16 += VGA_WIDTH;
    }
    // left
    ptr16 = top_left_ptr16;
    for (int32_t i=0; i<h; i++) {
        ptr16[0] = color;
        ptr16 += VGA_WIDTH;
    }
    // bottom
    ptr16 -= VGA_WIDTH;
    for (int32_t i=0; i<w; i++) {
        ptr16[0] = color;
        ptr16++;
    }
}

void vga_fill_rect(int32_t x, int32_t y, int32_t w, int32_t h, rgb_t color) {
    uint16_t* row_ptr16 = &(VGA[(y*VGA_WIDTH)+x]);
    uint16_t* ptr16 = row_ptr16;
    for (int32_t i=0; i<h; i++) {
        for (int32_t j=0; j<w; j++) {
            ptr16[0] = color;
        }
        row_ptr16 += VGA_WIDTH;
        ptr16 = row_ptr16;
    }
}

void vga_draw_h_line(int32_t x, int32_t y, int32_t w, rgb_t color) {
    uint16_t* ptr16 = &(VGA[(y*VGA_WIDTH)+x]);
    for (int32_t i=0; i<w; i++) {
        ptr16[0] = color;
        ptr16++;
    }
}

void vga_draw_v_line(int32_t x, int32_t y, int32_t h, rgb_t color) {
    uint16_t* ptr16 = &(VGA[(y*VGA_WIDTH)+x]);
    for (int32_t i=0; i<h; i++) {
        ptr16[0] = color;
        ptr16 += VGA_WIDTH;
    }
}

void vga_draw_bitmap(int32_t x, int32_t y, rgb_t* bmp, int32_t w, int32_t h) {
    uint16_t* row_ptr16 = &(VGA[(y*VGA_WIDTH) + x]);
    uint16_t* ptr16 = row_ptr16;
    uint16_t* bmp_ptr = bmp;
    for (int32_t i=0; i<h; i++) {
        for (int32_t j=0; j<w; i++) {
            ptr16[0] = bmp_ptr[0];
            bmp_ptr++;
        }
        row_ptr16 += VGA_WIDTH;
        ptr16 = row_ptr16;
    }
}
