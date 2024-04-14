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
void vga_draw_bitmap_scaled(int32_t x, int32_t y, const rgb_t* bmp, int32_t w, int32_t h, int32_t scale);
void vga_fill_screen(rgb_t color);

#ifdef __cplusplus
} // extern "C"
#endif


#ifdef __cplusplus
template<int32_t rotate, bool flip_horiz, bool flip_vert>
void vga_draw_bitmap(int32_t x, int32_t y, const rgb_t* bmp, int32_t w, int32_t h, int32_t scale=1) {
    // Rotation is performed while indexing the frame buffer.
    // Vertical/horizontal flip is performed while indexing the bitmap
    //
    // * variable names and comments are in reference to the non-rotated, non-flipped orientation
    static_assert((rotate==0) | (rotate==360) | (rotate==90) | (rotate==-270)
                | (rotate==180) | (rotate==-180) | (rotate==270) | (rotate==-90),
                "Rotation must be 0, 90, 180, or 270"
    );
    // Rotate performed with frame buffer pointer
    volatile rgb_t* curr = VGA_FRAME_BUFF + (y*VGA_WIDTH) + x;
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
            curr += (h-1) * VGA_WIDTH + w-1;
            break;
        case 270:
        case -90:
            curr += ((h-1) * VGA_WIDTH);
            break;
    }
    volatile rgb_t* row = curr;
    // Flip performed with bitmap pointer
    const rgb_t* bmp_curr = bmp;
    if (flip_horiz) {
        bmp_curr += w - 1;
    }
    if (flip_vert) {
        bmp_curr += (h-1) * w;
    }
    const rgb_t* bmp_row = bmp_curr;

    // Copy pixel data from bitmap to frame buffer
    for (int32_t _y=0; _y<h; _y++) {
        // Bitmap index y loop
        for (int32_t _sy=0; _sy<scale; _sy++) {
            // Scale y loop
            for (int32_t _x=0; _x<w; _x++) {
                // Bitmap index x loop
                for (int32_t _sx=0; _sx<scale; _sx++) {
                    // Scale x loop
                    // copy data
                    *curr = *bmp_curr;
                    // increment* frame buff pointer every pixel
                    switch (rotate) {
                        case 0:   case 360:     curr++; break;
                        case 90:  case -270:    curr += VGA_WIDTH; break;
                        case 180: case -180:    curr--; break;
                        case 270: case -90:     curr -= VGA_WIDTH; break;
                    }
                }
                // increment* bitmap pointer every <scale> pixels
                bmp_curr = (flip_horiz) ? bmp_curr-1 : bmp_curr+1;
            }
            // increment* frame buff row* pointer
            switch (rotate) {
                case 0:   case 360:         row += VGA_WIDTH; break;
                case 90:  case -270:        row--; break;
                case 180: case -180:        row -= VGA_WIDTH; break;
                case 270: case -90:         row++; break;
            }
            // set frame buff pointer to start of new row*
            curr = row;
            // reset bitmap pointer to beginning of row and repeat pixels
            bmp_curr = bmp_row;
        }
        // increment* bitmap row pointer to next row
        bmp_row = (flip_vert) ? bmp_row - w : bmp_row + w;
        bmp_curr = bmp_row;
    }
}
#endif // __cplusplus


#endif // __VGA_H
