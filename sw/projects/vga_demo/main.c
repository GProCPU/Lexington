#include "lexington.h"


int main() {

    vga_draw_h_line(0, 0, VGA_WIDTH, 0xFFF);
    vga_draw_h_line(0, VGA_HEIGHT-1, VGA_WIDTH, 0xFFF);
    vga_draw_v_line(0, 0, VGA_HEIGHT, 0xFFF);
    vga_draw_v_line(VGA_WIDTH-1, 0, VGA_HEIGHT, 0xFFF);

    vga_fill_rect(10, 10, 10, 10, 0x00F);

    while (true) {
        // do nothing
    }

}
